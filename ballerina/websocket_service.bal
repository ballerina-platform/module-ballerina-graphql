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

import ballerina/time;
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
    private boolean activityReceived = false;
    private boolean keepAliveStopped = false;

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
        self.markActivity();
        return {'type: WS_PONG};
    }

    @websocket:DispatcherConfig {
        dispatcherValue: "pong"
    }
    isolated remote function onPongMessage(Pong pong) {
        self.markActivity();
    }

    isolated remote function onComplete(Complete message) {
        self.markActivity();
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
            _ = start self.runKeepAlive(caller);
        }
        return {'type: WS_ACK};
    }

    remote function onSubscribe(Subscribe message)
    returns stream<Next|Complete|ErrorMessage, error?>|Unauthorized|SubscriberAlreadyExists {
        self.markActivity();
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
        self.stopKeepAlive();
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

    // Pings only when idle; tears down only after KEEPALIVE_MAX_MISSED_PROBES silent cycles.
    isolated function runKeepAlive(websocket:Caller caller) {
        int missedProbes = 0;
        while true {
            self.resetActivity();
            if self.keepAliveWait(self.keepAliveConfig.pingInterval, false) {
                return;
            }
            if self.isActivityReceived() {
                missedProbes = 0;
                continue;
            }
            Ping pingMessage = {'type: WS_PING};
            websocket:Error? result = writeMessage(caller, pingMessage);
            if result is websocket:Error {
                return;
            }
            if self.keepAliveWait(self.keepAliveConfig.pongTimeout, true) {
                return;
            }
            if self.isActivityReceived() {
                missedProbes = 0;
                continue;
            }
            // Tolerates isolated misses; see ballerina-library#8929.
            missedProbes += 1;
            if missedProbes >= KEEPALIVE_MAX_MISSED_PROBES {
                ServerSubscriptionError err = error("Request timeout", code = 4408);
                closeConnection(caller, err);
                return;
            }
        }
    }

    // Woken early by activity instead of sleeping blindly; mirrors the client's `keepAliveWait`
    // in `client_subscription_connection.bal`.
    isolated function keepAliveWait(decimal duration, boolean stopOnActivity) returns boolean {
        decimal remaining = duration;
        while remaining > 0d {
            if self.isKeepAliveStopped() {
                return true;
            }
            if stopOnActivity && self.isActivityReceived() {
                return false;
            }
            decimal waitStart = time:monotonicNow();
            any|error signal = self.keepAliveSignalQueue.dequeueWithTimeout(remaining);
            decimal elapsed = time:monotonicNow() - waitStart;
            remaining = elapsed < remaining ? remaining - elapsed : 0d;
        }
        return self.isKeepAliveStopped();
    }

    isolated function markActivity() {
        lock {
            self.activityReceived = true;
        }
        self.keepAliveSignalQueue.enqueue(());
    }

    isolated function resetActivity() {
        lock {
            self.activityReceived = false;
        }
    }

    isolated function isActivityReceived() returns boolean {
        lock {
            return self.activityReceived;
        }
    }

    isolated function stopKeepAlive() {
        lock {
            self.keepAliveStopped = true;
        }
        self.keepAliveSignalQueue.enqueue(());
    }

    isolated function isKeepAliveStopped() returns boolean {
        lock {
            return self.keepAliveStopped;
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
