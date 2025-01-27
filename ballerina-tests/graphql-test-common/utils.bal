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
import ballerina/log;
import ballerina/test;
import ballerina/websocket;

public isolated function getJsonPayloadUsingHttpClient(string url, string document, json? variables = {}, string? operationName = (),
        http:HttpVersion httpVersion = http:HTTP_1_1) returns json|error {
    http:Client httpClient = check new (url, httpVersion = httpVersion);
    return httpClient->post("/", {query: document, operationName: operationName, variables: variables});
}

public isolated function getJsonPayloadFromService(string url, string document, json variables = (), string? operationName = (),
        map<string|string[]>? headers = ()) returns json|error {
    graphql:Client graphqlClient = check new (url);
    json|graphql:ClientError response = graphqlClient->execute(document, <map<anydata>?>variables, operationName, headers);
    if response is graphql:InvalidDocumentError {
        return response.detail().toJson();
    } else if response is graphql:PayloadBindingError {
        return response.message();
    } else if response is graphql:HttpError {
        return response.detail().body.toJson();
    } else {
        return response;
    }
}

public isolated function getTextPayloadFromService(string url, string document, json? variables = {}, string? operationName = ())
returns string|error {
    http:Client httpClient = check new (url, httpVersion = http:HTTP_1_1);
    http:Response response = check httpClient->post("/", {query: document, operationName: operationName, variables: variables});
    return response.getTextPayload();
}

public isolated function getJsonPayloadFromRequest(string url, http:Request request) returns json|error {
    http:Client httpClient = check new (url, httpVersion = http:HTTP_1_1);
    return httpClient->post("/", request);
}

public isolated function getJsonContentFromFile(string fileName) returns json|error {
    string jsonFileName = string `${fileName}.json`;
    string path = check file:joinPath("tests", "resources", "expected_results", jsonFileName);
    json content = check io:fileReadJson(path);
    return content;
}

public isolated function getGraphqlDocumentFromFile(string fileName) returns string|error {
    string gqlFileName = string `${fileName}.graphql`;
    string path = check file:joinPath("tests", "resources", "documents", gqlFileName);
    string content = check io:fileReadString(path);
    return content;
}

public isolated function assertResponseAndGetPayload(string url, string document, json? variables = {},
        string? operationName = (), int statusCode = http:STATUS_OK) returns json|error {
    http:Client httpClient = check new (url, httpVersion = http:HTTP_1_1);
    http:Response response = check httpClient->post("/", {query: document, operationName: operationName, variables: variables});
    test:assertEquals(response.statusCode, statusCode);
    return response.getJsonPayload();
}

public isolated function getTextPayloadFromBadRequest(string url, http:Request request) returns string|error {
    http:Client httpClient = check new (url, httpVersion = http:HTTP_1_1);
    http:Response response = check httpClient->post("/", request);
    assertResponseForBadRequest(response);
    return response.getTextPayload();
}

public isolated function assertResponseForBadRequest(http:Response response) {
    int statusCode = response.statusCode;
    if statusCode != http:STATUS_BAD_REQUEST && statusCode != http:STATUS_NOT_FOUND {
        test:assertFail(string `Invalid status code received: ${statusCode}`);
    }
}

public isolated function assertJsonValuesWithOrder(json actualPayload, json expectedPayload) {
    string actual = actualPayload.toJsonString();
    string expected = expectedPayload.toJsonString();
    test:assertEquals(actual, expected);
}

public isolated function getContentFromByteStream(stream<byte[], io:Error?> byteStream) returns string|error {
    record {|byte[] value;|}|io:Error? next = byteStream.iterator().next();
    byte[] content = [];
    while next is record {|byte[] value;|} {
        foreach byte b in next.value {
            content.push(b);
        }
        next = byteStream.iterator().next();
    }
    return 'string:fromBytes(content);
}

public isolated function readMessageExcludingPingMessages(websocket:Client wsClient) returns json|error {
    json message = null;
    int i = 0;
    while i < 10 {
        i = i + 1;
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
    return error("No message received");
}

public isolated function sendPongMessage(websocket:Client wsClient) returns websocket:Error? {
    json message = {'type: WS_PONG};
    check wsClient->writeMessage(message);
}

public isolated function sendSubscriptionMessage(websocket:Client wsClient, string document, string id = "1",
        json? variables = {}, string? operationName = ()) returns websocket:Error? {
    json payload = {query: document, variables: variables, operationName: operationName};
    json wsPayload = {'type: WS_SUBSCRIBE, id: id, payload: payload};
    return wsClient->writeMessage(wsPayload);
}

public isolated function validateConnectionAckMessage(websocket:Client wsClient) returns websocket:Error? {
    json response = check wsClient->readMessage();
    test:assertEquals(response.'type, WS_ACK);
}

public isolated function sendConnectionInitMessage(websocket:Client wsClient) returns websocket:Error? {
    check wsClient->writeMessage({'type: WS_INIT});
}

public isolated function initiateGraphqlWsConnection(websocket:Client wsClient) returns websocket:Error? {
    check sendConnectionInitMessage(wsClient);
    check validateConnectionAckMessage(wsClient);
}

public isolated function validateNextMessage(websocket:Client wsClient, json expectedMsgPayload, string id = "1") returns error? {
    json expectedPayload = {'type: WS_NEXT, id, payload: expectedMsgPayload};
    json actualPayload = check readMessageExcludingPingMessages(wsClient);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

public isolated function validateErrorMessage(websocket:Client wsClient, json expectedMsgPayload, string id = "1") returns error? {
    json expectedPayload = {'type: WS_ERROR, id, payload: expectedMsgPayload};
    json actualPayload = check readMessageExcludingPingMessages(wsClient);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

public isolated function validateCompleteMessage(websocket:Client wsClient, string id = "1") returns error? {
    json expectedPayload = {'type: WS_COMPLETE, id};
    json actualPayload = check readMessageExcludingPingMessages(wsClient);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

public isolated function validateConnectionClosureWithError(websocket:Client wsClient, string expectedErrorMsg) {
    json|error response = readMessageExcludingPingMessages(wsClient);
    if response is error {
        test:assertEquals(response.message(), expectedErrorMsg);
        return;
    }
    test:assertFail(string `Unexpected Error found : ${response.toString()}`);
}

public isolated function closeWebsocketClient(websocket:Client wsClient) {
    string id = wsClient.getConnectionId();
    error? result = wsClient->writeMessage({'type: WS_COMPLETE, id});
    if result is error {
        log:printError("Error occurred while sending the complete message: ", result);
    }
    result = wsClient->close(timeout = 1);
    if result is error {
        log:printError("Error occurred while closing the websocket client: ", result);
    }
}
