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

@test:Config {
    groups: ["subscriptions", "multiplexing"]
}
isolated function testSubscriptionMultiplexing() returns error? {
    string document = string `subscription { refresh }`;
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document, "1");
    check common:sendSubscriptionMessage(wsClient, document, "2");

    boolean subscriptionOneDisabled = false;
    map<int> subscriptions = {"1": 0, "2": 0};
    while true {
        json actualPayload = check common:readMessageExcludingPingMessages(wsClient);
        string subscriptionId = check actualPayload.id;
        subscriptions[subscriptionId] = subscriptions.get(subscriptionId) + 1;
        if subscriptionOneDisabled && subscriptionId == "1" {
            test:assertFail("Subscription one already unsubscirbed. No further data should be sent by ther server.");
        }
        if subscriptionId == "1" && subscriptions.get(subscriptionId) == 3 {
            subscriptionOneDisabled = true;
            check wsClient->writeMessage({'type: common:WS_COMPLETE, id: subscriptionId});
        }
        if subscriptionId == "2" && subscriptions.get(subscriptionId) == 10 {
            check wsClient->writeMessage({'type: common:WS_COMPLETE, id: subscriptionId});
            break;
        }
        json payload = {data: {refresh: "data"}};
        json expectedPayload = {'type: common:WS_NEXT, id: subscriptionId, payload: payload};
        test:assertEquals(actualPayload, expectedPayload);
    }
}

@test:Config {
    groups: ["request_validation", "websocket", "subscriptions"]
}
isolated function testInvalidWebSocketRequestWithEmptyQuery() returns error? {
    string document = "";
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document);
    json expectedMsgPayload = {errors: [{message: "An empty query is found"}]};
    check common:validateErrorMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["request_validation", "websocket", "subscriptions"]
}
isolated function testInvalidWebSocketRequestWithInvalidQuery() returns error? {
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    json payload = {query: 2};
    check wsClient->writeMessage({"type": common:WS_SUBSCRIBE, id: "1", payload: payload});
    string expectedErrorMsg = "Invalid format: payload does not conform to the format required by the" +
        " 'graphql-transport-ws' subprotocol: Status code: 1003";
    common:validateConnectionClosureWithError(wsClient, expectedErrorMsg);
}

@test:Config {
    groups: ["request_validation", "websocket", "subscriptions"]
}
isolated function testInvalidWebSocketRequestWithoutQuery() returns error? {
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check wsClient->writeMessage({"type": common:WS_SUBSCRIBE, id: "1", payload: {}});
    string expectedErrorMsg = "Invalid format: payload does not conform to the format required by the" +
        " 'graphql-transport-ws' subprotocol: Status code: 1003";
    common:validateConnectionClosureWithError(wsClient, expectedErrorMsg);
}

@test:Config {
    groups: ["request_validation", "websocket", "subscriptions"]
}
isolated function testInvalidVariableInWebSocketPayload() returns error? {
    string document = check common:getGraphqlDocumentFromFile("subscriptions_with_variable_values");
    json variables = [];
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document, variables = variables);
    string expectedErrorMsg = "Invalid format: payload does not conform to the format required by the" +
        " 'graphql-transport-ws' subprotocol: Status code: 1003";
    common:validateConnectionClosureWithError(wsClient, expectedErrorMsg);
}

@test:Config {
    groups: ["request_validation", "websocket", "subscriptions"]
}
isolated function testEmptyWebSocketPayload() returns error? {
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    string payload = "";
    check wsClient->writeMessage(payload);
    string expectedErrorMsg = "Invalid format: payload does not conform to the format required by the" +
        " 'graphql-transport-ws' subprotocol: Status code: 1003";
    common:validateConnectionClosureWithError(wsClient, expectedErrorMsg);
}

@test:Config {
    groups: ["request_validation", "websocket", "subscriptions"]
}
isolated function testInvalidWebSocketPayload() returns error? {
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient = check new (url, {subProtocols: [common:GRAPHQL_TRANSPORT_WS]});
    json payload = {payload: {query: ()}};
    check wsClient->writeMessage(payload);
    string expectedErrorMsg = "Invalid format: payload does not conform to the format required by the"
        + " 'graphql-transport-ws' subprotocol: Status code: 1003";
    common:validateConnectionClosureWithError(wsClient, expectedErrorMsg);
}
