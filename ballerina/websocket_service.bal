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

import ballerina/io;
import ballerina/websocket;

import graphql.parser;

isolated service class WsService {
    *websocket:Service;

    private final Engine engine;
    private final readonly & __Schema schema;
    private final Context context;
    private map<[websocket:Caller, parser:OperationNode]> clientsMap;
    
    isolated function init(Engine engine, __Schema schema) {
        self.engine = engine;
        self.schema = schema.cloneReadOnly();
        self.context = new();
        self.clientsMap = {};
    }
                
    isolated remote function onClose(websocket:Caller caller, int statusCode, string reason) {
        lock {
            _ = self.clientsMap.remove(caller.getConnectionId());
        }
    }

    isolated remote function onTextMessage(websocket:Caller caller, string data) returns websocket:Error? {
        lock {
            parser:OperationNode|ErrorDetail node = validateSubscriptionPayload(data, self.engine);
            if node is parser:OperationNode {
                self.clientsMap[caller.getConnectionId()] = [caller, node];

                stream<any, io:Error?> sourceStream = new(); // receiving stream from "getSubscriptionResponse(...)" -> Not implemented yet
                any|io:Error? next = sourceStream.iterator().next();

                while next !is io:Error? {
                    check broadcast(self.engine, self.schema, self.context, next, self.clientsMap);
                    next = sourceStream.iterator().next();
                }
            }
            check caller->writeTextMessage((<ErrorDetail>node).message);
        }
    }
}

isolated function validateSubscriptionPayload(string text, Engine engine) returns parser:OperationNode|ErrorDetail {
    json payload = text.toJson();
    var document = payload.query;
    var variables = payload.variables;
    variables = variables is error ? () : variables;
    if document is string && document != "" {
        if variables is map<json> || variables is () {
            parser:OperationNode|OutputObject validationResult = engine.validate(document, getOperationName(payload),
                                                                                 variables);
            if validationResult is parser:OperationNode {
                return validationResult;
            }
            return {message: validationResult.toJsonString()};
        }
        return {message: "Invalid format in request parameter: variables"};
    }
    return {message: "Query not found"};
}

isolated function broadcast(Engine engine, __Schema schema, Context context, any result,
                            map<[websocket:Caller, parser:OperationNode]> clientsMap) returns websocket:Error? {
    ExecutorVisitor executor = new(engine, schema, context, {}, result);
    foreach var callerDetails in clientsMap {
        websocket:Caller caller = callerDetails[0];
        parser:OperationNode operationNode = callerDetails[1];
        OutputObject outputObject = executor.getExecutorResult(operationNode);
        if outputObject.hasKey(DATA_FIELD) || outputObject.hasKey(ERRORS_FIELD) {
            check caller->writeTextMessage(outputObject.toString());
        }
    }
}
