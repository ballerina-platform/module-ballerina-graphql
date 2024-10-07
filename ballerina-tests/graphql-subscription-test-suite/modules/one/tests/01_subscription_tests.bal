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

import ballerina/graphql_test_common as common;
import ballerina/test;
import ballerina/websocket;
import ballerina/io;

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscription() returns error? {
io:println("testSubscription");
    string document = string `subscription { name }`;
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {name: "Walter"}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {name: "Skyler"}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionWithoutSubProtocol() returns error? {
io:println("testSubscriptionWithoutSubProtocol");
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client|error wsClient = new (url);
    string expectedErrorMsg = "InvalidHandshakeError: Invalid handshake response getStatus: 400 Bad Request";
    test:assertTrue(wsClient is websocket:InvalidHandshakeError, "Invalid handshake error expected");
    test:assertEquals((<error>wsClient).message(), expectedErrorMsg);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionsWithMultipleOperations() returns error? {
io:println("testSubscriptionsWithMultipleOperations");
    string document = check common:getGraphqlDocumentFromFile("subscriptions_with_multiple_operations");
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient1);
    check common:sendSubscriptionMessage(wsClient1, document, "1", operationName = "getMessages");

    websocket:Client wsClient2 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient2);
    check common:sendSubscriptionMessage(wsClient2, document, "2", operationName = "getStringMessages");

    json expectedMsgPayload = {data: null};
    check common:validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    foreach int i in 1 ..< 4 {
        expectedMsgPayload = {data: {messages: i}};
        check common:validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        expectedMsgPayload = {data: {stringMessages: i.toString()}};
        check common:validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    }
    string httpUrl = "http://localhost:9091/subscriptions";
    json actualPayload = check common:getJsonPayloadFromService(httpUrl, document, operationName = "getName");
    json expectedPayload = {data: {name: "Walter White"}};
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["records", "subscriptions"]
}
isolated function testSubscriptionWithRecords() returns error? {
io:println("testSubscriptionWithRecords");
    string document = check common:getGraphqlDocumentFromFile("subscriptions_with_records");
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {books: {name: "Crime and Punishment", author: "Fyodor Dostoevsky"}}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {books: {name: "A Game of Thrones", author: "George R.R. Martin"}}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testQueryWithSameSubscriptionFieldName() returns error? {
io:println("testQueryWithSameSubscriptionFieldName");
    string document = string `query { name }`;
    string url = "http://localhost:9091/subscriptions";
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    json expectedPayload = {data: {name: "Walter White"}};
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "subscriptions"]
}
isolated function testSubscriptionWithFragments() returns error? {
io:println("testSubscriptionWithFragments");
    string document = check common:getGraphqlDocumentFromFile("subscriptions_with_fragments");
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {students: {id: 1, name: "Eren Yeager"}}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {students: {id: 2, name: "Mikasa Ackerman"}}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["union", "subscriptions"]
}
isolated function testSubscriptionWithUnionType() returns error? {
io:println("testSubscriptionWithUnionType");
    string document = check common:getGraphqlDocumentFromFile("subscriptions_with_union_type");
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {multipleValues: {id: 1, name: "Jesse Pinkman"}}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {multipleValues: {name: "Walter White", subject: "Chemistry"}}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["variables", "subscriptions"]
}
isolated function testSubscriptionWithVariables() returns error? {
io:println("testSubscriptionWithVariables");
    string document = check common:getGraphqlDocumentFromFile("subscriptions_with_variable_values");
    json variables = {"value": 4};
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document, variables = variables);

    foreach int i in 1 ..< 3 {
        json expectedMsgPayload = {data: {filterValues: i}};
        check common:validateNextMessage(wsClient, expectedMsgPayload);
    }
}
