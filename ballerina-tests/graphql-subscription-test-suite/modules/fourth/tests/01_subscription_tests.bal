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
    io:println("start testAlreadyExistingSubscriber");
    string document = check common:getGraphqlDocumentFromFile("subscriptions_with_service_objects");
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
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
    io:println("end testAlreadyExistingSubscriber");

}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testOnPing() returns error? {
    io:println("start testOnPing");

    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check wsClient->writeMessage({'type: common:WS_PING});
    json response = check wsClient->readMessage();
    test:assertEquals(response.'type, common:WS_PONG);
    io:println("end testOnPing");

}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testInvalidSubProtocolInSubscriptions() returns error? {
    io:println("start testInvalidSubProtocolInSubscriptions");

    string url = "ws://localhost:9091/subscriptions";
    string subProtocol = "graphql-invalid-ws";
    websocket:ClientConfiguration config = {subProtocols: [subProtocol]};
    websocket:Client|error wsClient = new (url, config);
    test:assertTrue(wsClient is websocket:InvalidHandshakeError, "Invalid handshake error expected");
    string expectedErrorMsg = "InvalidHandshakeError: Invalid subprotocol. Actual: null." +
    " Expected one of: graphql-invalid-ws";
    test:assertEquals((<error>wsClient).message(), expectedErrorMsg);
    io:println("end testInvalidSubProtocolInSubscriptions");
}    

@test:Config {
    groups: ["subscriptions", "runtime_errors"]
}
isolated function testErrorsInStreams() returns error? {
    io:println("start testErrorsInStreams");
    
    string document = "subscription { evenNumber }";
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {evenNumber: 2}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = check common:getJsonContentFromFile("errors_in_streams");
    check common:validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {evenNumber: 6}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
    io:println("end testErrorsInStreams");
    
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testMultipleSubscriptionUsingSingleClient() returns error? {
    io:println("start testMultipleSubscriptionUsingSingleClient");

    string document = string `subscription { messages }`;
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
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
    io:println("end testMultipleSubscriptionUsingSingleClient");

}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionWithInvalidPayload() returns error? {
    io:println("start testSubscriptionWithInvalidPayload");

    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    json invalidPayload = {'type: "start"};
    check wsClient->writeMessage(invalidPayload);

    string expectedErrorMsg = "Invalid format: payload does not conform to the format required by the" +
        " 'graphql-transport-ws' subprotocol: Status code: 1003";
    common:validateConnectionClousureWithError(wsClient, expectedErrorMsg);
    io:println("end testSubscriptionWithInvalidPayload");

}

@test:Config {
    groups: ["subscriptions", "recrods", "service"]
}
isolated function testResolverReturingStreamOfRecordsWithServiceObjects() returns error? {
    io:println("start testResolverReturingStreamOfRecordsWithServiceObjects");

    string document = "subscription { live { product { id } score } }";
    string url = "ws://localhost:9091/reviews";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document);

    json expectedPayload = {data: {live: {product: {id: "1"}, score: 20}}};
    check common:validateNextMessage(wsClient, expectedPayload);
    io:println("end testResolverReturingStreamOfRecordsWithServiceObjects");

}

@test:Config {
    groups: ["subscriptions", "recrods", "service", "maps"]
}
isolated function testResolverReturingStreamOfRecordsWithMapOfServiceObjects() returns error? {
    io:println("start testResolverReturingStreamOfRecordsWithMapOfServiceObjects");

    string document = string `subscription { accountUpdates { details(key: "acc1") { name } } }`;
    string url = "ws://localhost:9091/reviews";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {accountUpdates: {details: {name: "James"}}}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {accountUpdates: {details: {name: "James Deen"}}}};
    check common:validateNextMessage(wsClient, expectedMsgPayload);
    io:println("end testResolverReturingStreamOfRecordsWithMapOfServiceObjects");

}

// @test:Config {
//     groups: ["subscriptions", "multiplexing"]
// }
// isolated function testSubscriptionMultiplexing() returns error? {
//     io:println("start testSubscriptionMultiplexing");

//     string document = string `subscription { refresh }`;
//     string url = "ws://localhost:9091/subscriptions";
//     websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
//     websocket:Client wsClient = check new (url, config);
//     check common:initiateGraphqlWsConnection(wsClient);
//     check common:sendSubscriptionMessage(wsClient, document, "1");
//     check common:sendSubscriptionMessage(wsClient, document, "2");

//     boolean subscriptionOneDisabled = false;
//     map<int> subscriptions = {"1": 0, "2": 0};
//     while true {
//         json actualPayload = check common:readMessageExcludingPingMessages(wsClient);
//         string subscriptionId = check actualPayload.id;
//         subscriptions[subscriptionId] = subscriptions.get(subscriptionId) + 1;
//         if subscriptionOneDisabled && subscriptionId == "1" {
//             test:assertFail("Subscription one already unsubscirbed. No further data should be sent by ther server.");
//         }
//         if subscriptionId == "1" && subscriptions.get(subscriptionId) == 3 {
//             subscriptionOneDisabled = true;
//             check wsClient->writeMessage({'type: common:WS_COMPLETE, id: subscriptionId});
//         }
//         if subscriptionId == "2" && subscriptions.get(subscriptionId) == 10 {
//             check wsClient->writeMessage({'type: common:WS_COMPLETE, id: subscriptionId});
//             break;
//         }
//         json payload = {data: {refresh: "data"}};
//         json expectedPayload = {'type: common:WS_NEXT, id: subscriptionId, payload: payload};
//         test:assertEquals(actualPayload, expectedPayload);
//     }
//     io:println("end testSubscriptionMultiplexing");

// }

// @test:Config {
//     groups: ["subscriptions", "recrods", "service"]
// }
// isolated function testConnectionClousureWhenPongNotRecived() returns error? {
//     io:println("start testConnectionClousureWhenPongNotRecived");

//     string url = "ws://localhost:9091/reviews";
//     websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
//     websocket:Client wsClient = check new (url, config);
//     check common:initiateGraphqlWsConnection(wsClient);
//     json|error response;
//     while true {
//         response = wsClient->readMessage();
//         if response is json {
//             test:assertTrue(response.'type == common:WS_PING);
//             continue;
//         }
//         break;
//     }
//     test:assertTrue(response is error, "Expected connection clousure error");
//     test:assertEquals((<error>response).message(), "Request timeout: Status code: 4408");
//     io:println("end testConnectionClousureWhenPongNotRecived");

// }

// @test:Config {
//     groups: ["request_validation", "websocket", "subscriptions"]
// }
// isolated function testInvalidWebSocketRequestWithEmptyQuery() returns error? {
//     io:println("start testInvalidWebSocketRequestWithEmptyQuery");

//     string document = "";
//     string url = "ws://localhost:9091/subscriptions";
//     websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
//     websocket:Client wsClient = check new (url, config);
//     check common:initiateGraphqlWsConnection(wsClient);
//     check common:sendSubscriptionMessage(wsClient, document);
//     json expectedMsgPayload = {errors: [{message: "An empty query is found"}]};
//     check common:validateErrorMessage(wsClient, expectedMsgPayload);
//     io:println("end testInvalidWebSocketRequestWithEmptyQuery");

// }

// @test:Config {
//     groups: ["request_validation", "websocket", "subscriptions"]
// }
// isolated function testInvalidWebSocketRequestWithInvalidQuery() returns error? {
//     io:println("start testInvalidWebSocketRequestWithInvalidQuery");

//     string url = "ws://localhost:9091/subscriptions";
//     websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
//     websocket:Client wsClient = check new (url, config);
//     check common:initiateGraphqlWsConnection(wsClient);
//     json payload = {query: 2};
//     check wsClient->writeMessage({"type": common:WS_SUBSCRIBE, id: "1", payload: payload});
//     string expectedErrorMsg = "Invalid format: payload does not conform to the format required by the" +
//         " 'graphql-transport-ws' subprotocol: Status code: 1003";
//     common:validateConnectionClousureWithError(wsClient, expectedErrorMsg);
//     io:println("end testInvalidWebSocketRequestWithInvalidQuery");

// }

// @test:Config {
//     groups: ["request_validation", "websocket", "subscriptions"]
// }
// isolated function testInvalidWebSocketRequestWithoutQuery() returns error? {
//     io:println("start testInvalidWebSocketRequestWithoutQuery");

//     string url = "ws://localhost:9091/subscriptions";
//     websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
//     websocket:Client wsClient = check new (url, config);
//     check common:initiateGraphqlWsConnection(wsClient);
//     check wsClient->writeMessage({"type": common:WS_SUBSCRIBE, id: "1", payload: {}});
//     string expectedErrorMsg = "Invalid format: payload does not conform to the format required by the" +
//         " 'graphql-transport-ws' subprotocol: Status code: 1003";
//     common:validateConnectionClousureWithError(wsClient, expectedErrorMsg);
//     io:println("end testInvalidWebSocketRequestWithoutQuery");

// }

// @test:Config {
//     groups: ["request_validation", "websocket", "subscriptions"]
// }
// isolated function testInvalidVariableInWebSocketPayload() returns error? {
//     io:println("start testInvalidVariableInWebSocketPayload");

//     string document = check common:getGraphqlDocumentFromFile("subscriptions_with_variable_values");
//     json variables = [];
//     string url = "ws://localhost:9091/subscriptions";
//     websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
//     websocket:Client wsClient = check new (url, config);
//     check common:initiateGraphqlWsConnection(wsClient);
//     check common:sendSubscriptionMessage(wsClient, document, variables = variables);
//     string expectedErrorMsg = "Invalid format: payload does not conform to the format required by the" +
//         " 'graphql-transport-ws' subprotocol: Status code: 1003";
//     common:validateConnectionClousureWithError(wsClient, expectedErrorMsg);
//     io:println("end testInvalidVariableInWebSocketPayload");

// }

// @test:Config {
//     groups: ["request_validation", "websocket", "subscriptions"]
// }
// isolated function testEmptyWebSocketPayload() returns error? {
//     io:println("start testEmptyWebSocketPayload");

//     string url = "ws://localhost:9091/subscriptions";
//     websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
//     websocket:Client wsClient = check new (url, config);
//     string payload = "";
//     check wsClient->writeMessage(payload);
//     string expectedErrorMsg = "Invalid format: payload does not conform to the format required by the" +
//         " 'graphql-transport-ws' subprotocol: Status code: 1003";
//     common:validateConnectionClousureWithError(wsClient, expectedErrorMsg);
//     io:println("end testEmptyWebSocketPayload");

// }

// @test:Config {
//     groups: ["request_validation", "websocket", "subscriptions"]
// }
// isolated function testInvalidWebSocketPayload() returns error? {
//     io:println("start testInvalidWebSocketPayload");

//     string url = "ws://localhost:9091/subscriptions";
//     websocket:Client wsClient = check new (url, {subProtocols: [GRAPHQL_TRANSPORT_WS]});
//     json payload = {payload: {query: ()}};
//     check wsClient->writeMessage(payload);
//     string expectedErrorMsg = "Invalid format: payload does not conform to the format required by the"
//         + " 'graphql-transport-ws' subprotocol: Status code: 1003";
//     common:validateConnectionClousureWithError(wsClient, expectedErrorMsg);

//     io:println("end testInvalidWebSocketPayload");

// }

