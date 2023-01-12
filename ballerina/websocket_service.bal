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

import ballerina/lang.value;
import ballerina/websocket;
import graphql.parser;

isolated service class WsService {
    *websocket:Service;

    private final Engine engine;
    private final readonly & __Schema schema;
    private final Context context;
    private final map<SubscriptionHandler> activeConnections;
    private final readonly & map<string> customHeaders;
    private boolean initiatedConnection;

    isolated function init(Engine engine, __Schema & readonly schema, map<string> & readonly customHeaders,
                           Context context) {
        self.engine = engine;
        self.schema = schema;
        self.context = context;
        self.customHeaders = customHeaders;
        self.activeConnections = {};
        self.initiatedConnection = false;
    }

    isolated remote function onIdleTimeout(websocket:Caller caller) returns websocket:Error? {
        lock {
            if !self.initiatedConnection {
                SubscriptionError err = error("Connection initialisation timeout", code = 4408);
                return closeConnection(caller, err);
            }
        }
    }

    isolated remote function onMessage(websocket:Caller caller, string text) returns websocket:Error? {
        SubscriptionError? validationError = validateSubProtocol(caller, self.customHeaders);
        if validationError is SubscriptionError {
            return closeConnection(caller, validationError);
        }

        Message|SubscriptionError message = self.castToMessage(text);
        if message is SubscriptionError {
            return closeConnection(caller, message);
        }
        if message is ConnectionInitMessage {
            return self.handleConnectionInitRequest(caller);
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
    }

    private isolated function castToMessage(string text) returns Message|SubscriptionError {
        do {
            json jsonValue = check value:fromJsonString(text);
            Message message = check jsonValue.cloneWithType();
            return message;
        } on fail {
            string detail = "payload does not conform to the format required by the '" +
                GRAPHQL_TRANSPORT_WS + "' subprotocol";
            return error(string `Invalid format: ${detail}`, code = 1003);
        }
    }

    private isolated function handleConnectionInitRequest(websocket:Caller caller) returns websocket:Error? {
        lock {
            if self.initiatedConnection {
                SubscriptionError err = error("Too many initialisation requests", code = 4429);
                return closeConnection(caller, err);
            }
            ConnectionAckMessage response = {'type: WS_ACK};
            check caller->writeMessage(response);
            self.initiatedConnection = true;
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
        } else {
            ErrorMessage response = {'type: WS_ERROR, id: handler.getId(), payload: node};
            check caller->writeMessage(response);
        }
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
        return caller->writeMessage(response);
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
}
