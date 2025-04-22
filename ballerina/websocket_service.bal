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

import ballerina/websocket;
import graphql.parser;

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

    isolated remote function onMessage(websocket:Caller caller, string text) returns websocket:Error? {
        InboundMessage|SubscriptionError message = castToMessage(text);
        if message is SubscriptionError {
            return closeConnection(caller, message);
        }
        if message is ConnectionInitMessage {
            check self.handleConnectionInitRequest(caller);
            self.startSendingPingMessages(caller);
            return self.schedulePongMessageHandler(caller);
        }
        if message is SubscribeMessage {
            return self.handleSubscriptionRequest(caller, message);
        }
        if message is CompleteMessage {
            return self.handleCompleteRequest(message);
        }
        if message is PingMessage {
            return self.handlePingRequest(caller);
        }
        if message is PongMessage {
            return self.handlePongRequest();
        }
    }

    remote function onClose(websocket:Caller caller) {
        self.unschedulePingPongHandlers();
    }

    private isolated function handleConnectionInitRequest(websocket:Caller caller) returns websocket:Error? {
        lock {
            if self.initiatedConnection {
                SubscriptionError err = error("Too many initialisation requests", code = 4429);
                return closeConnection(caller, err);
            }
            ConnectionAckMessage response = {'type: WS_ACK};
            check writeMessage(caller, response);
            self.initiatedConnection = true;
        }
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

    private isolated function handleSubscriptionRequest(websocket:Caller caller, SubscribeMessage message)
    returns websocket:Error? {
        SubscriptionHandler|SubscriptionError handler = self.validateSubscriptionRequest(message);
        if handler is SubscriptionError {
            return closeConnection(caller, handler);
        }
        parser:OperationNode|json node = validateSubscriptionPayload(message, self.engine);
        if node is parser:OperationNode {
            _ = start executeOperation(self.engine, self.context, self.schema, caller, node, handler);
            return;
        }
        ErrorMessage response = {'type: WS_ERROR, id: handler.getId(), payload: node};
        check writeMessage(caller, response);
    }

    private isolated function handleCompleteRequest(CompleteMessage message) {
        lock {
            if !self.activeConnections.hasKey(message.id) {
                return;
            }
            SubscriptionHandler handler = self.activeConnections.remove(message.id);
            handler.setUnsubscribed();
        }
        return;
    }

    private isolated function handlePingRequest(websocket:Caller caller) returns websocket:Error? {
        PongMessage response = {'type: WS_PONG};
        check writeMessage(caller, response);
    }

    private isolated function handlePongRequest() {
        lock {
            PongMessageHandlerJob? handler = self.pongMessageHandler;
            if handler is () {
                return;
            }
            handler.setPongMessageReceived();
        }
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

    private isolated function validateSubscriptionRequest(SubscribeMessage message)
    returns SubscriptionHandler|SubscriptionError {
        SubscriptionHandler handler = new (message.id);
        lock {
            if !self.initiatedConnection {
                return error("Unauthorized", code = 4401);
            }
            if self.activeConnections.hasKey(message.id) {
                return error(string `Subscriber for ${message.id} already exists`, code = 4409);
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
