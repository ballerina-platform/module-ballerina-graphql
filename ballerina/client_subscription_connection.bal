// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/jballerina.java;
import ballerina/lang.runtime;
import ballerina/websocket;

# The caller for a `ping` message received over a GraphQL subscription connection, used to
# respond with a `pong` message.
public isolated client class PingMessageCaller {
    private final websocket:Client wsClient;

    isolated function init(websocket:Client wsClient) {
        self.wsClient = wsClient;
    }

    # Sends a `pong` message with the given payload.
    #
    # + payload - The payload of the `pong` message
    # + return - A `graphql:ClientError` if the message could not be sent
    remote isolated function pong(map<json>? payload = ()) returns ClientError? {
        Pong pongMessage = payload is () ? {'type: WS_PONG} : {'type: WS_PONG, payload: payload};
        websocket:Error? result = self.wsClient->writeMessage(pongMessage);
        if result is websocket:Error {
            return error SubscriptionError(string `Failed to send the pong message: ${result.message()}`,
                    result, errors = ());
        }
        return;
    }
}

// The outcome of the first locked section of `SubscriptionConnection.subscribe()`: either it is
// already finished (`mustConnect: false`, with `result` as the value to return), or no connection
// exists yet and none is being established, so this strand must establish it itself
// (`mustConnect: true`) by calling `connect()` -- outside the lock -- and then
// `subscribeAfterConnect()`.
type SubscribeStartOutcome record {|
    boolean mustConnect;
    ClientError? result;
|};

// The outcome of `SubscriptionConnection.subscribe()`'s second locked section, reached only when
// this strand established the connection itself. `closeConnection` tells the (unlocked) caller
// whether it must close the just-established connection afterwards -- kept out of this locked
// section because closing a WebSocket can block for a while, and the lock should not be held
// across it.
type SubscribeCompletion record {|
    ClientError? result;
    boolean closeConnection;
|};

// The outcome of the locked section of `SubscriptionConnection.handleConnectionFailure()`: either
// there is nothing further to do (`action: "none"`), or reconnection is configured and was just
// started, so the caller must run `reconnect(reconnectConfig)` -- outside the lock.
type ConnectionFailureOutcome record {|
    "none"|"reconnect" action;
    readonly & ReconnectConfig reconnectConfig = {};
|};

// The outcome of the locked section of `SubscriptionConnection.handleKeepAliveTimeout()`.
// `"none"`: nothing further to do. `"closeSync"`: the caller must close `failedWsClient`
// synchronously, then return -- kept out of the lock since closing can block for a while.
// `"closeAsyncAndReconnect"`: the caller must close `failedWsClient` in the background and run
// `reconnect(reconnectConfig)`.
type KeepAliveTimeoutOutcome record {|
    "none"|"closeSync"|"closeAsyncAndReconnect" action;
    readonly & ReconnectConfig reconnectConfig = {};
|};

// The outcome of one locked reconnection attempt inside `SubscriptionConnection.reconnect()`'s
// retry loop. `"done"`: the connection was (re-)established; the loop returns. `"closeAndReturn"`:
// the connection was closed by the user mid-attempt; the caller closes `connectionResult` (outside
// the lock) and returns. `"closeAndRetry"`: sending the pending `subscribe` messages failed; the
// caller closes `connectionResult` and the loop tries again.
type ReconnectAttemptOutcome "done"|"closeAndReturn"|"closeAndRetry";

// Manages the WebSocket connection of a GraphQL client used for subscriptions, implementing the
// `graphql-transport-ws` protocol: the connection establishment with the handshake, the
// multiplexing of the subscription operations over the single connection, and the reconnection.
//
// The mutable state of the connection lives in a Java state holder with concurrent-safe data
// structures (see `SubscriptionConnectionState.java`); compound state transitions are serialized
// through its `lockState()`/`unlockState()` functions. Ballerina `lock` statements are
// intentionally not used.
//
// Every `lockState()`/`unlockState()` pair brackets a `trap`-wrapped call to a private `...Locked`
// helper (Ballerina has no try/finally): `unlockState()` always runs right after, whether the
// helper returned normally or panicked, so a bug in a critical section cannot leave the connection
// permanently locked. A caught panic is re-panicked (after unlocking) once the trapped value is
// checked to not already be the helper's own, non-error result type.
isolated class SubscriptionConnection {
    private final string wsUrl;
    private final decimal connectionInitTimeout;
    private final readonly & map<json>? connectionInitPayload;
    private final readonly & ReconnectConfig? reconnectConfig;
    private final PingMessageHandler? pingMessageHandler;
    private final boolean keepAliveEnabled;
    private final decimal keepAlivePingInterval;
    private final decimal keepAlivePongTimeout;
    // Wakes up a keep-alive wait (see `keepAliveWait`) the instant `close()` runs or the dispatcher
    // receives a `pong`/notices the connection is gone, instead of it only noticing at the end of a
    // blind sleep. Reuses `MessageQueue`'s native blocking wait; the enqueued value itself is never
    // read; only its arrival (or the timeout) matters.
    private final MessageQueue keepAliveSignalQueue;

    isolated function init(string wsUrl, WebSocketConfiguration config) {
        self.wsUrl = wsUrl;
        self.connectionInitTimeout = config.connectionInitTimeout;
        map<json>? connectionInitPayload = config.connectionInitPayload;
        self.connectionInitPayload = connectionInitPayload is () ? () : connectionInitPayload.cloneReadOnly();
        ReconnectConfig? reconnectConfig = config.reconnect;
        self.reconnectConfig = reconnectConfig is () ? () : reconnectConfig.cloneReadOnly();
        self.pingMessageHandler = config.pingMessageHandler;
        KeepAliveConfig keepAlive = config.keepAlive;
        self.keepAliveEnabled = keepAlive.enabled;
        self.keepAlivePingInterval = keepAlive.pingInterval;
        self.keepAlivePongTimeout = keepAlive.pongTimeout;
        self.keepAliveSignalQueue = new;
        self.initConnectionState();
        websocket:ClientConfiguration wsClientConfig = {
            ...config.websocketConfig,
            subProtocols: [GRAPHQL_TRANSPORT_WS]
        };
        if wsClientConfig.readTimeout == -1d {
            wsClientConfig.readTimeout = DEFAULT_IDLE_READ_TIMEOUT;
        }
        self.storeWebSocketClientConfig(wsClientConfig);
    }

    // Registers the subscription operation and sends the `subscribe` message, establishing the
    // connection when there is none. When a reconnection is in progress, the registered operation
    // is subscribed by the reconnection procedure upon its completion.
    isolated function subscribe(string id, readonly & json subscribeMessage, MessageQueue queue)
            returns ClientError? {
        if self.isClosed() {
            return error ClientError(CLIENT_ALREADY_CLOSED_MESSAGE);
        }
        self.lockState();
        // `trap` stands in for a try/finally: whatever happens inside the locked section --
        // including an unexpected panic -- `unlockState()` right below always runs, so a bug in the
        // critical section cannot leave the connection permanently locked. A caught panic is
        // re-panicked after unlocking, since `SubscribeStartOutcome` is a plain record and can never
        // itself be mistaken for one.
        SubscribeStartOutcome|error startTrapped = trap self.subscribeStart(id, subscribeMessage, queue);
        self.unlockState();
        if startTrapped is error {
            panic startTrapped;
        }
        if !startTrapped.mustConnect {
            return startTrapped.result;
        }
        // No live connection and none being established: this strand establishes it. The lock is
        // released across the blocking handshake so concurrent subscribe()/unsubscribe()/close()
        // calls are not stalled for up to `connectionInitTimeout`; the state is re-acquired and
        // re-validated afterwards (mirrors the reconnect() procedure).
        websocket:Client|SubscriptionError connectionResult = self.connect();
        self.lockState();
        SubscribeCompletion|error completionTrapped = trap self.subscribeAfterConnect(connectionResult);
        self.unlockState();
        if completionTrapped is error {
            panic completionTrapped;
        }
        if completionTrapped.closeConnection && connectionResult is websocket:Client {
            closeWebSocketClient(connectionResult);
        }
        return completionTrapped.result;
    }

    private isolated function subscribeStart(string id, readonly & json subscribeMessage, MessageQueue queue)
            returns SubscribeStartOutcome {
        // Re-check under the lock: the client may have been closed between the check in `subscribe()`
        // and acquiring the lock.
        if self.isClosed() {
            return {mustConnect: false, result: error ClientError(CLIENT_ALREADY_CLOSED_MESSAGE)};
        }
        if !self.registerOperation(id, queue, subscribeMessage) {
            return {mustConnect: false,
                    result: error SubscriptionError(string `A subscription with the id "${id}" already exists`,
                            errors = ())};
        }
        websocket:Client? wsClient = self.loadWsClient();
        if wsClient is websocket:Client {
            websocket:Error? result = wsClient->writeMessage(subscribeMessage);
            if result is websocket:Error {
                _ = self.removeOperation(id);
                return {mustConnect: false,
                        result: error SubscriptionError(
                                string `Failed to send the subscribe message: ${result.message()}`, result,
                                errors = ())};
            }
            return {mustConnect: false, result: ()};
        }
        if self.isConnecting() {
            // A connection is being established (initial or via reconnection); it subscribes this
            // operation upon completion.
            return {mustConnect: false, result: ()};
        }
        self.startConnecting();
        return {mustConnect: true, result: ()};
    }

    private isolated function subscribeAfterConnect(websocket:Client|SubscriptionError connectionResult)
            returns SubscribeCompletion {
        if self.isClosed() {
            self.markDisconnected();
            return {result: error ClientError(CLIENT_ALREADY_CLOSED_MESSAGE),
                    closeConnection: connectionResult is websocket:Client};
        }
        if connectionResult is SubscriptionError {
            self.markDisconnected();
            // Fail every operation waiting on this establishment, not just the current one.
            self.terminateAllStreams(connectionResult);
            return {result: connectionResult, closeConnection: false};
        }
        self.storeWsClient(connectionResult);
        // Send the subscribe message for this operation and any others registered while connecting.
        SubscriptionError? sendResult = self.sendPendingSubscribeMessages(connectionResult);
        if sendResult is SubscriptionError {
            self.storeWsClient(());
            self.markDisconnected();
            self.terminateAllStreams(sendResult);
            return {result: sendResult, closeConnection: true};
        }
        self.markConnected();
        return {result: (), closeConnection: false};
    }

    // Opens a WebSocket connection and performs the `graphql-transport-ws` handshake: sends the
    // `connection_init` message and waits for the `connection_ack` message, bounded by the
    // configured timeout. Starts the dispatcher for the connection.
    isolated function connect() returns websocket:Client|SubscriptionError {
        websocket:Client|websocket:Error wsClient = new (self.wsUrl, self.loadWebSocketClientConfig());
        if wsClient is websocket:Error {
            return error SubscriptionError(string `Failed to establish the WebSocket connection: ${wsClient.message()}`,
                    wsClient, errors = ());
        }
        websocket:Error? initResult = wsClient->writeMessage(self.getConnectionInitMessage());
        if initResult is websocket:Error {
            closeWebSocketClient(wsClient);
            return error SubscriptionError(string `Failed to send the connection_init message: ${initResult.message()}`,
                    initResult, errors = ());
        }
        MessageQueue ackQueue = new;
        _ = start self.dispatch(wsClient, ackQueue);
        any|error ack = ackQueue.dequeueWithTimeout(self.connectionInitTimeout);
        if ack is () {
            closeWebSocketClient(wsClient);
            return error SubscriptionError(HANDSHAKE_TIMED_OUT_MESSAGE, errors = ());
        }
        if ack is SubscriptionError {
            closeWebSocketClient(wsClient);
            return ack;
        }
        if ack is error {
            closeWebSocketClient(wsClient);
            return error SubscriptionError(ack.message(), ack, errors = ());
        }
        return wsClient;
    }

    isolated function getConnectionInitMessage() returns ConnectionInit {
        readonly & map<json>? payload = self.connectionInitPayload;
        if payload is () {
            return {'type: WS_INIT};
        }
        return {'type: WS_INIT, payload: payload};
    }

    // The background reader of a connection. Waits for the `connection_ack` message and signals
    // the handshake result through the given queue, then dispatches each incoming message to the
    // corresponding subscription operation until the connection fails or is closed.
    isolated function dispatch(websocket:Client wsClient, MessageQueue ackQueue) {
        boolean ackReceived = false;
        while !ackReceived {
            json|websocket:Error message = wsClient->readMessage();
            if message is websocket:ReadTimedOutError {
                // Idle read timeout, not a connection failure: retry the read.
                continue;
            }
            if message is websocket:Error {
                ackQueue.enqueue(error SubscriptionError(
                        string `Failed to establish the subscription connection: ${message.message()}`,
                        message, errors = ()));
                return;
            }
            string? messageType = getWsMessageType(message);
            if messageType == WS_ACK {
                ackQueue.enqueue(WS_ACK);
                ackReceived = true;
            } else if messageType == WS_PING {
                self.handlePingMessage(wsClient, message);
            } else if messageType == WS_PONG {
                // Pong messages are ignored.
            } else {
                ackQueue.enqueue(error SubscriptionError(
                        string `Unexpected message received while waiting for the connection_ack message`,
                        errors = ()));
                return;
            }
        }
        // The connection is established: start the keep-alive monitor for it, if enabled. The
        // monitor pings the server and closes this connection if the server stops responding.
        // `runKeepAliveLoop` (in `keep_alive.bal`) is shared with the server's keep-alive; only the
        // `ClientKeepAlivePeer` adapter below is specific to this side.
        KeepAliveMonitor? keepAliveMonitor = ();
        if self.keepAliveEnabled {
            KeepAliveMonitor monitor = new;
            keepAliveMonitor = monitor;
            ClientKeepAlivePeer peer = new (wsClient, self);
            _ = start runKeepAliveLoop(monitor, self.keepAliveSignalQueue, self.keepAlivePingInterval,
                    self.keepAlivePongTimeout, peer);
        }
        while true {
            json|websocket:Error message = wsClient->readMessage();
            if message is websocket:ReadTimedOutError {
                // Idle read timeout, not a connection failure: retry the read.
                continue;
            }
            if message is websocket:Error {
                if keepAliveMonitor is KeepAliveMonitor {
                    keepAliveMonitor.stop();
                    self.keepAliveSignalQueue.enqueue(());
                }
                self.handleConnectionFailure(wsClient);
                return;
            }
            if keepAliveMonitor is KeepAliveMonitor {
                if getWsMessageType(message) == WS_PONG {
                    // Only an actual `pong` resets the keep-alive timer, matching the convention
                    // established by the `graphql-ws` reference implementation (`enisdenjo/graphql-ws`):
                    // its client only resets on `message.type === 'pong'`, not on arbitrary traffic.
                    keepAliveMonitor.markPongReceived();
                    self.keepAliveSignalQueue.enqueue(());
                    continue;
                }
            }
            self.dispatchMessage(wsClient, message);
        }
    }

    // Handles a keep-alive timeout (the server stopped responding to `ping` messages). Mirrors
    // `handleConnectionFailure`, but closes the still-open WebSocket, and surfaces a
    // keep-alive-specific error when reconnection is not configured. The stored client is cleared
    // under the lock before closing, so the dispatcher's subsequent `handleConnectionFailure`
    // (triggered by that close) finds it already replaced and no-ops.
    isolated function handleKeepAliveTimeout(websocket:Client failedWsClient) {
        if self.isClosed() {
            return;
        }
        self.lockState();
        KeepAliveTimeoutOutcome|error trapped = trap self.handleKeepAliveTimeoutLocked(failedWsClient);
        self.unlockState();
        if trapped is error {
            panic trapped;
        }
        if trapped.action == "none" {
            return;
        }
        if trapped.action == "closeSync" {
            closeWebSocketClient(failedWsClient);
            return;
        }
        // "closeAsyncAndReconnect": closing a dead connection can block for up to
        // GRACEFUL_CLOSE_TIMEOUT waiting on an echo that never arrives; run it concurrently so a
        // slow close doesn't delay reconnection.
        _ = start closeWebSocketClient(failedWsClient);
        self.reconnect(trapped.reconnectConfig);
    }

    private isolated function handleKeepAliveTimeoutLocked(websocket:Client failedWsClient)
            returns KeepAliveTimeoutOutcome {
        if self.isClosed() || self.loadWsClient() !== failedWsClient {
            return {action: "none"};
        }
        self.storeWsClient(());
        // No active operations: close rather than reconnect to resume nothing.
        if self.getOperationIds().length() == 0 {
            return {action: "closeSync"};
        }
        readonly & ReconnectConfig? reconnectConfig = self.reconnectConfig;
        if reconnectConfig is () {
            self.terminateAllStreams(error SubscriptionError(KEEPALIVE_TIMEOUT_MESSAGE, errors = ()));
            return {action: "closeSync"};
        }
        self.startReconnecting();
        return {action: "closeAsyncAndReconnect", reconnectConfig: reconnectConfig};
    }

    isolated function dispatchMessage(websocket:Client wsClient, json message) {
        string? messageType = getWsMessageType(message);
        if messageType == WS_PING {
            self.handlePingMessage(wsClient, message);
            return;
        }
        if messageType == WS_NEXT || messageType == WS_ERROR || messageType == WS_COMPLETE {
            string? id = getWsMessageId(message);
            if id is () {
                return;
            }
            if messageType == WS_NEXT {
                // Messages received for an unknown ID are ignored.
                MessageQueue? queue = self.getQueue(id);
                if queue is MessageQueue {
                    json payload = getWsMessagePayload(message);
                    if payload is () {
                        // A nil item is MessageQueue's stream-completion sentinel; a `next` message
                        // must never enqueue it, or a malformed/payload-less frame would silently end
                        // the stream instead of surfacing an error.
                        queue.enqueue(error SubscriptionError(INVALID_SUBSCRIPTION_MESSAGE, errors = ()));
                    } else {
                        queue.enqueue(payload);
                    }
                }
                return;
            }
            MessageQueue? queue = self.removeOperation(id);
            if queue is () {
                return;
            }
            if messageType == WS_ERROR {
                queue.enqueue(getSubscriptionServerError(getWsMessagePayload(message)));
            } else {
                queue.enqueue(());
            }
        }
        // Messages with an unknown type are ignored.
    }

    isolated function handlePingMessage(websocket:Client wsClient, json message) {
        PingMessageHandler? pingMessageHandler = self.pingMessageHandler;
        if pingMessageHandler is () {
            Pong pongMessage = {'type: WS_PONG};
            websocket:Error? result = wsClient->writeMessage(pongMessage);
            if result is websocket:Error {
                logError("Failed to send the pong message", result);
            }
            return;
        }
        PingMessageCaller caller = new (wsClient);
        _ = start invokePingMessageHandler(pingMessageHandler, caller, getWsPingMessagePayload(message));
    }

    // Handles an abnormal closure of the connection: terminates the active subscription streams,
    // or runs the reconnection procedure when reconnection is configured.
    isolated function handleConnectionFailure(websocket:Client failedWsClient) {
        if self.isClosed() {
            return;
        }
        self.lockState();
        ConnectionFailureOutcome|error trapped = trap self.handleConnectionFailureLocked(failedWsClient);
        self.unlockState();
        if trapped is error {
            panic trapped;
        }
        if trapped.action == "reconnect" {
            self.reconnect(trapped.reconnectConfig);
        }
    }

    private isolated function handleConnectionFailureLocked(websocket:Client failedWsClient)
            returns ConnectionFailureOutcome {
        websocket:Client? currentWsClient = self.loadWsClient();
        if currentWsClient !== failedWsClient {
            // The failed connection was already replaced or cleaned up.
            return {action: "none"};
        }
        self.storeWsClient(());
        readonly & ReconnectConfig? reconnectConfig = self.reconnectConfig;
        if reconnectConfig is () {
            self.terminateAllStreams(error SubscriptionError(CONNECTION_DROPPED_MESSAGE, errors = ()));
            return {action: "none"};
        }
        self.startReconnecting();
        return {action: "reconnect", reconnectConfig: reconnectConfig};
    }

    // Attempts to re-establish the connection following the configured retry strategy. On success,
    // re-sends the `subscribe` message for every active operation with the original ID and payload.
    isolated function reconnect(readonly & ReconnectConfig reconnectConfig) {
        int attemptIndex = 0;
        while attemptIndex < reconnectConfig.maxAttempts {
            runtime:sleep(calculateBackOffDelay(reconnectConfig, attemptIndex));
            attemptIndex += 1;
            if self.isClosed() {
                self.markDisconnected();
                return;
            }
            websocket:Client|SubscriptionError connectionResult = self.connect();
            if connectionResult is SubscriptionError {
                continue;
            }
            self.lockState();
            ReconnectAttemptOutcome|error trapped = trap self.reconnectAttemptLocked(connectionResult);
            self.unlockState();
            if trapped is error {
                panic trapped;
            }
            if trapped == "done" {
                return;
            }
            closeWebSocketClient(connectionResult);
            if trapped == "closeAndReturn" {
                return;
            }
            // "closeAndRetry": fall through to the next attempt.
        }
        self.lockState();
        error? trapped = trap self.markReconnectionExhausted();
        self.unlockState();
        if trapped is error {
            panic trapped;
        }
    }

    private isolated function reconnectAttemptLocked(websocket:Client connectionResult)
            returns ReconnectAttemptOutcome {
        if self.isClosed() {
            self.markDisconnected();
            return "closeAndReturn";
        }
        self.storeWsClient(connectionResult);
        SubscriptionError? sendResult = self.sendPendingSubscribeMessages(connectionResult);
        if sendResult is () {
            self.markConnected();
            return "done";
        }
        self.storeWsClient(());
        return "closeAndRetry";
    }

    private isolated function markReconnectionExhausted() {
        self.markDisconnected();
        self.terminateAllStreams(error SubscriptionError(RECONNECTION_EXHAUSTED_MESSAGE, errors = ()));
    }

    isolated function sendPendingSubscribeMessages(websocket:Client wsClient) returns SubscriptionError? {
        foreach string id in self.getOperationIds() {
            json subscribeMessage = self.getSubscribeMessage(id);
            if subscribeMessage is () {
                continue;
            }
            websocket:Error? result = wsClient->writeMessage(subscribeMessage);
            if result is websocket:Error {
                return error SubscriptionError(string `Failed to send the subscribe message: ${result.message()}`,
                        result, errors = ());
            }
        }
        return;
    }

    // Removes the subscription operation and sends the `complete` message for it. The removal
    // happens before sending the message, guaranteeing that a user-closed operation is never
    // resubscribed by the reconnection logic.
    isolated function unsubscribe(string id) returns ClientError? {
        MessageQueue? queue = self.removeOperation(id);
        if queue is () {
            return;
        }
        queue.enqueue(());
        self.lockState();
        error? trapped = trap self.unsubscribeLocked(id);
        self.unlockState();
        if trapped is error {
            panic trapped;
        }
        return;
    }

    private isolated function unsubscribeLocked(string id) {
        websocket:Client? wsClient = self.loadWsClient();
        if wsClient is websocket:Client {
            Complete completeMessage = {'type: WS_COMPLETE, id: id};
            websocket:Error? result = wsClient->writeMessage(completeMessage);
            if result is websocket:Error {
                // A send failure on an already-dead connection is not an error.
                logError("Failed to send the complete message", result);
            }
        }
    }

    // Closes the connection: sends a `complete` message per active operation, closes the WebSocket
    // connection with a normal closure, and terminates every active subscription stream with `()`.
    // Calling this on an already-closed connection is a no-op.
    isolated function close() returns ClientError? {
        if !self.markClosed() {
            return;
        }
        // Wake up a keep-alive wait immediately, rather than leaving it to notice this only once the
        // dispatcher's blocked read errors out after the websocket below is closed.
        self.keepAliveSignalQueue.enqueue(());
        self.lockState();
        error? trapped = trap self.closeLocked();
        self.unlockState();
        if trapped is error {
            panic trapped;
        }
        return;
    }

    private isolated function closeLocked() {
        websocket:Client? wsClient = self.loadWsClient();
        if wsClient is websocket:Client {
            foreach string id in self.getOperationIds() {
                Complete completeMessage = {'type: WS_COMPLETE, id: id};
                websocket:Error? writeResult = wsClient->writeMessage(completeMessage);
                if writeResult is websocket:Error {
                    logError("Failed to send the complete message", writeResult);
                }
            }
            // Best-effort close. The background reader shares this connection and may consume the
            // peer's close-frame echo, so waiting for it (the default is 60s) is both slow and
            // unreliable; the connection is torn down regardless. A close-handshake failure is
            // logged rather than surfaced, so close() completes deterministically.
            websocket:Error? closeResult = wsClient->close(timeout = GRACEFUL_CLOSE_TIMEOUT);
            if closeResult is websocket:Error {
                logError("Failed to close the WebSocket connection gracefully", closeResult);
            }
            self.storeWsClient(());
        }
        self.terminateAllStreams(());
    }

    isolated function terminateAllStreams(SubscriptionError? cause) {
        foreach string id in self.getOperationIds() {
            MessageQueue? queue = self.removeOperation(id);
            if queue is MessageQueue {
                queue.enqueue(cause);
            }
        }
    }

    isolated function initConnectionState() = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function storeWebSocketClientConfig(websocket:ClientConfiguration config) = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function loadWebSocketClientConfig() returns websocket:ClientConfiguration = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function registerOperation(string id, MessageQueue queue, readonly & json subscribeMessage)
            returns boolean = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function removeOperation(string id) returns MessageQueue? = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function getOperationIds() returns string[] = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function getQueue(string id) returns MessageQueue? = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function getSubscribeMessage(string id) returns json = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function markClosed() returns boolean = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function isClosed() returns boolean = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function lockState() = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function unlockState() = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function isConnecting() returns boolean = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    // DISCONNECTED -> CONNECTING: the initial connection attempt for this client starts.
    isolated function startConnecting() = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    // CONNECTED -> RECONNECTING: a previously-live connection was lost and reconnection starts.
    isolated function startReconnecting() = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    // CONNECTING|RECONNECTING -> CONNECTED: a connection attempt succeeded.
    isolated function markConnected() = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    // CONNECTING|RECONNECTING -> DISCONNECTED: a connection attempt failed, or reconnection was exhausted.
    isolated function markDisconnected() = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function storeWsClient(websocket:Client? wsClient) = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function loadWsClient() returns websocket:Client? = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;
}

// Adapts a subscription connection's WebSocket client to `KeepAlivePeer` (`keep_alive.bal`) so its
// keep-alive loop can share `runKeepAliveLoop` with the server's (`websocket_service.bal`'s
// `ServerKeepAlivePeer`).
isolated class ClientKeepAlivePeer {
    *KeepAlivePeer;

    private final websocket:Client wsClient;
    private final SubscriptionConnection connection;

    isolated function init(websocket:Client wsClient, SubscriptionConnection connection) {
        self.wsClient = wsClient;
        self.connection = connection;
    }

    isolated function sendPing() returns boolean {
        Ping pingMessage = {'type: WS_PING};
        websocket:Error? result = self.wsClient->writeMessage(pingMessage);
        return result is ();
    }

    isolated function onKeepAliveTimeout() {
        self.connection.handleKeepAliveTimeout(self.wsClient);
    }

    isolated function isExternallyStopped() returns boolean {
        // The connection may have been closed by the user without a live `KeepAliveMonitor` at
        // hand to call `stop()` on directly -- see `keep_alive.bal`'s doc comment on `KeepAlivePeer`.
        return self.connection.isClosed();
    }
}

isolated function invokePingMessageHandler(PingMessageHandler handler, PingMessageCaller caller,
        readonly & map<json>? payload) {
    error? result = trap handler(caller, payload);
    if result is error {
        logError("Error occurred while executing the ping message handler", result);
    }
}

isolated function closeWebSocketClient(websocket:Client wsClient) {
    websocket:Error? result = wsClient->close(timeout = GRACEFUL_CLOSE_TIMEOUT);
    if result is websocket:Error {
        logError("Failed to close the WebSocket connection", result);
    }
}

isolated function getWsMessageType(json message) returns string? {
    if message is map<json> {
        json messageType = message[WS_MESSAGE_TYPE_FIELD];
        if messageType is string {
            return messageType;
        }
    }
    return;
}

isolated function getWsMessageId(json message) returns string? {
    if message is map<json> {
        json id = message[WS_MESSAGE_ID_FIELD];
        if id is string {
            return id;
        }
    }
    return;
}

isolated function getWsMessagePayload(json message) returns json {
    if message is map<json> {
        return message[WS_MESSAGE_PAYLOAD_FIELD];
    }
    return;
}

isolated function getWsPingMessagePayload(json message) returns readonly & map<json>? {
    json payload = getWsMessagePayload(message);
    if payload is map<json> {
        return payload.cloneReadOnly();
    }
    return;
}

isolated function getSubscriptionServerError(json payload) returns SubscriptionError {
    // The protocol specifies the payload as an array of GraphQL errors, but some servers
    // (including the Ballerina GraphQL listener) wrap the array in an `errors` field.
    json errorsJson = payload;
    if payload is map<json> && payload.hasKey(ERRORS_FIELD) {
        errorsJson = payload.get(ERRORS_FIELD);
    }
    ErrorDetail[]|error errors = errorsJson.cloneWithType();
    if errors is error {
        return error SubscriptionError(SUBSCRIPTION_SERVER_ERROR_MESSAGE, errors = ());
    }
    return error SubscriptionError(SUBSCRIPTION_SERVER_ERROR_MESSAGE, errors = errors);
}
