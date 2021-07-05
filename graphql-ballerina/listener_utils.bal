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

import graphql.parser;

isolated function handleGetRequests(Engine engine, http:Request request) returns http:Response {
    string? query = request.getQueryParamValue(PARAM_QUERY);
    if query is string && query != "" {
        string? operationName = request.getQueryParamValue(PARAM_OPERATION_NAME);
        return getResponseFromQuery(engine, query, operationName);
    } else {
        return createResponse("Query not found", http:STATUS_BAD_REQUEST);
    }
}

isolated function handlePostRequests(Engine engine, http:Request request) returns http:Response {
    string contentType = request.getContentType();
    if contentType == CONTENT_TYPE_JSON {
        return getResponseFromJsonPayload(engine, request);
    } else if contentType == CONTENT_TYPE_GQL {
        return createResponse("Content-Type 'application/graphql' is not yet supported", http:STATUS_BAD_REQUEST);
    } else {
        return createResponse("Invalid 'Content-type' received", http:STATUS_BAD_REQUEST);
    }
}

isolated function getResponseFromJsonPayload(Engine engine, http:Request request) returns http:Response {
    var payload = request.getJsonPayload();
    if payload is json {
        var document = payload.query;
        if document is string && document != "" {
            return getResponseFromQuery(engine, document, getOperationName(payload));
        }
    }
    return createResponse("Invalid request body", http:STATUS_BAD_REQUEST);
}

isolated function getResponseFromQuery(Engine engine, string document, string? operationName) returns http:Response {
    parser:OperationNode|OutputObject validationResult = engine.validate(document, operationName);
    if validationResult is parser:OperationNode {
        return getResponseFromExecution(engine, validationResult);
    } else {
        return getResponseFromOutputObject(validationResult, http:STATUS_BAD_REQUEST);
    }
}

isolated function getResponseFromExecution(Engine engine, parser:OperationNode operationNode) returns http:Response {
    OutputObject outputObject = engine.execute(operationNode);
    return getResponseFromOutputObject(outputObject);
}

isolated function getResponseFromOutputObject(OutputObject outputObject, int? statusCode = ()) returns http:Response {
    json|error payload  = outputObject.cloneWithType();
    if payload is error {
        return createResponse(payload.message(), http:STATUS_INTERNAL_SERVER_ERROR);
    } else {
        return createResponse(payload, statusCode);
    }
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
}
