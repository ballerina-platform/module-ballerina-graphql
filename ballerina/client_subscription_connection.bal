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
import ballerina/time;
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

// Manages the WebSocket connection of a GraphQL client used for subscriptions, implementing the
// `graphql-transport-ws` protocol: the connection establishment with the handshake, the
// multiplexing of the subscription operations over the single connection, and the reconnection.
//
// The mutable state of the connection lives in a Java state holder with concurrent-safe data
// structures (see `SubscriptionConnectionState.java`); compound state transitions are serialized
// through its `lockState()`/`unlockState()` functions. Ballerina `lock` statements are
// intentionally not used.
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
        // Re-check under the lock: the client may have been closed between the check above and
        // acquiring the lock.
        if self.isClosed() {
            self.unlockState();
            return error ClientError(CLIENT_ALREADY_CLOSED_MESSAGE);
        }
        if !self.registerOperation(id, queue, subscribeMessage) {
            self.unlockState();
            return error SubscriptionError(string `A subscription with the id "${id}" already exists`, errors = ());
        }
        websocket:Client? wsClient = self.loadWsClient();
        if wsClient is websocket:Client {
            websocket:Error? result = wsClient->writeMessage(subscribeMessage);
            if result is websocket:Error {
                _ = self.removeOperation(id);
                self.unlockState();
                return error SubscriptionError(string `Failed to send the subscribe message: ${result.message()}`,
                        result, errors = ());
            }
            self.unlockState();
            return;
        }
        if self.isConnecting() {
            // A connection is being established (initial or via reconnection); it subscribes this
            // operation upon completion.
            self.unlockState();
            return;
        }
        // No live connection and none being established: this strand establishes it. The lock is
        // released across the blocking handshake so concurrent subscribe()/unsubscribe()/close()
        // calls are not stalled for up to `connectionInitTimeout`; the state is re-acquired and
        // re-validated afterwards (mirrors the reconnect() procedure).
        self.setConnecting(true);
        self.unlockState();
        websocket:Client|SubscriptionError connectionResult = self.connect();
        self.lockState();
        if self.isClosed() {
            self.setConnecting(false);
            self.unlockState();
            if connectionResult is websocket:Client {
                closeWebSocketClient(connectionResult);
            }
            return error ClientError(CLIENT_ALREADY_CLOSED_MESSAGE);
        }
        if connectionResult is SubscriptionError {
            self.setConnecting(false);
            // Fail every operation waiting on this establishment, not just the current one.
            self.terminateAllStreams(connectionResult);
            self.unlockState();
            return connectionResult;
        }
        self.storeWsClient(connectionResult);
        // Send the subscribe message for this operation and any others registered while connecting.
        SubscriptionError? sendResult = self.sendPendingSubscribeMessages(connectionResult);
        self.setConnecting(false);
        if sendResult is SubscriptionError {
            self.storeWsClient(());
            self.terminateAllStreams(sendResult);
            self.unlockState();
            closeWebSocketClient(connectionResult);
            return sendResult;
        }
        self.unlockState();
        return;
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
        KeepAliveMonitor? keepAliveMonitor = ();
        if self.keepAliveEnabled {
            KeepAliveMonitor monitor = new;
            keepAliveMonitor = monitor;
            _ = start self.runKeepAlive(wsClient, monitor);
        }
        while true {
            json|websocket:Error message = wsClient->readMessage();
            if message is websocket:Error {
                if keepAliveMonitor is KeepAliveMonitor {
                    keepAliveMonitor.stop();
                    self.keepAliveSignalQueue.enqueue(());
                }
                self.handleConnectionFailure(wsClient);
                return;
            }
            if keepAliveMonitor is KeepAliveMonitor {
                // Any incoming message -- not just a `pong` -- counts as a liveness signal: the
                // connection is demonstrably alive if the server is sending anything at all. See
                // `markLivenessSignalReceived()`'s doc comment.
                keepAliveMonitor.markLivenessSignalReceived();
                self.keepAliveSignalQueue.enqueue(());
                if getWsMessageType(message) == WS_PONG {
                    continue;
                }
            }
            self.dispatchMessage(wsClient, message);
        }
    }

    // Pings only when idle; tears down only after KEEPALIVE_MAX_MISSED_PROBES silent cycles.
    isolated function runKeepAlive(websocket:Client wsClient, KeepAliveMonitor monitor) {
        int missedProbes = 0;
        while true {
            monitor.resetLivenessSignal();
            if self.keepAliveWait(self.keepAlivePingInterval, monitor, false) {
                return;
            }
            if monitor.isLivenessSignalReceived() {
                missedProbes = 0;
                continue;
            }
            Ping pingMessage = {'type: WS_PING};
            websocket:Error? result = wsClient->writeMessage(pingMessage);
            if result is websocket:Error {
                // The connection is already going down; the dispatcher handles the failure.
                return;
            }
            if self.keepAliveWait(self.keepAlivePongTimeout, monitor, true) {
                return;
            }
            if monitor.isLivenessSignalReceived() {
                missedProbes = 0;
                continue;
            }
            // Tolerates isolated misses; see ballerina-library#8929.
            missedProbes += 1;
            if missedProbes >= KEEPALIVE_MAX_MISSED_PROBES {
                self.handleKeepAliveTimeout(wsClient);
                return;
            }
        }
    }

    // Waits for up to `duration` seconds, blocking on `keepAliveSignalQueue` rather than sleeping, so
    // the wait ends the instant a signal arrives instead of only being noticed at the end of
    // `duration`. A signal is enqueued when the connection is closed, when the dispatcher notices the
    // connection is gone, and -- relevant only when `stopOnPong` is set -- when the dispatcher
    // receives the pong being waited for. The underlying strand is genuinely blocked while waiting
    // (via `MessageQueue`'s native, timed queue take), not periodically polling, so this adds no
    // scheduling overhead beyond the signals that are already being sent.
    //
    // A signal that turns out not to be relevant to this particular wait (for example, a pong signal
    // arriving while waiting out the ping interval, which does not care about pongs) is not treated as
    // done: the actual state is re-checked and, if not yet resolved, the wait resumes for whatever
    // duration remains, measured with a monotonic clock so an early wake-up does not reset the budget.
    //
    // Returns `true` if the connection was closed or the monitor was stopped while waiting, in which
    // case the caller must stop the keep-alive loop entirely rather than proceed to the next step.
    isolated function keepAliveWait(decimal duration, KeepAliveMonitor monitor, boolean stopOnPong) returns boolean {
        decimal remaining = duration;
        while remaining > 0d {
            if self.isClosed() || monitor.isStopped() {
                return true;
            }
            if stopOnPong && monitor.isLivenessSignalReceived() {
                return false;
            }
            decimal waitStart = time:monotonicNow();
            any|error signal = self.keepAliveSignalQueue.dequeueWithTimeout(remaining);
            decimal elapsed = time:monotonicNow() - waitStart;
            remaining = elapsed < remaining ? remaining - elapsed : 0d;
        }
        return self.isClosed() || monitor.isStopped();
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
        if self.isClosed() || self.loadWsClient() !== failedWsClient {
            self.unlockState();
            return;
        }
        self.storeWsClient(());
        // No active operations: close rather than reconnect to resume nothing.
        if self.getOperationIds().length() == 0 {
            self.unlockState();
            closeWebSocketClient(failedWsClient);
            return;
        }
        readonly & ReconnectConfig? reconnectConfig = self.reconnectConfig;
        if reconnectConfig is () {
            self.terminateAllStreams(error SubscriptionError(KEEPALIVE_TIMEOUT_MESSAGE, errors = ()));
            self.unlockState();
            closeWebSocketClient(failedWsClient);
            return;
        }
        self.setConnecting(true);
        self.unlockState();
        // Closing a dead connection can block for up to GRACEFUL_CLOSE_TIMEOUT waiting on an echo
        // that never arrives; run it concurrently so a slow close doesn't delay reconnection.
        _ = start closeWebSocketClient(failedWsClient);
        self.reconnect(reconnectConfig);
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
                    queue.enqueue(getWsMessagePayload(message));
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
        websocket:Client? currentWsClient = self.loadWsClient();
        if currentWsClient !== failedWsClient {
            // The failed connection was already replaced or cleaned up.
            self.unlockState();
            return;
        }
        self.storeWsClient(());
        readonly & ReconnectConfig? reconnectConfig = self.reconnectConfig;
        if reconnectConfig is () {
            self.terminateAllStreams(error SubscriptionError(CONNECTION_DROPPED_MESSAGE, errors = ()));
            self.unlockState();
            return;
        }
        self.setConnecting(true);
        self.unlockState();
        self.reconnect(reconnectConfig);
    }

    // Attempts to re-establish the connection following the configured retry strategy. On success,
    // re-sends the `subscribe` message for every active operation with the original ID and payload.
    isolated function reconnect(readonly & ReconnectConfig reconnectConfig) {
        int attemptIndex = 0;
        while attemptIndex < reconnectConfig.maxAttempts {
            runtime:sleep(calculateBackOffDelay(reconnectConfig, attemptIndex));
            attemptIndex += 1;
            if self.isClosed() {
                self.setConnecting(false);
                return;
            }
            websocket:Client|SubscriptionError connectionResult = self.connect();
            if connectionResult is SubscriptionError {
                continue;
            }
            self.lockState();
            if self.isClosed() {
                self.setConnecting(false);
                self.unlockState();
                closeWebSocketClient(connectionResult);
                return;
            }
            self.storeWsClient(connectionResult);
            SubscriptionError? sendResult = self.sendPendingSubscribeMessages(connectionResult);
            if sendResult is () {
                self.setConnecting(false);
                self.unlockState();
                return;
            }
            self.storeWsClient(());
            self.unlockState();
            closeWebSocketClient(connectionResult);
        }
        self.lockState();
        self.setConnecting(false);
        self.terminateAllStreams(error SubscriptionError(RECONNECTION_EXHAUSTED_MESSAGE, errors = ()));
        self.unlockState();
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
        websocket:Client? wsClient = self.loadWsClient();
        if wsClient is websocket:Client {
            Complete completeMessage = {'type: WS_COMPLETE, id: id};
            websocket:Error? result = wsClient->writeMessage(completeMessage);
            if result is websocket:Error {
                // A send failure on an already-dead connection is not an error.
                logError("Failed to send the complete message", result);
            }
        }
        self.unlockState();
        return;
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
        self.unlockState();
        return;
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

    isolated function setConnecting(boolean connecting) = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function isConnecting() returns boolean = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function storeWsClient(websocket:Client? wsClient) = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;

    isolated function loadWsClient() returns websocket:Client? = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.SubscriptionConnectionState"
    } external;
}

// Tracks the liveness signal shared between a connection's keep-alive loop (`runKeepAlive`) and its
// dispatcher. The keep-alive loop resets and checks `livenessSignalReceived` around each `ping`; the
// dispatcher sets it upon reading *any* message, not just a `pong` -- receiving anything at all from
// the server, including ordinary subscription traffic, is itself proof the connection is alive, so it
// counts as a liveness signal the same way an explicit `pong` does. `stopped` lets the dispatcher stop
// the loop promptly when the connection ends for another reason.
isolated class KeepAliveMonitor {
    private boolean livenessSignalReceived = false;
    private boolean stopped = false;

    isolated function markLivenessSignalReceived() {
        lock {
            self.livenessSignalReceived = true;
        }
    }

    isolated function resetLivenessSignal() {
        lock {
            self.livenessSignalReceived = false;
        }
    }

    isolated function isLivenessSignalReceived() returns boolean {
        lock {
            return self.livenessSignalReceived;
        }
    }

    isolated function stop() {
        lock {
            self.stopped = true;
        }
    }

    isolated function isStopped() returns boolean {
        lock {
            return self.stopped;
        }
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
