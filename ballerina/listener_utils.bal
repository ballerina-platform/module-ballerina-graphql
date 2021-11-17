// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/jballerina.java;

import graphql.parser;

isolated function handleGetRequests(Engine engine, Context context, http:Request request) returns http:Response {
    string? query = request.getQueryParamValue(PARAM_QUERY);
    if query is string && query != "" {
        string? operationName = request.getQueryParamValue(PARAM_OPERATION_NAME);
        json? variables = request.getQueryParamValue(PARAM_VARIABLES);
        if variables is map<json> || variables == () {
            return getResponseFromQuery(engine, query, operationName, variables, context);
        } else {
            return createResponse("Invalid format in request parameter: variables", http:STATUS_BAD_REQUEST);
        }
    } else {
        return createResponse("Query not found", http:STATUS_BAD_REQUEST);
    }
}

isolated function handlePostRequests(Engine engine, Context context, http:Request request) returns http:Response {
    string contentType = request.getContentType();
    if contentType == CONTENT_TYPE_JSON {
        return getResponseFromJsonPayload(engine, context, request);
    } else if contentType == CONTENT_TYPE_GQL {
        return createResponse("Content-Type 'application/graphql' is not yet supported", http:STATUS_BAD_REQUEST);
    } else {
        return createResponse("Invalid 'Content-type' received", http:STATUS_BAD_REQUEST);
    }
}

isolated function getResponseFromJsonPayload(Engine engine, Context context, http:Request request)
returns http:Response {
    var payload = request.getJsonPayload();
    if payload is json {
        var document = payload.query;
        var variables = payload.variables;
        variables = variables is error ? () : variables;
        if document is string && document != "" {
            if variables is map<json> || variables is () {
                return getResponseFromQuery(engine, document, getOperationName(payload), variables, context);
            } else {
                return createResponse("Invalid format in request parameter: variables", http:STATUS_BAD_REQUEST);
            }
        }
    }
    return createResponse("Invalid request body", http:STATUS_BAD_REQUEST);
}

isolated function getResponseFromQuery(Engine engine, string document, string? operationName, map<json>? variables,
    Context context) returns http:Response {
    parser:OperationNode|OutputObject validationResult = engine.validate(document, operationName, variables);
    if validationResult is parser:OperationNode {
        return getResponseFromExecution(engine, validationResult, context);
    } else {
        return createResponse(validationResult.toJson(), http:STATUS_BAD_REQUEST);
    }
}

isolated function getResponseFromExecution(Engine engine, parser:OperationNode operationNode, Context context)
returns http:Response {
    OutputObject outputObject = engine.execute(operationNode, context);
    return createResponse(outputObject.toJson());
}

isolated function createResponse(json payload, int? statusCode = ()) returns http:Response {
    http:Response response = new;
    if statusCode is int {
        response.statusCode = statusCode;
    }
    response.setPayload(payload);
    return response;
}

isolated function getOperationName(json payload) returns string? {
    var operationName = payload.operationName;
    if operationName is string {
        return operationName;
    }
    return;
}

isolated function addDefaultDirectives(__Schema schema) {
    foreach __Directive directive in defaultDirectives {
        schema.directives.push(directive);
    }
}

isolated function attachHttpServiceToGraphqlService(Service s, HttpService httpService) = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.ListenerUtils"
} external;

isolated function getHttpServiceFromGraphqlService(Service s) returns HttpService? =
@java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.ListenerUtils"
} external;
