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

import ballerina/lang.array;
import ballerina/lang.value;
import ballerina/websocket;
import graphql.parser;

isolated service class WsService {
    *websocket:Service;

    private final Engine engine;
    private final readonly & __Schema schema;
    private final Context context;
    private readonly & string[] activeConnections;
    private final readonly & map<string> customHeaders;
    private boolean initiatedConnection;

    isolated function init(Engine engine, __Schema & readonly schema, map<string> & readonly customHeaders) {
        self.engine = engine;
        self.schema = schema;
        self.context = new;
        self.customHeaders = customHeaders;
        self.activeConnections = [];
        self.initiatedConnection = false;
    }

    isolated remote function onIdleTimeout(websocket:Caller caller) returns websocket:Error? {
        lock {
            if !self.initiatedConnection {
                closeConnection(caller, 4408, "Connection initialisation timeout");
            }
        }
    }

    isolated remote function onTextMessage(websocket:Caller caller, string text) returns websocket:Error? {
        error? validatedSubProtocol = validateSubProtocol(caller, self.customHeaders);
        if validatedSubProtocol is error {
            closeConnection(caller, 4406, "Subprotocol not acceptable");
            return;
        }
        json|error wsText = value:fromJsonString(text);
        if wsText is error {
            json payload = {errors: [{message: "Invalid format in WebSocket payload"}]};
            check sendWebSocketResponse(caller, self.customHeaders, WS_ERROR, payload);
            closeConnection(caller);
            return;
        }

        WSPayload|json|error wsPayload = self.customHeaders != {}
                                        ? wsText.cloneWithType(WSPayload) : value:fromJsonString(text);
        if wsPayload is error {
            json payload = {errors: [{message: "Invalid format in WebSocket payload"}]};
            check sendWebSocketResponse(caller, self.customHeaders, WS_ERROR, payload);
            closeConnection(caller);
            return;
        }
        string wsType = wsPayload is WSPayload ? <string>wsPayload.'type : DEFAULT_VALUE;
        string connectionId = wsPayload is WSPayload && wsPayload?.id !is () ? <string>wsPayload?.id : DEFAULT_VALUE;

        if wsType.equalsIgnoreCaseAscii(WS_INIT) {
            lock {
                if self.initiatedConnection {
                    closeConnection(caller, 4429, "Too many initialisation requests");
                    return;
                }
                self.initiatedConnection = true;
            }
            json wsResponse = {"type": WS_ACK};
            check caller->writeTextMessage(wsResponse.toJsonString());
        } else if wsType == WS_SUBSCRIBE || wsType == WS_START || !self.customHeaders.hasKey(WS_SUB_PROTOCOL) {
            lock {
                if self.customHeaders.hasKey(WS_SUB_PROTOCOL) {
                    if !self.initiatedConnection {
                        closeConnection(caller, 4401, "Unauthorized");
                        return;
                    }
                    if self.activeConnections.indexOf(connectionId) !is () {
                        closeConnection(caller, 4409, string `Subscriber for ${connectionId} already exists`);
                        return;
                    }
                    string[] connections = [connectionId];
                    foreach string i in self.activeConnections {
                        connections.push(i);
                    }
                    self.activeConnections = connections.cloneReadOnly();
                }
            }
            parser:OperationNode|json node = validateSubscriptionPayload(wsPayload, self.engine);
            if node is parser:OperationNode {
                check executeOperation(self.engine, self.context, self.schema, self.customHeaders, caller,
                                       connectionId, node);
            } else {
                check sendWebSocketResponse(caller, self.customHeaders, WS_ERROR, node, connectionId);
                closeConnection(caller);
            }
        } else if (wsType.equalsIgnoreCaseAscii(WS_STOP) || wsType.equalsIgnoreCaseAscii(WS_COMPLETE)) {
            lock {
                string[] connections = [];
                foreach string i in self.activeConnections {
                    connections.push(i);
                }
                int? index = array:indexOf(connections, connectionId);
                if index is int {
                    _ = connections.remove(index);
                }
                self.activeConnections = connections.cloneReadOnly();
                self.initiatedConnection = false;
            }
            check sendWebSocketResponse(caller, self.customHeaders, WS_COMPLETE, null, connectionId);
            closeConnection(caller);
        } else if wsType.equalsIgnoreCaseAscii(WS_PING) {
            json wsMessage = {"type": WS_PONG};
            check caller->writeTextMessage(wsMessage.toString());
        } else if wsType.equalsIgnoreCaseAscii(WS_PONG) {
            json wsMessage = {"type": WS_PING};
            check caller->writeTextMessage(wsMessage.toString());
        } else {
            // do nothing
        }
    }
}
