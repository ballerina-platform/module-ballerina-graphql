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
import ballerina/graphql;
import ballerina/http;
import ballerina/io;
import ballerina/test;
import ballerina/websocket;

const CONTENT_TYPE_TEXT_HTML = "text/html";
const CONTENT_TYPE_TEXT_PLAIN = "text/plain";

isolated function getJsonPayloadUsingHttpClient(string url, string document, json? variables = {}, string? operationName = (),
                                            http:HttpVersion httpVersion = http:HTTP_1_1) returns json|error {
    http:Client httpClient = check new(url, httpVersion = httpVersion);
    return httpClient->post("/", { query: document, operationName: operationName, variables: variables});
}

isolated function getJsonPayloadFromService(string url, string document, json variables = (), string? operationName = (),
                                            map<string|string[]>? headers = ()) returns json|error {
    graphql:Client graphqlClient = check new (url);
    json|graphql:ClientError response = graphqlClient->execute(document, <map<anydata>?>variables, operationName, headers);
    if response is graphql:InvalidDocumentError || response is graphql:PayloadBindingError {
        return response.detail().toJson();
    } else {
        return response;
    }
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

isolated function readMessageExcludingPingMessages(websocket:Client wsClient) returns json|websocket:Error {
    json message = null;
    while true {
        message = check wsClient->readMessage();
        if message == null {
            continue;
        } 
        if message.'type == WS_PING {
            check sendPongMessage(wsClient);
            continue;
        }
        return message;
    }
}

isolated function sendPongMessage(websocket:Client wsClient) returns websocket:Error? {
    json message = {'type: WS_PONG};
    check wsClient->writeMessage(message);
}

isolated function sendSubscriptionMessage(websocket:Client wsClient, string document, string id = "1",
                                          json? variables = {}, string? operationName = ()) returns websocket:Error? {
    json payload = {query: document, variables: variables, operationName: operationName};
    json wsPayload = {'type: WS_SUBSCRIBE, id: id, payload: payload};
    return wsClient->writeMessage(wsPayload);
}

isolated function validateConnectionAckMessage(websocket:Client wsClient) returns websocket:Error? {
    json response = check wsClient->readMessage();
    test:assertEquals(response.'type, WS_ACK);
}

isolated function sendConnectionInitMessage(websocket:Client wsClient) returns websocket:Error? {
    check wsClient->writeMessage({'type: WS_INIT});
}

isolated function initiateGraphqlWsConnection(websocket:Client wsClient) returns websocket:Error? {
    check sendConnectionInitMessage(wsClient);
    check validateConnectionAckMessage(wsClient);
}

isolated function validateNextMessage(websocket:Client wsClient, json expectedMsgPayload, string id = "1") returns websocket:Error? {
    json expectedPayload = {'type: WS_NEXT, id, payload: expectedMsgPayload};
    json actualPayload = check readMessageExcludingPingMessages(wsClient);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

isolated function validateErrorMessage(websocket:Client wsClient, json expectedMsgPayload, string id = "1") returns websocket:Error? {
    json expectedPayload = {'type: WS_ERROR, id, payload: expectedMsgPayload};
    json actualPayload = check readMessageExcludingPingMessages(wsClient);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

isolated function validateCompleteMessage(websocket:Client wsClient, string id = "1") returns websocket:Error? {
    json expectedPayload = {'type: WS_COMPLETE, id};
    json actualPayload = check readMessageExcludingPingMessages(wsClient);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

isolated function validateConnectionClousureWithError(websocket:Client wsClient, string expectedErrorMsg) {
    json|error response = readMessageExcludingPingMessages(wsClient);
    test:assertTrue(response is error);
    test:assertEquals((<error>response).message(), expectedErrorMsg);
}
