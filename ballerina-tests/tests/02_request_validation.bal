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
import ballerina/test;
import ballerina/url;
import ballerina/websocket;

@test:Config {
    groups: ["request_validation", "listener"]
}
isolated function testMultipleOperationsWithoutOperationNameInRequest() returns error? {
    string document = check getGraphQLDocumentFromFile("multiple_operations_without_operation_name_in_request.graphql");
    string url = "http://localhost:9091/validation";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "Must provide operation name if query contains multiple operations.",
                locations: []
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["request_validation", "listener"]
}
isolated function testMultipleOperationsWithInvalidOperationInRequest() returns error? {
    string document = check getGraphQLDocumentFromFile("multiple_operations_without_operation_name_in_request.graphql");
    string url = "http://localhost:9091/validation";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, operationName = "invalid");
    json expectedPayload = {
        errors: [
            {
                message: "Unknown operation named \"invalid\".",
                locations: []
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["request_validation", "listener"]
}
isolated function testInvalidGetRequestWithoutQuery() returns error? {
    http:Client httpClient = check new("http://localhost:9091");
    http:Response response = check httpClient->get("/validation");
    assertResponseForBadRequest(response);
    test:assertEquals(response.getTextPayload(), "Query not found");
}

@test:Config {
    groups: ["request_validation", "listener"]
}
isolated function testGetRequest() returns error? {
    string document = "{ name }";
    string encodedDocument = check url:encode(document, "UTF-8");
    json expectedPayload = {
        data: {
            name: "James Moriarty"
        }
    };
    http:Client httpClient = check new("http://localhost:9091");
    string path = "/validation?query=" + encodedDocument;
    json actualPayload = check httpClient->get(path);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["request_validation", "listener"]
}
isolated function testGetRequestWithEmptyQuery() returns error? {
    http:Client httpClient = check new("http://localhost:9091");
    string path = "/validation?query=";
    http:Response response = check httpClient->get(path);
    assertResponseForBadRequest(response);
    test:assertEquals(response.getTextPayload(), "Query not found");
}

@test:Config {
    groups: ["request_validation", "listener"]
}
isolated function testInvalidJsonPayload() returns error? {
    http:Request request = new;
    request.setJsonPayload({});
    string payload = check getTextPayloadFromBadRequest("http://localhost:9091/validation", request);
    test:assertEquals(payload, "Invalid request body");
}

@test:Config {
    groups: ["request_validation", "listener"]
}
isolated function testEmptyStringAsQuery() returns error? {
    http:Request request = new;
    request.setJsonPayload({ query: "" });
    string payload = check getTextPayloadFromBadRequest("http://localhost:9091/validation", request);
    test:assertEquals(payload, "Invalid request body");
}

@test:Config {
    groups: ["request_validation", "listener"]
}
isolated function testInvalidContentType() returns error? {
    http:Request request= new;
    request.setPayload("invalid");
    string payload = check getTextPayloadFromBadRequest("http://localhost:9091/validation", request);
    test:assertEquals(payload, "Invalid 'Content-type' received");
}

@test:Config {
    groups: ["request_validation", "listener"]
}
isolated function testContentTypeGraphql() returns error? {
    http:Request request = new;
    request.setHeader("Content-Type", "application/graphql");
    string payload = check getTextPayloadFromBadRequest("http://localhost:9091/validation", request);
    test:assertEquals(payload, "Content-Type 'application/graphql' is not yet supported");
}

@test:Config {
    groups: ["request_validation", "listener"]
}
isolated function testInvalidRequestBody() returns error? {
    http:Request request = new;
    request.setTextPayload("Invalid");
    request.setHeader("Content-Type", "application/json");
    string payload = check getTextPayloadFromBadRequest("http://localhost:9091/validation", request);
    test:assertEquals(payload, "Invalid request body");
}

@test:Config {
    groups: ["request_validation", "websocket", "subscriptions"]
}
isolated function testInvalidWebSocketRequestWithEmptyQuery() returns error? {
    string document = "";
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = {errors: [{message: "Empty query is found"}]};
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["request_validation", "websocket", "subscriptions"]
}
isolated function testInvalidWebSocketRequestWithInvalidQuery() returns error? {
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    json payload = {query: 2};
    check wsClient->writeMessage(payload);
    json expectedPayload = {errors: [{message: "Invalid format in request parameter: query"}]};
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["request_validation", "websocket", "subscriptions"]
}
isolated function testInvalidWebSocketRequestWithoutQuery() returns error? {
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    check wsClient->writeMessage({id: "1", payload: {query: ()}});
    string expectedErrorMessage = "Unable to find the query: {ballerina/lang.map}KeyNotFound";
    json expectedPayload = {errors: [{message: expectedErrorMessage}]};
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["request_validation", "websocket", "subscriptions"]
}
isolated function testInvalidVariableInWebSocketPayload() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_variable_values.graphql");
    json variables = [];
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient, variables);
    json expectedPayload = {errors: [{message: "Invalid format in request parameter: variables"}]};
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["request_validation", "websocket", "subscriptions"]
}
isolated function testEmptyWebSocketPayload() returns error? {
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    string payload = "";
    check wsClient->writeMessage(payload);
    string expectedErrorMessage = "Invalid format in WebSocket payload: {ballerina/lang.value}FromJsonStringError";
    json expectedPayload = {errors: [{message: expectedErrorMessage}]};
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["request_validation", "websocket", "subscriptions", "sub_protocols"]
}
isolated function testInvalidWebSocketPayload() returns error? {
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new (url, {subProtocols: ["graphql-ws"]});
    json payload = {payload: {query: ()}};
    check wsClient->writeMessage(payload);
    string expectedErrorMessage = "Invalid format in WebSocket payload: {ballerina/lang.value}ConversionError";
    json expectedPayload = {'type: "data", payload: {errors: [{message: expectedErrorMessage}]}};
    check validateWebSocketResponse(wsClient, expectedPayload);
}
