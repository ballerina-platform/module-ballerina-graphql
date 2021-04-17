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
    http:Response response = new;
    var query = request.getQueryParamValue(PARAM_QUERY);
    if (query is ()) {
        // TODO: Use default bad request response when it is implemented
        setResponseForBadRequest(response);
    } else {
        string operationName = resolveOperationName(request.getQueryParamValue(PARAM_OPERATION_NAME));
        OutputObject outputObject = engine.getOutputObjectForQuery(query, operationName);
        response.setJsonPayload(<json> checkpanic outputObject.cloneWithType(json));
    }
    return response;
}

isolated function handlePostRequests(Engine engine, http:Request request) returns http:Response {
    http:Response response = new;
    string contentType = request.getContentType();
    if (contentType == CONTENT_TYPE_JSON) {
        processRequestWithJsonPayload(engine, request, response);
    } else if (contentType == CONTENT_TYPE_GQL) {
        json payload = getErrorJson("Content-Type 'application/graphql' is not yet supported");
        response.setPayload(payload);
    } else {
        json payload = getErrorJson("Invalid 'Content-type' received");
        response.setPayload(payload);
    }
    return response;
}

isolated function processRequestWithJsonPayload(Engine engine, http:Request request, http:Response response) {
    var payload = request.getJsonPayload();
    if (payload is json) {
        return processJsonPayload(engine, payload, response);
    } else {
        string message = "Error occurred while retriving the payload from the request.";
        response.setJsonPayload(getErrorJson(message));
    }
}

isolated function processJsonPayload(Engine engine, json payload, http:Response response) {
    var documentString = payload.query;
    string operationName = parser:ANONYMOUS_OPERATION;
    var operationNameInPayload = payload.operationName;
    if (operationNameInPayload is string?) {
        operationName = resolveOperationName(operationNameInPayload);
    }
    if (documentString is string) {
        OutputObject outputObject = engine.getOutputObjectForQuery(documentString, operationName);
        response.setJsonPayload(checkpanic outputObject.cloneWithType(json));
    } else {
        setResponseForBadRequest(response);
    }
}

isolated function setResponseForBadRequest(http:Response response) {
    response.statusCode = 400;
    string message = "Bad request";
    response.setPayload(message);
}

isolated function getErrorJson(string message) returns json {
    return {
        errors: [
            {
                massage: message
            }
        ]
    };
}

isolated function resolveOperationName(string? operationName) returns string {
    if (operationName is string) {
        return operationName;
    } else {
        return parser:ANONYMOUS_OPERATION;
    }
}
