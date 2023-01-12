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

import ballerina/log;
import ballerina/websocket;
import graphql.parser;

isolated function executeOperation(Engine engine, Context context, readonly & __Schema schema, websocket:Caller caller,
                                   parser:OperationNode node, SubscriptionHandler subscriptionHandler) {
    stream<any, error?>|json sourceStream;
    do {
        SubscriptionHandler handler = subscriptionHandler;
        RootFieldVisitor rootFieldVisitor = new (node);
        parser:FieldNode fieldNode = <parser:FieldNode>rootFieldVisitor.getRootFieldNode();
        sourceStream = getSubscriptionResponse(engine, schema, context, fieldNode);
        if sourceStream is stream<any, error?> {
            record {|any value;|}|error? next = sourceStream.next();
            while next !is () {
                if handler.getUnsubscribed() {
                    closeStream(sourceStream);
                    return;
                }
                any|error resultValue = next is error ? next : next.value;
                OutputObject outputObject = engine.getResult(node, context, resultValue);
                if outputObject.hasKey(DATA_FIELD) || outputObject.hasKey(ERRORS_FIELD) {
                    NextMessage response = {'type: 'WS_NEXT, id: handler.getId(), payload: outputObject.toJson()};
                    check caller->writeMessage(response);
                }
                context.resetErrors(); //Remove previous event's errors before the next one
                next = sourceStream.next();
            }
            check handleStreamCompletion(caller, handler, sourceStream);
        } else {
            check handleStreamCreationError(caller, handler, sourceStream);
        }
    } on fail error err {
        log:printError(err.message(), stackTrace = err.stackTrace());
        if sourceStream is stream<any, error?> {
            closeStream(sourceStream);
        }
    }
}

isolated function handleStreamCompletion(websocket:Caller caller, SubscriptionHandler handler,
                                         stream<any, error?> sourceStream) returns websocket:Error? {
    if handler.getUnsubscribed() {
        closeStream(sourceStream);
        return;
    }
    CompleteMessage response = {'type: WS_COMPLETE, id: handler.getId()};
    check caller->writeMessage(response);
    closeStream(sourceStream);
}

isolated function handleStreamCreationError(websocket:Caller caller, SubscriptionHandler handler, json errors) 
returns websocket:Error? {
    if handler.getUnsubscribed() {
        return;
    }
    ErrorMessage response = {'type: WS_ERROR, id: handler.getId(), payload: errors};
    check caller->writeMessage(response);
}

isolated function validateSubscriptionPayload(SubscribeMessage data, Engine engine) returns parser:OperationNode|json {
    string document = data.payload.query.trim();
    if document == "" {
        return {errors: [{message: "An empty query is found"}]};
    }
    string? operationName = data.payload?.operationName;
    map<json>? variables = data.payload?.variables;
    parser:OperationNode|OutputObject result = engine.validate(document, operationName, variables);
    if result is parser:OperationNode {
        return result;
    }
    return result.toJson();
}

isolated function getSubscriptionResponse(Engine engine, __Schema schema, Context context,
                                          parser:FieldNode node) returns stream<any, error?>|json {
    any|error result = engine.executeSubscriptionResource(context, engine.getService(), node);
    if result is stream<any, error?> {
        return result;
    }
    string errorMessage = result is error ? result.message() : "Error ocurred in the subscription resolver";
    return {errors: [{message: errorMessage}]};
}

isolated function closeConnection(websocket:Caller caller, SubscriptionError cause) {
    string reason = cause.message();
    int statusCode = cause.detail().code;
    error? closedConnection = caller->close(statusCode, reason, timeout = 5);
    if closedConnection is error {
        error err = error("Failed to close WebSocket connection", closedConnection);
        log:printError(err.message(), stackTrace = err.stackTrace());
    }
}

isolated function validateSubProtocol(websocket:Caller caller, readonly & map<string> customHeaders)
returns SubscriptionError? {
    string subProtocol = customHeaders.get(WS_SUB_PROTOCOL).trim();
    if subProtocol != GRAPHQL_TRANSPORT_WS {
        return error(string `Unsupported subprotocol "${subProtocol}" requested by the client`, code = 4406);
    }
}

isolated function closeStream(stream<any, error?> sourceStream) {
    error? result = sourceStream.close();
    if result is error {
        error err = error("Failed to close stream", result);
        log:printError(err.message(), stackTrace = err.stackTrace());
    }
}
