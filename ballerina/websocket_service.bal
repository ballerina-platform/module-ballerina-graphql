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
    private PingMessageJob? pingMessageHandler = ();
    private PongMessageHandlerJob? pongMessageHandler = ();

    isolated function init(Engine engine, __Schema & readonly schema, Context context) {
        self.engine = engine;
        self.schema = schema;
        self.context = context;
    }

    isolated remote function onIdleTimeout() returns ConnectionInitialisationTimeout? {
        lock {
            if !self.initiatedConnection {
                return CONNECTION_INITIALISATION_TIMEOUT;
            }
        }
        return;
    }

    @websocket:DispatcherMapping {
        value: "ping"
    }
    isolated remote function onPingMessage(Ping ping) returns Pong {
        return {'type: WS_PONG};
    }

    @websocket:DispatcherMapping {
        value: "pong"
    }
    isolated remote function onPongMessage(Pong pong) {
        lock {
            PongMessageHandlerJob? handler = self.pongMessageHandler;
            if handler !is () {
                handler.setPongMessageReceived();
            }
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
        self.startSendingPingMessages(caller);
        self.schedulePongMessageHandler(caller);
        return {'type: WS_ACK};
    }

    isolated remote function onSubscribe(websocket:Caller caller, Subscribe message)
    returns Unauthorized|SubscriberAlreadyExists|ErrorMessage? {
        SubscriptionHandler|Unauthorized|SubscriberAlreadyExists handler = self.validateSubscriptionRequest(message);
        if handler is Unauthorized|SubscriberAlreadyExists {
            return handler;
        }
        parser:OperationNode|json node = validateSubscriptionPayload(message, self.engine);
        if node is parser:OperationNode {
            _ = start executeOperation(self.engine, self.context, self.schema, caller, node, handler);
            return;
        }
        return {'type: WS_ERROR, id: handler.getId(), payload: node};
    }

    isolated remote function onMessage() returns websocket:UnsupportedData {
        string detail = "payload does not conform to the format required by the '" +
            GRAPHQL_TRANSPORT_WS + "' subprotocol";
        return {status: 1003, reason: string `Invalid format: ${detail}`};
    }

    isolated remote function onError(error errorMessage) returns websocket:UnsupportedData|error? {
        if errorMessage.message().endsWith("ConversionError") {
            string detail = "payload does not conform to the format required by the '" +
            GRAPHQL_TRANSPORT_WS + "' subprotocol";
            return {status: 1003, reason: string `Invalid format: ${detail}`};
        }
        return errorMessage;
    }

    remote function onClose(websocket:Caller caller) {
        self.unschedulePingPongHandlers();
    }

    private isolated function startSendingPingMessages(websocket:Caller caller) {
        lock {
            if self.pingMessageHandler !is () || !self.initiatedConnection {
                return;
            }
            PingMessageJob job = new PingMessageJob(caller);
            job.schedule();
            self.pingMessageHandler = job;
        }
    }

    private isolated function handlePingRequest(websocket:Caller caller) returns websocket:Error? {
        Pong response = {'type: WS_PONG};
        check writeMessage(caller, response);
    }

    private isolated function schedulePongMessageHandler(websocket:Caller caller) {
        lock {
            if !self.initiatedConnection || self.pongMessageHandler is PongMessageHandlerJob {
                return;
            }
            PongMessageHandlerJob handler = new (caller);
            handler.schedule();
            self.pongMessageHandler = handler;
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

    private isolated function unschedulePingPongHandlers() {
        lock {
            PingMessageJob? pingMessageHandler = self.pingMessageHandler;
            PongMessageHandlerJob? pongMessageHandler = self.pongMessageHandler;
            if pingMessageHandler is PingMessageJob {
                error? err = pingMessageHandler.unschedule();
                if err is error {
                    logError(err.message(), err);
                }
            }
            if pongMessageHandler is PongMessageHandlerJob {
                error? err = pongMessageHandler.unschedule();
                if err is error {
                    logError(err.message(), err);
                }
            }
        }
    }
}
