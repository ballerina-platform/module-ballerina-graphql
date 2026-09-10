// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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

import graphql.parser;

import ballerina/websocket;

isolated service class WsService {
    *websocket:Service;

    private final Engine engine;
    private final readonly & __Schema schema;
    private final Context context;
    private final map<SubscriptionHandler> activeConnections = {};
    private boolean initiatedConnection = false;
    private final readonly & ServerKeepAliveConfig keepAliveConfig;
    private final MessageQueue keepAliveSignalQueue;
    // Created once `onConnectionInit` starts the keep-alive loop (if enabled); `onPongMessage` and
    // `onClose` reach it through `loadKeepAliveMonitor()` to report a pong or a stop.
    private KeepAliveMonitor? keepAliveMonitor = ();

    isolated function init(Engine engine, __Schema & readonly schema, Context context,
            readonly & ServerKeepAliveConfig keepAliveConfig) {
        self.engine = engine;
        self.schema = schema;
        self.context = context;
        self.keepAliveConfig = keepAliveConfig;
        self.keepAliveSignalQueue = new;
    }

    isolated remote function onIdleTimeout() returns ConnectionInitialisationTimeout? {
        lock {
            if !self.initiatedConnection {
                return CONNECTION_INITIALISATION_TIMEOUT;
            }
        }
        return;
    }

    @websocket:DispatcherConfig {
        dispatcherValue: "ping"
    }
    isolated remote function onPingMessage(Ping ping) returns Pong {
        // A `ping` initiated by the client is answered with a `pong` (required by the protocol),
        // but it is not itself a response to this server's own keep-alive probe, so it does not
        // reset the missed-probe counter -- only an actual `pong` does (see `onPongMessage`).
        return {'type: WS_PONG};
    }

    @websocket:DispatcherConfig {
        dispatcherValue: "pong"
    }
    isolated remote function onPongMessage(Pong pong) {
        KeepAliveMonitor? monitor = self.loadKeepAliveMonitor();
        if monitor is KeepAliveMonitor {
            monitor.markPongReceived();
            self.keepAliveSignalQueue.enqueue(());
        }
    }

    isolated remote function onComplete(Complete message) {
        lock {
            if self.activeConnections.hasKey(message.id) {
                SubscriptionHandler handler = self.activeConnections.remove(message.id);
                handler.setUnsubscribed();
            }
        }
    }

    isolated remote function onConnectionInit(websocket:Caller caller, ConnectionInit message)
    returns ConnectionAck|TooManyInitializationRequests|error? {
        lock {
            if self.initiatedConnection {
                return TOO_MANY_INITIALIZATION_REQUESTS;
            }
            self.initiatedConnection = true;
        }
        if self.keepAliveConfig.enabled {
            // `runKeepAliveLoop` (in `keep_alive.bal`) is shared with the client's keep-alive; only
            // the `ServerKeepAlivePeer` adapter below is specific to this side.
            KeepAliveMonitor monitor = new;
            self.storeKeepAliveMonitor(monitor);
            ServerKeepAlivePeer peer = new (caller);
            _ = start runKeepAliveLoop(monitor, self.keepAliveSignalQueue, self.keepAliveConfig.pingInterval,
                    self.keepAliveConfig.pongTimeout, peer);
        }
        return {'type: WS_ACK};
    }

    remote function onSubscribe(Subscribe message)
    returns stream<Next|Complete|ErrorMessage, error?>|Unauthorized|SubscriberAlreadyExists {
        SubscriptionHandler|Unauthorized|SubscriberAlreadyExists handler = self.validateSubscriptionRequest(message);
        if handler is Unauthorized|SubscriberAlreadyExists {
            return handler;
        }
        parser:OperationNode|json node = validateSubscriptionPayload(message, self.engine);
        return getResultStream(self.engine, self.context, self.schema, node, handler);
    }

    isolated remote function onMessage() returns websocket:UnsupportedData {
        string detail = "payload does not conform to the format required by the '" +
            GRAPHQL_TRANSPORT_WS + "' subprotocol";
        return {status: 1003, reason: string `Invalid format: ${detail}`};
    }

    isolated remote function onError(error errorMessage) returns websocket:UnsupportedData|error {
        if errorMessage.message().endsWith("ConversionError") {
            string detail = "payload does not conform to the format required by the '" +
            GRAPHQL_TRANSPORT_WS + "' subprotocol";
            return {status: 1003, reason: string `Invalid format: ${detail}`};
        }
        return errorMessage;
    }

    remote function onClose(websocket:Caller caller) {
        KeepAliveMonitor? monitor = self.loadKeepAliveMonitor();
        if monitor is KeepAliveMonitor {
            monitor.stop();
            self.keepAliveSignalQueue.enqueue(());
        }
        // Without this, a subscription whose resolver is mid-call when the connection closes (e.g.
        // blocked producing the next value) keeps calling that resolver forever: onComplete is the
        // only other place a handler is marked unsubscribed, and it never fires for a connection that
        // closes out from under an active subscription (idle timeout, keep-alive teardown, abrupt
        // client disconnect).
        lock {
            foreach SubscriptionHandler handler in self.activeConnections {
                handler.setUnsubscribed();
            }
            self.activeConnections.removeAll();
        }
    }

    isolated function storeKeepAliveMonitor(KeepAliveMonitor monitor) {
        lock {
            self.keepAliveMonitor = monitor;
        }
    }

    isolated function loadKeepAliveMonitor() returns KeepAliveMonitor? {
        lock {
            return self.keepAliveMonitor;
        }
    }

    private isolated function validateSubscriptionRequest(Subscribe message)
    returns SubscriptionHandler|Unauthorized|SubscriberAlreadyExists {
        SubscriptionHandler handler = new (message.id);
        lock {
            if !self.initiatedConnection {
                return UNAUTHORIZED;
            }
            if self.activeConnections.hasKey(message.id) {
                return {status: 4409, reason: string `Subscriber for ${message.id} already exists`};
            }
            self.activeConnections[message.id] = handler;
        }
        return handler;
    }
}

// Adapts a WebSocket caller to `KeepAlivePeer` (`keep_alive.bal`) so the server's keep-alive loop
// can share `runKeepAliveLoop` with the client's (`client_subscription_connection.bal`'s
// `ClientKeepAlivePeer`).
isolated class ServerKeepAlivePeer {
    *KeepAlivePeer;

    private final websocket:Caller caller;

    isolated function init(websocket:Caller caller) {
        self.caller = caller;
    }

    isolated function sendPing() returns boolean {
        Ping pingMessage = {'type: WS_PING};
        websocket:Error? result = writeMessage(self.caller, pingMessage);
        return result is ();
    }

    isolated function onKeepAliveTimeout() {
        ServerSubscriptionError err = error("Request timeout", code = 4408);
        closeConnection(self.caller, err);
    }

    isolated function isExternallyStopped() returns boolean {
        // WsService.onClose() calls stop() on this connection's one keep-alive monitor directly,
        // so there is no additional stop condition to report here.
        return false;
    }
}
