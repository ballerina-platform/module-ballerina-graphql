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

import ballerina/test;
import ballerina/websocket;

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscription() returns error? {
    string document = string `subscription { name }`;
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {name: "Walter"}};
    check validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {name: "Skyler"}};
    check validateNextMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionWithoutSubProtocol() returns error? {
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client|error wsClient = new (url);
    string expectedErrorMsg = "InvalidHandshakeError: Invalid handshake response getStatus: 400 Bad Request";
    test:assertTrue(wsClient is websocket:InvalidHandshakeError, "Invalid handshake error expected");
    test:assertEquals((<error>wsClient).message(), expectedErrorMsg);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionsWithMultipleOperations() returns error? {
    string document = check getGraphqlDocumentFromFile("subscriptions_with_multiple_operations");
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient1);
    check sendSubscriptionMessage(wsClient1, document, "1", operationName = "getMessages");

    websocket:Client wsClient2 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient2);
    check sendSubscriptionMessage(wsClient2, document, "2", operationName = "getStringMessages");

    json expectedMsgPayload = {data: null};
    check validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    foreach int i in 1 ..< 4 {
        expectedMsgPayload = {data: {messages: i}};
        check validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        expectedMsgPayload = {data: {stringMessages: i.toString()}};
        check validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    }
    string httpUrl = "http://localhost:9099/subscriptions";
    json actualPayload = check getJsonPayloadFromService(httpUrl, document, operationName = "getName");
    json expectedPayload = {data: {name: "Walter White"}};
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["records", "subscriptions"]
}
isolated function testSubscriptionWithRecords() returns error? {
    string document = check getGraphqlDocumentFromFile("subscriptions_with_records");
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {books: {name: "Crime and Punishment", author: "Fyodor Dostoevsky"}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {books: {name: "A Game of Thrones", author: "George R.R. Martin"}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testQueryWithSameSubscriptionFieldName() returns error? {
    string document = string `query { name }`;
    string url = "http://localhost:9099/subscriptions";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {data: {name: "Walter White"}};
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "subscriptions"]
}
isolated function testSubscriptionWithFragments() returns error? {
    string document = check getGraphqlDocumentFromFile("subscriptions_with_fragments");
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {students: {id: 1, name: "Eren Yeager"}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {students: {id: 2, name: "Mikasa Ackerman"}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["union", "subscriptions"]
}
isolated function testSubscriptionWithUnionType() returns error? {
    string document = check getGraphqlDocumentFromFile("subscriptions_with_union_type");
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {multipleValues: {id: 1, name: "Jesse Pinkman"}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {multipleValues: {name: "Walter White", subject: "Chemistry"}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["variables", "subscriptions"]
}
isolated function testSubscriptionWithVariables() returns error? {
    string document = check getGraphqlDocumentFromFile("subscriptions_with_variable_values");
    json variables = {"value": 4};
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document, variables = variables);

    foreach int i in 1 ..< 3 {
        json expectedMsgPayload = {data: {filterValues: i}};
        check validateNextMessage(wsClient, expectedMsgPayload);
    }
}

@test:Config {
    groups: ["introspection", "typename", "subscriptions"]
}
isolated function testSubscriptionWithIntrospectionInFields() returns error? {
    string document = string `subscription { students { __typename } }`;
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {students: {__typename: "StudentService"}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testInvalidSubscription() returns error? {
    string document = string `subscription { invalidField }`;
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = check getJsonContentFromFile("subscription_invalid_field");
    check validateErrorMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionFunctionWithErrors() returns error? {
    string document = string `subscription getNames { values }`;
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {errors: [{message: "{ballerina/lang.array}IndexOutOfRange"}]};
    check validateErrorMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["service", "subscriptions"]
}
isolated function testSubscriptionWithServiceObjects() returns error? {
    string document = check getGraphqlDocumentFromFile("subscriptions_with_service_objects");
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {students: {id: 1, name: "Eren Yeager"}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {students: {id: 2, name: "Mikasa Ackerman"}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
    check validateCompleteMessage(wsClient);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionWithMultipleClients() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};

    websocket:Client wsClient1 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient1);
    check sendSubscriptionMessage(wsClient1, document, "1");

    websocket:Client wsClient2 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient2);
    check sendSubscriptionMessage(wsClient2, document, "2");

    foreach int i in 1 ..< 6 {
        json expectedMsgPayload = {data: {messages: i}};
        check validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        check validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    }
    check validateCompleteMessage(wsClient1, id = "1");
    check validateCompleteMessage(wsClient2, id = "2");
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testConnectionInitMessage() returns error? {
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check sendConnectionInitMessage(wsClient);
    check validateConnectionAckMessage(wsClient);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testInvalidMultipleConnectionInitMessages() returns error? {
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendConnectionInitMessage(wsClient);

    string expectedErrorMsg = "Too many initialisation requests: Status code: 4429";
    validateConnectionClousureWithError(wsClient, expectedErrorMsg);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testUnauthorizedAccess() returns error? {
    string document = check getGraphqlDocumentFromFile("subscriptions_with_service_objects");
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check sendSubscriptionMessage(wsClient, document);

    string expectedErrorMsg = "Unauthorized: Status code: 4401";
    validateConnectionClousureWithError(wsClient, expectedErrorMsg);
}

@test:Config {
    groups: ["subscriptions"]
}
function testAlreadyExistingSubscriber() returns error? {
    string document = check getGraphqlDocumentFromFile("subscriptions_with_service_objects");
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    string clientId = wsClient.getConnectionId();
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document, clientId);
    check sendSubscriptionMessage(wsClient, document, clientId);
    string expectedErrorMsg = "Subscriber for " + clientId + " already exists: Status code: 4409";
    int i = 0;
    json|error response;
    while true {
        i += 1;
        response = readMessageExcludingPingMessages(wsClient);
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
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check wsClient->writeMessage({'type: WS_PING});
    json response = check wsClient->readMessage();
    test:assertEquals(response.'type, WS_PONG);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testInvalidSubProtocolInSubscriptions() returns error? {
    string url = "ws://localhost:9099/subscriptions";
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
    string document = "subscription { evenNumber }";
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {evenNumber: 2}};
    check validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = check getJsonContentFromFile("errors_in_streams");
    check validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {evenNumber: 6}};
    check validateNextMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testMultipleSubscriptionUsingSingleClient() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);

    check sendSubscriptionMessage(wsClient, document, "1");
    foreach int i in 1 ..< 6 {
        json expectedMsgPayload = {data: {messages: i}};
        check validateNextMessage(wsClient, expectedMsgPayload, id = "1");
    }
    check validateCompleteMessage(wsClient, id = "1");

    check sendSubscriptionMessage(wsClient, document, "2");
    foreach int i in 1 ..< 6 {
        json expectedMsgPayload = {data: {messages: i}};
        check validateNextMessage(wsClient, expectedMsgPayload, id = "2");
    }
    check validateCompleteMessage(wsClient, id = "2");
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionWithInvalidPayload() returns error? {
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    json invalidPayload = {'type: "start"};
    check wsClient->writeMessage(invalidPayload);

    string expectedErrorMsg = "Invalid format: payload does not conform to the format required by the" +
        " 'graphql-transport-ws' subprotocol: Status code: 1003";
    validateConnectionClousureWithError(wsClient, expectedErrorMsg);
}

@test:Config {
    groups: ["subscriptions", "recrods", "service"]
}
isolated function testResolverReturingStreamOfRecordsWithServiceObjects() returns error? {
    string document = "subscription { live { product { id } score } }";
    string url = "ws://localhost:9090/reviews";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document);

    json expectedPayload = {data: {live: {product: {id: "1"}, score: 20}}};
    check validateNextMessage(wsClient, expectedPayload);
}

@test:Config {
    groups: ["subscriptions", "recrods", "service", "maps"]
}
isolated function testResolverReturingStreamOfRecordsWithMapOfServiceObjects() returns error? {
    string document = string `subscription { accountUpdates { details(key: "acc1") { name } } }`;
    string url = "ws://localhost:9090/reviews";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document);

    json expectedMsgPayload = {data: {accountUpdates: {details: {name: "James"}}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {accountUpdates: {details: {name: "James Deen"}}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["subscriptions", "multiplexing"]
}
isolated function testSubscriptionMultiplexing() returns error? {
    string document = string `subscription { refresh }`;
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document, "1");
    check sendSubscriptionMessage(wsClient, document, "2");

    boolean subscriptionOneDisabled = false;
    map<int> subscriptions = {"1": 0, "2": 0};
    while true {
        json actualPayload = check readMessageExcludingPingMessages(wsClient);
        string subscriptionId = check actualPayload.id;
        subscriptions[subscriptionId] = subscriptions.get(subscriptionId) + 1;
        if subscriptionOneDisabled && subscriptionId == "1" {
            test:assertFail("Subscription one already unsubscirbed. No further data should be sent by ther server.");
        }
        if subscriptionId == "1" && subscriptions.get(subscriptionId) == 3 {
            subscriptionOneDisabled = true;
            check wsClient->writeMessage({'type: WS_COMPLETE, id: subscriptionId});
        }
        if subscriptionId == "2" && subscriptions.get(subscriptionId) == 10 {
            check wsClient->writeMessage({'type: WS_COMPLETE, id: subscriptionId});
            break;
        }
        json payload = {data: {refresh: "data"}};
        json expectedPayload = {'type: WS_NEXT, id: subscriptionId, payload: payload};
        test:assertEquals(actualPayload, expectedPayload);
    }
}

@test:Config {
    groups: ["subscriptions", "recrods", "service"]
}
isolated function testConnectionClousureWhenPongNotRecived() returns error? {
    string url = "ws://localhost:9090/reviews";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    json|error response;
    while true {
        response = wsClient->readMessage();
        if response is json {
            test:assertTrue(response.'type == WS_PING);
            continue;
        }
        break;
    }
    test:assertTrue(response is error, "Expected connection clousure error");
    test:assertEquals((<error>response).message(), "Request timeout: Status code: 4408");
}
