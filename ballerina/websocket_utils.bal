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

import ballerina/log;
import ballerina/websocket;

class ResultGenerator {
    private Engine engine;
    private stream<any, error?> sourceStream;
    private SubscriptionHandler handler;
    private parser:OperationNode node;
    private Context context;
    private boolean isCompleted = false;

    isolated function init(Engine engine, stream<any, error?> sourceStream, SubscriptionHandler handler, parser:OperationNode node,
            Context context) {
        self.engine = engine;
        self.sourceStream = sourceStream;
        self.handler = handler;
        self.node = node;
        self.context = context;
    }

    public isolated function next() returns record {|Next|Complete|ErrorMessage value;|}|error? {
            if self.isCompleted {
                return;
            }
            if self.handler.getUnsubscribed() {
                closeStream(self.sourceStream);
                return;
            }
            record {|any value;|}|error? nextValue = self.sourceStream.next();
            if nextValue !is () {
                any|error resultValue = nextValue is error ? nextValue : nextValue.value;
                OutputObject outputObject = self.engine.getResult(self.node, self.context, resultValue);
                self.context.clearDataLoadersCachesAndPlaceholders();
                self.context.resetErrors(); //Remove previous event's errors before the next one
                if outputObject.hasKey(DATA_FIELD) || outputObject.hasKey(ERRORS_FIELD) {
                    Next response = {'type: 'WS_NEXT, id: self.handler.getId(), payload: outputObject.toJson()};
                    return {value: response};
                }
            }
            self.isCompleted = true;
            Complete response = {'type: WS_COMPLETE, id: self.handler.getId()};
            return {value: response};
    }
}

isolated function getResultStream(Engine engine, Context context, readonly & __Schema schema,
        parser:OperationNode|json node, SubscriptionHandler handler)
returns stream<Next|Complete|ErrorMessage, error?> {
    stream<any, error?>|json sourceStream;
    if node is json {
        return getErrorMessageStream(handler, node);
    }
    sourceStream = getSourceStream(engine, context, schema, node);
    if sourceStream is json {
        return getErrorMessageStream(handler, sourceStream);
    }
    ResultGenerator resultGenerator = new (engine, sourceStream, handler, node, context);
    stream<Next|Complete|ErrorMessage, error?> result = new (resultGenerator);
    return result;
}

isolated function getSourceStream(Engine engine, Context context, readonly & __Schema schema, parser:OperationNode node) returns stream<any, error?>|json {
    RootFieldVisitor rootFieldVisitor = new (node);
    parser:FieldNode fieldNode = <parser:FieldNode>rootFieldVisitor.getRootFieldNode();
    Field 'field = getFieldObject(fieldNode, parser:OPERATION_SUBSCRIPTION, schema, engine);
    return getSubscriptionResponse(engine, schema, context, 'field, node);
}

isolated function getErrorMessageStream(SubscriptionHandler handler, json errors) returns stream<ErrorMessage, error?> {
    if !handler.getUnsubscribed() {
        ErrorMessage errorMessage = {'type: WS_ERROR, id: handler.getId(), payload: errors};
        return [errorMessage].toStream();
    }
    return [].toStream();
}

isolated function validateSubscriptionPayload(Subscribe data, Engine engine) returns parser:OperationNode|json {
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
        Field 'field, parser:OperationNode operationNode)
returns stream<any, error?>|json {
    ResponseGenerator responseGenerator = new (engine, context, 'field.getFieldType(), 'field.getPath().clone());
    any|error result = engine.executeSubscriptionResource(context, engine.getService(), 'field, responseGenerator, engine.getValidation());
    if result is stream<any, error?> {
        return result;
    }
    if result !is error {
        if context.getErrors().length() == 0 {
            result = error("Error occurred in the subscription resolver");
        }
        result = ();
    }
    OutputObject outputObject = engine.getResult(operationNode, context, result);
    return outputObject.errors.toJson();
}

isolated function closeConnection(websocket:Caller caller, SubscriptionError cause, decimal timeout = 5) {
    string reason = cause.message();
    int statusCode = cause.detail().code;
    error? closedConnection = caller->close(statusCode, reason, timeout);
    if closedConnection is error {
        logError("Failed to close WebSocket connection: " + closedConnection.message(), closedConnection);
    }
}

isolated function closeStream(stream<any, error?> sourceStream) {
    error? result = sourceStream.close();
    if result is error {
        logError("Failed to close stream", result);
    }
}

isolated function logError(string message, error cause) {
    error err = error(message, cause);
    log:printError(err.message(), stackTrace = err.stackTrace());
}

isolated function writeMessage(websocket:Caller caller, OutboundMessage message) returns websocket:Error? {
    if !caller.isOpen() {
        return;
    }
    check caller->writeMessage(message);
}
