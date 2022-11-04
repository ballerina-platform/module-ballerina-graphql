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

import ballerina/file;
import ballerina/http;
import ballerina/io;
import ballerina/test;
import ballerina/websocket;

const CONTENT_TYPE_TEXT_HTML = "text/html";
const CONTENT_TYPE_TEXT_PLAIN = "text/plain";

isolated function getJsonPayloadFromService(string url, string document, json? variables = {}, string? operationName = (),
                                            http:HttpVersion httpVersion = http:HTTP_1_1) returns json|error {
    http:Client httpClient = check new(url, httpVersion = httpVersion);
    return httpClient->post("/", { query: document, operationName: operationName, variables: variables});
}

isolated function getTextPayloadFromService(string url, string document, json? variables = {}, string? operationName = ())
returns string|error {
    http:Client httpClient = check new(url, httpVersion = http:HTTP_1_1);
    http:Response response = check httpClient->post("/", { query: document, operationName: operationName, variables: variables});
    return response.getTextPayload();
}

isolated function getJsonPayloadFromRequest(string url, http:Request request) returns json|error {
    http:Client httpClient = check new(url, httpVersion = http:HTTP_1_1);
    return httpClient->post("/", request);
}

isolated function getJsonContentFromFile(string fileName) returns json|error {
    string path = check file:joinPath("tests", "resources", "expected_results", fileName);
    return io:fileReadJson(path);
}

isolated function getGraphQLDocumentFromFile(string fileName) returns string|error {
    string path = check file:joinPath("tests", "resources", "documents", fileName);
    return io:fileReadString(path);
}

isolated function getJsonPayloadFromBadRequest(string url, string document, json? variables = {}, string? operationName = ())
returns json|error {
    http:Client httpClient = check new(url, httpVersion = http:HTTP_1_1);
    http:Response response = check httpClient->post("/", { query: document, operationName: operationName, variables: variables});
    assertResponseForBadRequest(response);
    return response.getJsonPayload();
}

isolated function getTextPayloadFromBadService(string url, string document, json? variables = {}, string? operationName = ())
returns string|error {
    http:Client httpClient = check new(url, httpVersion = http:HTTP_1_1);
    http:Response response = check httpClient->post("/", { query: document, operationName: operationName, variables: variables});
    assertResponseForBadRequest(response);
    return response.getTextPayload();
}

isolated function assertResponseAndGetPayload(string url, string document, json? variables = {},
string? operationName = (), int statusCode = http:STATUS_OK) returns json|error {
    http:Client httpClient = check new(url, httpVersion = http:HTTP_1_1);
    http:Response response = check httpClient->post("/", { query: document, operationName: operationName, variables: variables});
    test:assertEquals(response.statusCode, statusCode);
    return response.getJsonPayload();
}

isolated function getTextPayloadFromBadRequest(string url, http:Request request) returns string|error {
    http:Client httpClient = check new(url, httpVersion = http:HTTP_1_1);
    http:Response response = check httpClient->post("/", request);
    assertResponseForBadRequest(response);
    return response.getTextPayload();
}

isolated function assertResponseForBadRequest(http:Response response) {
    int statusCode = response.statusCode;
    if statusCode != http:STATUS_BAD_REQUEST && statusCode != http:STATUS_NOT_FOUND {
        test:assertFail(string`Invalid status code received: ${statusCode}`);
    }
}

isolated function assertJsonValuesWithOrder(json actualPayload, json expectedPayload) {
    string actual = actualPayload.toJsonString();
    string expected = expectedPayload.toJsonString();
    test:assertEquals(actual, expected);
}

isolated function getContentFromByteStream(stream<byte[], io:Error?> byteStream) returns string|error {
    record {| byte[] value; |}|io:Error? next = byteStream.iterator().next();
    byte[] content = [];
    while next is record {| byte[] value; |} {
        foreach byte b in next.value {
            content.push(b);
        }
        next = byteStream.iterator().next();
    }
    return 'string:fromBytes(content);
}

isolated function validateWebSocketResponse(websocket:Client wsClient, json expectedPayload)
    returns websocket:Error?|error {
    json actualPayload = check wsClient->readMessage();
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

isolated function writeWebSocketTextMessage(string? document, websocket:Client wsClient, json? variables = {},
                                            string? operationName = (), string? id = (), string? subProtocol = ())
                                            returns websocket:Error? {
    json payload = {query: document, variables: variables, operationName: operationName};
    if subProtocol !is () && id !is () {
        json wsPayload = subProtocol == GRAPHQL_WS
                        ? {"type": WS_START, id: id, payload: payload}
                        : {"type": WS_SUBSCRIBE, id: id, payload: payload};
        check wsClient->writeMessage(wsPayload);
    } else {
        check wsClient->writeMessage(payload);
    }
}

isolated function validateConnectionInitMessage(websocket:Client wsClient) returns websocket:Error?|error {
    string expectedPayload = WS_ACK;
    json jsonPayload = check wsClient->readMessage();
    WSPayload wsPayload = check jsonPayload.cloneWithType(WSPayload);
    string actualType = wsPayload.'type;
    test:assertEquals(actualType, expectedPayload);
}

isolated function initiateConnectionInitMessage(websocket:Client wsClient) returns websocket:Error? {
    check wsClient->writeMessage({"type": WS_INIT});
}
