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
import ballerina/java;
import ballerina/reflect;

isolated function getHttpListenerConfigs(ListenerConfiguration configs) returns http:ListenerConfiguration {
    http:ListenerConfiguration httpConfigs = {
        host: configs.host
    };
    return httpConfigs;
}

isolated function handleGetRequests(Engine? engine, http:Request request) returns http:Response {
    http:Response response = new;
    var query = request.getQueryParamValue(PARAM_QUERY);
    if (query is ()) {
        setResponseForBadRequest(response);
    } else {
        string operationName = resolveOperationName(request.getQueryParamValue(PARAM_OPERATION_NAME));
        json payload = <@untainted>getOutputObjectForQuery(engine, query, operationName);
        response.setPayload(payload);
    }
    return response;
}

isolated function handlePostRequests(Engine? engine, http:Request request) returns http:Response {
    http:Response response = new;
    string contentType = request.getContentType();
    if (contentType == CONTENT_TYPE_JSON) {
        processRequestWithJsonPayload(engine, request, response);
    } else if (contentType == CONTENT_TYPE_GQL) {
        var document = request.getTextPayload();
        json payload = getErrorJson("Content-Type 'application/graphql' is not yet supported");
        response.setPayload(payload);
    } else {
        json payload = getErrorJson("Invalid 'Content-type' received");
        response.setPayload(payload);
    }
    return response;
}

isolated function processRequestWithJsonPayload(Engine? engine, http:Request request, http:Response response) {
    var payload = request.getJsonPayload();
    if (payload is json) {
        return processJsonPayload(engine, <@untainted>payload, response);
    } else {
        string message = "Error occurred while retriving the payload from the request.";
        response.setJsonPayload(getErrorJson(message));
    }
}

isolated function processJsonPayload(Engine? engine, json payload, http:Response response) {
    var documentString = payload.query;
    string operationName = ANONYMOUS_OPERATION;
    var operationNameInPayload = payload.operationName;
    if (operationNameInPayload is string?) {
        operationName = resolveOperationName(operationNameInPayload);
    }
    if (documentString is string) {
        json outputObject = getOutputObjectForQuery(engine, documentString, operationName);
        response.setJsonPayload(outputObject);
    } else {
        setResponseForBadRequest(response);
    }
}

isolated function setResponseForBadRequest(http:Response response) {
    response.statusCode = 400;
    string message = "Bad request";
    response.setPayload(message);
}

isolated function getOutputObjectForQuery(Engine? engine, string documentString, string operationName) returns json {
    json? outputObject = ();
    if (engine is Engine) {
        Document|Error document = engine.parse(documentString);
        if (document is Error) {
            outputObject = getResultJsonForError(document);
        } else {
            var validationResult = engine.validate(document);
            if (validationResult is Error) {
                outputObject = getResultJsonForError(validationResult);
            } else {
                outputObject = engine.execute(document, operationName);
            }
        }
    }
    return outputObject;
}

isolated function resolveOperationName(string? operationName) returns string {
    if (operationName is string) {
        return operationName;
    } else {
        return ANONYMOUS_OPERATION;
    }
}

isolated function attach(Listener 'listener, service s, string? name) returns error? = @java:Method
{
    'class: "io.ballerina.stdlib.graphql.service.ServiceHandler"
} external;

isolated function detach(Listener 'listener, service s) returns error? = @java:Method
{
    'class: "io.ballerina.stdlib.graphql.service.ServiceHandler"
} external;

isolated function getServiceAnnotations(service s) returns GraphQlServiceConfiguration? {
    any annData = reflect:getServiceAnnotations(s, "ServiceConfiguration", "ballerina/graphql:0.1.0");
    if (!(annData is ())) {
        return <GraphQlServiceConfiguration> annData;
    }
}
