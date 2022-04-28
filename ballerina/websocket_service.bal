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

    isolated function init(Engine engine, __Schema schema) {
        self.engine = engine;
        self.schema = schema.cloneReadOnly();
        self.context = new();
    }

    isolated remote function onTextMessage(websocket:Caller caller, string data) returns websocket:Error? {
        parser:OperationNode|ErrorDetail node = validateSubscriptionPayload(data, self.engine);
        if node is parser:OperationNode {
            RootFieldVisitor rootFieldVisitor = new(node);
            parser:FieldNode fieldNode = <parser:FieldNode>rootFieldVisitor.getRootFieldNode();
            stream<any, error?>|json sourceStream = getSubscriptionResponse(self.engine, self.schema,
                                                                            self.context, fieldNode);
            if sourceStream is stream<any, error?> {
                record {|any value;|}|error? next = sourceStream.iterator().next();
                while next !is error? {
                    ExecutorVisitor executor = new(self.engine, self.schema, self.context, {}, next.value);
                    OutputObject outputObject = executor.getExecutorResult(node);
                    ResponseFormatter responseFormatter = new(self.schema);
                    OutputObject coercedOutputObject = responseFormatter.getCoercedOutputObject(outputObject, node);
                    if coercedOutputObject.hasKey(DATA_FIELD) || coercedOutputObject.hasKey(ERRORS_FIELD) {
                        check caller->writeTextMessage(coercedOutputObject.toString());
                    }
                    next = sourceStream.iterator().next();
                }
            } else {
                check caller->writeTextMessage(sourceStream.toJsonString());
            }
        } else {
            check caller->writeTextMessage((<ErrorDetail>node).message);
        }
    }
}

isolated function validateSubscriptionPayload(string text, Engine engine) returns parser:OperationNode|ErrorDetail {
    json|error payload = value:fromJsonString(text);
    if payload is error {
        json errorMessage = {errors: [{message: "Invalid subscription payload"}]};
        return {message: errorMessage.toJsonString()};
    }
    json|error document = payload.query;
    if document !is string || document == "" {
        json errorMessage = {errors: [{message: "Query not found"}]};
        return {message: errorMessage.toJsonString()};
    }
    json|error variables = payload.variables is error ? () : payload.variables;
    if variables !is map<json> && variables != () {
        json errorMessage = {errors: [{message: "Invalid format in request parameter: variables"}]};
        return {message: errorMessage.toJsonString()};
    }
    parser:OperationNode|OutputObject validationResult = engine.validate(document, getOperationName(payload),
                                                                         variables);
    if validationResult is parser:OperationNode {
        return validationResult;
    }
    return {message: validationResult.toJsonString()};
}

isolated function getSubscriptionResponse(Engine engine, __Schema schema, Context context,
                                          parser:FieldNode node) returns stream<any, error?>|json {
    ExecutorVisitor executor = new(engine, schema, context, {}, null);
    any|error result = getSubscriptionResult(executor, node);
    if result !is stream<any, error?> {
        return {errors: [{message: "Invalid return value"}]};
    }
    return <stream<any, error?>>result;
}
