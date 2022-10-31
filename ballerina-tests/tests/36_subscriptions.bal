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
    websocket:Client wsClient = check new(url);
    json payload = {query: document};
    check wsClient->writeMessage(payload);
    json expectedPayload = {data: {name: "Walter"}};
    check validateWebSocketResponse(wsClient, expectedPayload);
    expectedPayload = {data: {name: "Skyler"}};
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionWithMultipleClients() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient1 = check new(url);
    websocket:Client wsClient2 = check new(url);
    check writeWebSocketTextMessage(document, wsClient1);
    check writeWebSocketTextMessage(document, wsClient2);
    foreach int i in 1 ..< 4 {
        json expectedPayload = {data: {messages: i}};
        check validateWebSocketResponse(wsClient1, expectedPayload);
        check validateWebSocketResponse(wsClient2, expectedPayload);
    }
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionsWithMultipleOperations() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_multiple_operations.graphql");
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient1 = check new(url);
    websocket:Client wsClient2 = check new(url);
    check writeWebSocketTextMessage(document, wsClient1, {}, "getMessages");
    check writeWebSocketTextMessage(document, wsClient2, {}, "getStringMessages");
    json expectedPayload = {data: null};
    check validateWebSocketResponse(wsClient2, expectedPayload);
    foreach int i in 1 ..< 4 {
        expectedPayload = {data: {messages: i}};
        check validateWebSocketResponse(wsClient1, expectedPayload);
        expectedPayload = {data: {stringMessages: i.toString()}};
        check validateWebSocketResponse(wsClient2, expectedPayload);
    }
    string httpUrl = "http://localhost:9099/subscriptions";
    json actualPayload = check getJsonPayloadFromService(httpUrl, document, operationName = "getName");
    expectedPayload = {data: {name: "Walter White"}};
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["service", "subscriptions"]
}
isolated function testSubscriptionWithServiceObjects() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_service_objects.graphql");
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = {data: {students: {id: 1, name: "Eren Yeager"}}};
    check validateWebSocketResponse(wsClient, expectedPayload);
    expectedPayload = {data: {students: {id: 2, name: "Mikasa Ackerman"}}};
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["records", "subscriptions"]
}
isolated function testSubscriptionWithRecords() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_records.graphql");
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = {data: {books: {name: "Crime and Punishment", author: "Fyodor Dostoevsky"}}};
    check validateWebSocketResponse(wsClient, expectedPayload);
    expectedPayload = {data: {books: {name: "A Game of Thrones", author: "George R.R. Martin"}}};
    check validateWebSocketResponse(wsClient, expectedPayload);
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
    string document = check getGraphQLDocumentFromFile("subscriptions_with_fragments.graphql");
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = {data: {students: {id: 1, name: "Eren Yeager"}}};
    check validateWebSocketResponse(wsClient, expectedPayload);
    expectedPayload = {data: {students: {id: 2, name: "Mikasa Ackerman"}}};
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["union", "subscriptions"]
}
isolated function testSubscriptionWithUnionType() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_union_type.graphql");
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = {
        data: {
            multipleValues: {
                id: 1,
                name: "Jesse Pinkman"
            }
        }
    };
    check validateWebSocketResponse(wsClient, expectedPayload);
    expectedPayload = {
        data: {
            multipleValues: {
                name: "Walter White",
                subject: "Chemistry"
            }
        }
    };
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["variables", "subscriptions"]
}
isolated function testSubscriptionWithVariables() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_variable_values.graphql");
    json variables = {"value": 4};
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient, variables);
    foreach int i in 1 ..< 3 {
        json expectedPayload = {data: {filterValues: i}};
        check validateWebSocketResponse(wsClient, expectedPayload);
    }
}

@test:Config {
    groups: ["introspection", "typename", "subscriptions"]
}
isolated function testSubscriptionWithIntrospectionInFields() returns error? {
    string document = string `subscription { students { __typename } }`;
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = {data: {students: {__typename: "StudentService"}}};
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testInvalidSubscription() returns error? {
    string document = string `subscription { invalidField }`;
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = check getJsonContentFromFile("subscription_invalid_field.json");
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testInvalidSubscriptionWithMultipleRootFields() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_multiple_root_fields.graphql");
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = check getJsonContentFromFile("subscription_invalid_multiple_root_fields.json");
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["introspection", "typename", "subscriptions"]
}
isolated function testInvalidSubscriptionWithIntrospections() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_introspections.graphql");
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = check getJsonContentFromFile("subscription_invalid_introspections.json");
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["introspection", "typename", "subscriptions"]
}
isolated function testInvalidAnonymousSubscriptionOperationWithIntrospections() returns error? {
    string document = string `subscription { __typename }`;
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = check getJsonContentFromFile("subscription_anonymous_with_invalid_introspections.json");
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["fragments", "subscriptions"]
}
isolated function testInvalidSubscriptionWithMultipleRootFieldsInFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_multiple_root_fields_in_fragments.graphql");
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = check getJsonContentFromFile("subscription_invalid_multiple_root_fields_in_fragments.json");
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionFunctionWithErrors() returns error? {
    string document = string `subscription getNames { values }`;
    string url = "ws://localhost:9099/subscriptions";
    websocket:Client websocketClient = check new(url);
    check writeWebSocketTextMessage(document, websocketClient);
    string errorMessage = "{ballerina/lang.array}IndexOutOfRange";
    json expectedPayload = {errors: [{message: errorMessage}]};
    check validateWebSocketResponse(websocketClient, expectedPayload);
}

@test:Config {
    groups: ["sub_protocols", "service", "subscriptions"]
}
isolated function testSubscriptionWithServiceObjectsUsingSubProtocol() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_service_objects.graphql");
    string url = "ws://localhost:9099/subscriptions";
    string[] subProtocols = ["graphql-ws", "graphql-transport-ws"];
    foreach string subProtocol in subProtocols {
        websocket:ClientConfiguration config = {subProtocols: [subProtocol]};
        websocket:Client wsClient = check new(url, config);
        string messageType = subProtocol == GRAPHQL_WS ? WS_DATA : WS_NEXT;
        check initiateConnectionInitMessage(wsClient);
        check validateConnectionInitMessage(wsClient);

        check writeWebSocketTextMessage(document, wsClient, id = "1", subProtocol = subProtocol);
        json payload = {data: {students: {id: 1, name: "Eren Yeager"}}};
        json expectedPayload = {"type": messageType, id: "1", payload: payload};
        check validateWebSocketResponse(wsClient, expectedPayload);
        payload = {data: {students: {id: 2, name: "Mikasa Ackerman"}}};
        expectedPayload = {"type": messageType, id: "1", payload: payload};
        check validateWebSocketResponse(wsClient, expectedPayload);
        expectedPayload = {"type": WS_COMPLETE, id: "1", payload: null};
        check validateWebSocketResponse(wsClient, expectedPayload);
    }
}

@test:Config {
    groups: ["sub_protocols", "variables", "subscriptions"]
}
isolated function testSubscriptionWithVariablesUsingSubProtocol() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_variable_values.graphql");
    json variables = {"value": 4};
    string url = "ws://localhost:9099/subscriptions";
    string[] subProtocols = ["graphql-ws", "graphql-transport-ws"];
    foreach string subProtocol in subProtocols {
        websocket:ClientConfiguration config = {subProtocols: [subProtocol]};
        websocket:Client wsClient = check new(url, config);
        string messageType = subProtocol == GRAPHQL_WS ? WS_DATA : WS_NEXT;

        check initiateConnectionInitMessage(wsClient);
        check validateConnectionInitMessage(wsClient);

        check writeWebSocketTextMessage(document, wsClient, variables, id = "1", subProtocol = subProtocol);
        foreach int i in 1 ..< 4 {
            json expectedPayload = {"type": messageType, id: "1", payload: {data: {filterValues: i}}};
            check validateWebSocketResponse(wsClient, expectedPayload);
        }
    }
}

@test:Config {
    groups: ["sub_protocols", "subscriptions"]
}
isolated function testSubscriptionWithMultipleClientsUsingSubProtocol() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9099/subscriptions";
    string[] subProtocols = ["graphql-ws", "graphql-transport-ws"];
    foreach string subProtocol in subProtocols {
        websocket:ClientConfiguration config = {subProtocols: [subProtocol]};
        websocket:Client wsClient1 = check new(url, config);
        websocket:Client wsClient2 = check new(url, config);
        string messageType = subProtocol == GRAPHQL_WS ? WS_DATA : WS_NEXT;

        check initiateConnectionInitMessage(wsClient1);
        check validateConnectionInitMessage(wsClient1);

        check initiateConnectionInitMessage(wsClient2);
        check validateConnectionInitMessage(wsClient2);

        check writeWebSocketTextMessage(document, wsClient1, id = "1", subProtocol = subProtocol);
        check writeWebSocketTextMessage(document, wsClient2, id = "2", subProtocol = subProtocol);

        foreach int i in 1 ..< 6 {
            json expectedPayload = {"type": messageType, id: "1", payload: {data: {messages: i}}};
            check validateWebSocketResponse(wsClient1, expectedPayload);
            expectedPayload = {"type": messageType, id: "2", payload: {data: {messages: i}}};
            check validateWebSocketResponse(wsClient2, expectedPayload);
        }

        check wsClient1->writeMessage({id: "1", "type": WS_STOP});
        check wsClient2->writeMessage({id: "2", "type": WS_STOP});
        json expectedPayload = {"type": WS_COMPLETE, id: "1", payload: null};
        check validateWebSocketResponse(wsClient1, expectedPayload);
        expectedPayload = {"type": WS_COMPLETE, id: "2", payload: null};
        check validateWebSocketResponse(wsClient2, expectedPayload);
    }
}

@test:Config {
    groups: ["sub_protocols", "subscriptions"]
}
isolated function testSubscriptionsWithMultipleOperationsUsingSubProtocol() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_multiple_operations.graphql");
    string url = "ws://localhost:9099/subscriptions";
    string[] subProtocols = ["graphql-ws", "graphql-transport-ws"];
    foreach string subProtocol in subProtocols {
        websocket:ClientConfiguration config = {subProtocols: [subProtocol]};
        websocket:Client wsClient1 = check new(url, config);
        websocket:Client wsClient2 = check new(url, config);
        string messageType = subProtocol == GRAPHQL_WS ? WS_DATA : WS_NEXT;

        check initiateConnectionInitMessage(wsClient1);
        check validateConnectionInitMessage(wsClient1);

        check initiateConnectionInitMessage(wsClient2);
        check validateConnectionInitMessage(wsClient2);

        check writeWebSocketTextMessage(document, wsClient1, {}, "getMessages", "1", subProtocol = subProtocol);
        check writeWebSocketTextMessage(document, wsClient2, {}, "getStringMessages", "2", subProtocol = subProtocol);
        json expectedPayload = {"type": messageType, id: "2", payload: {data: null}};
        check validateWebSocketResponse(wsClient2, expectedPayload);
        foreach int i in 1 ..< 4 {
            json payload = {data: {messages: i}};
            expectedPayload = {"type": messageType, id: "1", payload: payload};
            check validateWebSocketResponse(wsClient1, expectedPayload);
            payload = {data: {stringMessages: i.toString()}};
            expectedPayload = {"type": messageType, id: "2", payload: payload};
            check validateWebSocketResponse(wsClient2, expectedPayload);
        }

        string httpUrl = "http://localhost:9099/subscriptions";
        json actualPayload = check getJsonPayloadFromService(httpUrl, document, operationName = "getName");
        expectedPayload = {data: {name: "Walter White"}};
        assertJsonValuesWithOrder(actualPayload, expectedPayload);
    }
}

@test:Config {
    groups: ["sub_protocols", "fragments", "subscriptions"]
}
isolated function testSubscriptionWithFragmentsUsingSubProtocol() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_fragments.graphql");
    string url = "ws://localhost:9099/subscriptions";
    string[] subProtocols = ["graphql-ws", "graphql-transport-ws"];
    foreach string subProtocol in subProtocols {
        websocket:ClientConfiguration config = {subProtocols: [subProtocol]};
        websocket:Client wsClient = check new(url, config);
        string messageType = subProtocol == GRAPHQL_WS ? WS_DATA : WS_NEXT;

        check initiateConnectionInitMessage(wsClient);
        check validateConnectionInitMessage(wsClient);

        check writeWebSocketTextMessage(document, wsClient, id = "1", subProtocol = subProtocol);
        json payload = {data: {students: {id: 1, name: "Eren Yeager"}}};
        json expectedPayload = {"type": messageType, id: "1", payload: payload};
        check validateWebSocketResponse(wsClient, expectedPayload);
        payload = {data: {students: {id: 2, name: "Mikasa Ackerman"}}};
        expectedPayload = {"type": messageType, id: "1", payload: payload};
        check validateWebSocketResponse(wsClient, expectedPayload);
    }
}

@test:Config {
    groups: ["sub_protocols", "subscriptions"]
}
isolated function testInvalidSubscriptionUsingSubProtocol() returns error? {
    string document = string `subscription { invalidField }`;
    string url = "ws://localhost:9099/subscriptions";
    string[] subProtocols = ["graphql-ws", "graphql-transport-ws"];
    foreach string subProtocol in subProtocols {
        websocket:ClientConfiguration config = {subProtocols: [subProtocol]};
        websocket:Client wsClient = check new(url, config);
        string messageType = subProtocol == GRAPHQL_WS ? WS_DATA : WS_ERROR;
        json responsePayload = check getJsonContentFromFile("subscription_invalid_field.json");
        check initiateConnectionInitMessage(wsClient);
        check validateConnectionInitMessage(wsClient);

        json payload = {query: document};
        check wsClient->writeMessage({"type": WS_START, id: "1", payload: payload});
        json expectedPayload = {'type: messageType, id: "1", payload: responsePayload};
        check validateWebSocketResponse(wsClient, expectedPayload);
    }
}

@test:Config {
    groups: ["sub_protocols", "subscriptions"]
}
isolated function testSubscriptionFunctionWithErrorsUsingSubProtocol() returns error? {
    string document = string `subscription getNames { values }`;
    string url = "ws://localhost:9099/subscriptions";
    string[] subProtocols = ["graphql-ws", "graphql-transport-ws"];
    foreach string subProtocol in subProtocols {
        websocket:ClientConfiguration config = {subProtocols: [subProtocol]};
        websocket:Client wsClient = check new(url, config);
        string messageType = subProtocol == GRAPHQL_WS ? WS_DATA : WS_ERROR;

        check initiateConnectionInitMessage(wsClient);
        check validateConnectionInitMessage(wsClient);

        check writeWebSocketTextMessage(document, wsClient, id = "1", subProtocol = subProtocol);
        string errorMessage = "{ballerina/lang.array}IndexOutOfRange";
        json payload = {errors: [{message: errorMessage}]};
        json expectedPayload = {"type": messageType, id: "1", payload: payload};
        check validateWebSocketResponse(wsClient, expectedPayload);
    }
}

@test:Config {
    groups: ["sub_protocols", "subscriptions"]
}
isolated function testConnectionInitMessage() returns error? {
    string url = "ws://localhost:9099/subscriptions";
    string[] subProtocols = ["graphql-ws", "graphql-transport-ws"];
    foreach string subProtocol in subProtocols {
        websocket:ClientConfiguration config = {subProtocols: [subProtocol]};
        websocket:Client wsClient = check new(url, config);
        check initiateConnectionInitMessage(wsClient);
        check validateConnectionInitMessage(wsClient);
    }
}

@test:Config {
    groups: ["sub_protocols", "subscriptions"]
}
isolated function testInvalidMultipleConnectionInitMessages() returns error? {
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: ["graphql-ws"]};
    websocket:Client wsClient = check new(url, config);
    string expectedPayload = WS_ACK;

    check wsClient->writeMessage({"type": WS_INIT, id: "1"});

    json response = check wsClient->readMessage();
    WSPayload wsPayload = check response.cloneWithType(WSPayload);
    string actualType = wsPayload.'type;
    test:assertEquals(actualType, expectedPayload);

    check wsClient->writeMessage({"type": WS_INIT, id: "1"});
    json|websocket:Error message = wsClient->readMessage();
    test:assertTrue(message is websocket:Error);
    string errorMsg = "Too many initialisation requests: Status code: 4429";
    if message is websocket:Error {
        test:assertEquals((<error>message).message(), errorMsg);
    }
}

@test:Config {
    groups: ["sub_protocols", "subscriptions"]
}
isolated function testUnauthorizedAccessUsingSubProtocol() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_service_objects.graphql");
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: ["graphql-ws"]};
    websocket:Client wsClient = check new(url, config);
    check wsClient->writeMessage({"type": WS_START, id: "1", payload: {query: document}});
    json|websocket:Error response = wsClient->readMessage();
    string errorMsg = "Unauthorized: Status code: 4401";
    test:assertTrue(response is websocket:Error);
    if response is websocket:Error {
        test:assertEquals((<error>response).message(), errorMsg);
    }
}

@test:Config {
    groups: ["sub_protocols", "subscriptions"]
}
function testAlreadyExistingSubscriberUsingSubProtocol() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_service_objects.graphql");
    string url = "ws://localhost:9099/subscriptions";
    string subProtocol = "graphql-ws";
    websocket:ClientConfiguration config = {subProtocols: [subProtocol]};
    websocket:Client wsClient = check new(url, config);
    string clientId = wsClient.getConnectionId();

    check initiateConnectionInitMessage(wsClient);
    check validateConnectionInitMessage(wsClient);

    check writeWebSocketTextMessage(document, wsClient, id = clientId, subProtocol = subProtocol);
    check writeWebSocketTextMessage(document, wsClient, id = clientId, subProtocol = subProtocol);
    json|websocket:Error message = wsClient->readMessage();
    while message !is websocket:Error {
        message = wsClient->readMessage();
    }
    string errorMsg = "Subscriber for " + clientId + " already exists: Status code: 4409";
    test:assertTrue(message is websocket:Error);
    if message is websocket:Error {
        test:assertEquals((<error>message).message(), errorMsg);
    }
}

@test:Config {
    groups: ["sub_protocols", "subscriptions"]
}
isolated function testOnPing() returns error? {
    string url = "ws://localhost:9099/subscriptions";
    string[] subProtocols = ["graphql-ws", "graphql-transport-ws"];
    foreach string subProtocol in subProtocols {
        websocket:ClientConfiguration config = {subProtocols: [subProtocol]};
        websocket:Client wsClient = check new(url, config);
        check wsClient->writeMessage({"type": WS_PING});
        string expectedPayload = WS_PONG;
        json response = check wsClient->readMessage();
        WSPayload wsPayload = check response.cloneWithType(WSPayload);
        string actualType = wsPayload.'type;
        test:assertEquals(actualType, expectedPayload);
    }
}

@test:Config {
    groups: ["sub_protocols", "subscriptions"]
}
isolated function testInvalidSubProtocolInSubscriptions() returns error? {
    string url = "ws://localhost:9099/subscriptions";
    string subProtocol = "graphql-invalid-ws";
    websocket:ClientConfiguration config = {subProtocols: [subProtocol]};
    websocket:Client wsClient = check new(url, config);
    check initiateConnectionInitMessage(wsClient);
    json|websocket:Error message = wsClient->readMessage();
    string errorMsg = "Subprotocol not acceptable: Status code: 4406";
    test:assertTrue(message is websocket:Error);
    if message is websocket:Error {
        test:assertEquals((<error>message).message(), errorMsg);
    }
}

 @test:Config {
     groups: ["subscriptions", "runtime_errors"]
 }
 isolated function testErrorsInStreams() returns error? {
     string url = "ws://localhost:9099/subscriptions";
     websocket:Client wsClient = check new(url);
     string document = "subscription { evenNumber }";
     json payload = {query: document};
     check wsClient->writeMessage(payload);
     json expectedPayload = {data: {evenNumber: 2}};
     check validateWebSocketResponse(wsClient, expectedPayload);
     expectedPayload = check getJsonContentFromFile("errors_in_streams.json");
     check validateWebSocketResponse(wsClient, expectedPayload);
     expectedPayload = {data: {evenNumber: 6}};
     check validateWebSocketResponse(wsClient, expectedPayload);
 }

@test:Config {
    groups: ["sub_protocols", "subscriptions"]
}
isolated function testMultipleSubscriptionUsingSingleClient() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_WS]};
    websocket:Client wsClient = check new (url, config);

    check initiateConnectionInitMessage(wsClient);
    check validateConnectionInitMessage(wsClient);

    check writeWebSocketTextMessage(document, wsClient, {}, id = "1", subProtocol = GRAPHQL_WS);
    foreach int i in 1 ..< 6 {
        json payload = {data: {messages: i}};
        json expectedPayload = {"type": WS_DATA, id: "1", payload: payload};
        check validateWebSocketResponse(wsClient, expectedPayload);
    }
    json unsubscribe = {"type": WS_COMPLETE, id: "1", payload: null};
    check validateWebSocketResponse(wsClient, unsubscribe);
    check wsClient->writeMessage(unsubscribe);

    check writeWebSocketTextMessage(document, wsClient, {}, id = "2", subProtocol = GRAPHQL_WS);
    foreach int i in 1 ..< 6 {
        json payload = {data: {messages: i}};
        json expectedPayload = {"type": WS_DATA, id: "2", payload: payload};
        check validateWebSocketResponse(wsClient, expectedPayload);
    }
}

@test:Config {
    groups: ["sub_protocols", "subscriptions"]
}
isolated function testSubscriptionWithInvalidPayload() returns error? {
    string url = "ws://localhost:9099/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_WS]};
    websocket:Client wsClient = check new (url, config);

    check initiateConnectionInitMessage(wsClient);
    check validateConnectionInitMessage(wsClient);
    
    json invalidPayload = {"type": WS_START};
    check wsClient->writeMessage(invalidPayload);
    json|error response = wsClient->readMessage();
    test:assertTrue(response is error);
    test:assertEquals((<error>response).message(), "Request does not contain the id field: Status code: 1002");
}
