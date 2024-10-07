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
function testAlreadyExistingSubscriber() returns error? {
io:println("testAlreadyExistingSubscriber")
    string document = check common:getGraphqlDocumentFromFile("subscriptions_with_service_objects");
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    string clientId = wsClient.getConnectionId();
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document, clientId);
    check common:sendSubscriptionMessage(wsClient, document, clientId);
    string expectedErrorMsg = "Subscriber for " + clientId + " already exists: Status code: 4409";
    int i = 0;
    json|error response;
    while true {
        i += 1;
        response = common:readMessageExcludingPingMessages(wsClient);
        if response is error {
            break;
        }
        if i > 3 {
            test:assertFail(string `Expected: ${expectedErrorMsg}, Found: ${response.toString()}`);
        }
        json|error id = response.id;
        if id is error {
            test:assertFail(string `Expected json with id found: ${response.toString()}`);
        }
    }
    test:assertEquals((<error>response).message(), expectedErrorMsg);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testOnPing() returns error? {
io:println("testOnPing")
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check wsClient->writeMessage({'type: common:WS_PING});
    json response = check wsClient->readMessage();
    test:assertEquals(response.'type, common:WS_PONG);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testInvalidSubProtocolInSubscriptions() returns error? {
io:println("testInvalidSubProtocolInSubscriptions")
    string url = "ws://localhost:9091/subscriptions";
    string subProtocol = "graphql-invalid-ws";
    websocket:ClientConfiguration config = {subProtocols: [subProtocol]};
    websocket:Client|error wsClient = new (url, config);
    test:assertTrue(wsClient is websocket:InvalidHandshakeError, "Invalid handshake error expected");
    string expectedErrorMsg = "InvalidHandshakeError: Invalid subprotocol. Actual: null." +
    " Expected one of: graphql-invalid-ws";
    test:assertEquals((<error>wsClient).message(), expectedErrorMsg);
}

@test:Config {
    groups: ["subscriptions", "runtime_errors"]
}
isolated function testErrorsInStreams() returns error? {
io:println("testErrorsInStreams")
    string document = "subscription { evenNumber }";
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {evenNumber: 2}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = check common:getJsonContentFromFile("errors_in_streams");
    check common:validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {evenNumber: 6}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testMultipleSubscriptionUsingSingleClient() returns error? {
io:println("testMultipleSubscriptionUsingSingleClient")
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);

    check common:sendSubscriptionMessage(wsClient, document, "1");
    foreach int i in 1 ..< 6 {
        json expectedMsgPayload = {data: {messages: i}};
        check common:validateNextMessage(wsClient, expectedMsgPayload, id = "1");
    }
    check common:validateCompleteMessage(wsClient, id = "1");

    check common:sendSubscriptionMessage(wsClient, document, "2");
    foreach int i in 1 ..< 6 {
        json expectedMsgPayload = {data: {messages: i}};
        check common:validateNextMessage(wsClient, expectedMsgPayload, id = "2");
    }
    check common:validateCompleteMessage(wsClient, id = "2");
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionWithInvalidPayload() returns error? {
io:println("testSubscriptionWithInvalidPayload")
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    json invalidPayload = {'type: "start"};
    check wsClient->writeMessage(invalidPayload);

    string expectedErrorMsg = "Invalid format: payload does not conform to the format required by the" +
        " 'graphql-transport-ws' subprotocol: Status code: 1003";
    common:validateConnectionClousureWithError(wsClient, expectedErrorMsg);
}

@test:Config {
    groups: ["subscriptions", "recrods", "service"]
}
isolated function testResolverReturingStreamOfRecordsWithServiceObjects() returns error? {
io:println("testResolverReturingStreamOfRecordsWithServiceObjects")
    string document = "subscription { live { product { id } score } }";
    string url = "ws://localhost:9092/reviews";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document);

    json expectedPayload = {data: {live: {product: {id: "1"}, score: 20}}};
    check common:validateNextMessage(wsClient, expectedPayload);
}

@test:Config {
    groups: ["subscriptions", "recrods", "service", "maps"]
}
isolated function testResolverReturingStreamOfRecordsWithMapOfServiceObjects() returns error? {
io:println("testResolverReturingStreamOfRecordsWithMapOfServiceObjects")
    string document = string `subscription { accountUpdates { details(key: "acc1") { name } } }`;
    string url = "ws://localhost:9092/reviews";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {accountUpdates: {details: {name: "James"}}}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {accountUpdates: {details: {name: "James Deen"}}}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
}
