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

isolated function executeOperation(Engine engine, Context context, readonly & __Schema schema,
                                   readonly & map<string> customHeaders, websocket:Caller caller, string connectionId,
                                   parser:OperationNode node) returns websocket:Error? {
    RootFieldVisitor rootFieldVisitor = new (node);
    parser:FieldNode fieldNode = <parser:FieldNode>rootFieldVisitor.getRootFieldNode();
    stream<any, error?>|json sourceStream = getSubscriptionResponse(engine, schema, context, fieldNode);
    if sourceStream is stream<any, error?> {
        record {|any value;|}|error? next = sourceStream.next();
        while next !is error? {
            OutputObject outputObj = engine.getResult(node, context, next.value);
            ResponseFormatter responseFormatter = new (schema);
            OutputObject coercedOutputObject = responseFormatter.getCoercedOutputObject(outputObj, node);
            if coercedOutputObject.hasKey(DATA_FIELD) || coercedOutputObject.hasKey(ERRORS_FIELD) {
                check sendWebSocketResponse(caller, customHeaders, WS_NEXT, coercedOutputObject.toJson(), connectionId);
            }
            next = sourceStream.next();
        }
        if next is error {
            json errorPayload = {errors: {message: next.message()}};
            check sendWebSocketResponse(caller, customHeaders, WS_ERROR, errorPayload, connectionId);
            closeConnection(caller);
        } else {
            if customHeaders.hasKey(WS_SUB_PROTOCOL) {
                check sendWebSocketResponse(caller, customHeaders, WS_COMPLETE, null, connectionId);
            } else {
                closeConnection(caller);
            }
        }
    } else {
        check sendWebSocketResponse(caller, customHeaders, WS_ERROR, sourceStream, connectionId);
        closeConnection(caller);
    }
}

isolated function validateSubscriptionPayload(json|WSPayload data, Engine engine) returns parser:OperationNode|json {
    json|error payload = data is WSPayload ? data?.payload : data;
    if payload is error {
        return {errors: [{message: "Invalid format in WebSocket payload: " + payload.message()}]};
    }
    json|error document = payload.query;
    if document is error {
        return {errors: [{message: "Unable to find the query: " + document.message()}]};
    }
    if document !is string {
        return {errors: [{message: "Invalid format in request parameter: `query`"}]};
    }
    if document == "" {
        return {errors: [{message: "An empty query is found"}]};
    }
    json|error variables = payload?.variables;
    if variables is error || variables !is map<json>? {
        return {errors: [{message: "Invalid format in request parameter: `variables`"}]};
    }
    parser:OperationNode|OutputObject result = engine.validate(document, getOperationName(payload), variables);
    if result is parser:OperationNode {
        return result;
    }
    return result.toJson();
}

isolated function getSubscriptionResponse(Engine engine, __Schema schema, Context context,
                                          parser:FieldNode node) returns stream<any, error?>|json {
    ExecutorVisitor executor = new(engine, schema, context, {});
    any|error result = getSubscriptionResult(executor, node);
    if result is stream<any, error?> {
        return result;
    }
    string errorMessage = result is error ? result.message() : "Error ocurred in the subscription resolver";
    return {errors: [{message: errorMessage}]};
    
}

isolated function sendWebSocketResponse(websocket:Caller caller, map<string> & readonly customHeaders, string wsType,
                                        json payload, string? id = ()) returns websocket:Error? {
    if customHeaders.hasKey(WS_SUB_PROTOCOL) {
        string 'type = wsType;
        if customHeaders.get(WS_SUB_PROTOCOL) == GRAPHQL_WS {
            if wsType == WS_ERROR || wsType == WS_NEXT {
                'type = WS_DATA;
            }
        }
        json jsonResponse = id != () ? {'type: 'type, id: id, payload: payload} : {'type: 'type, payload: payload};
        check caller->writeMessage(jsonResponse);        
    } else {
        check caller->writeMessage(payload);
    }
}

isolated function closeConnection(websocket:Caller caller, int statusCode = 1000, string reason = "Normal Closure") {
    error? closedConnection = caller->close(statusCode, reason, timeout = 5);
    if closedConnection is error {
        // do nothing
    }
}

isolated function validateSubProtocol(websocket:Caller caller, readonly & map<string> customHeaders) returns error? {
    if customHeaders.hasKey(WS_SUB_PROTOCOL) {
        string subProtocol = customHeaders.get(WS_SUB_PROTOCOL);
        if subProtocol != GRAPHQL_WS && subProtocol != GRAPHQL_TRANSPORT_WS {
            return error("Subprotocol not acceptable");
        }
    }
    return;
}
