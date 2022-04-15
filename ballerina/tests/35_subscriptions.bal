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
isolated function testSubscriptions() returns error? {
    string document = string`subscription getNames { name }`;
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = { data : { name: "Walter" }};
    check validateWebSocketResponse(wsClient, expectedPayload);
    expectedPayload = { data : { name: "Skyler" }};
    check validateWebSocketResponse(wsClient, expectedPayload);   
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionsWithMultipleClients() returns error? {
    string document = string`subscription { messages }`;
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient1 = check new(url);
    websocket:Client wsClient2 = check new(url);
    check writeWebSocketTextMessage(document, wsClient1);
    check writeWebSocketTextMessage(document, wsClient2);
    foreach int i in 1..< 4 {
        json expectedPayload = { data : { messages: i }};
        check validateWebSocketResponse(wsClient1, expectedPayload);
        check validateWebSocketResponse(wsClient2, expectedPayload);
    }
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testMultipleSubscriptionsWithMultipleClients() returns error? {
    string document1 = string`
        subscription getMessages { 
            messages 
        }
        subscription getStringMessages { 
            stringMessages 
        }`;
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient1 = check new(url);
    websocket:Client wsClient2 = check new(url);
    check writeWebSocketTextMessage(document1, wsClient1, {}, "getMessages");
    check writeWebSocketTextMessage(document1, wsClient2, {}, "getStringMessages");
    foreach int i in 1..< 4 {
        json expectedPayload1 = { data : { messages: i }};       
        check validateWebSocketResponse(wsClient1, expectedPayload1);
        json expectedPayload2 = { data : { stringMessages: i.toString() }};
        check validateWebSocketResponse(wsClient2, expectedPayload2);
    }
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionsWithServiceObjects() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_service_objects.graphql");
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = { data : { students: { id: 1, name: "Eren Yeager" }}};
    check validateWebSocketResponse(wsClient, expectedPayload);
    expectedPayload = { data : { students: { id: 2, name: "Mikasa Ackerman" }}};
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionsWithRecords() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_records.graphql");
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = { data : { books: { name: "Crime and Punishment", author: "Fyodor Dostoevsky" }}};
    check validateWebSocketResponse(wsClient, expectedPayload);
    expectedPayload = { data : { books: { name: "A Game of Thrones", author: "George R.R. Martin" }}};
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testQueryWithSameSubscriptionFieldName() returns error? {
    string document = string`query { name }`;
    string url = "http://localhost:9091/subscriptions";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = { data : { name: "Walter White"}};
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testInvalidSubscriptionRequest() returns error? {
    string document = string`subscription { invalidField }`;
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = {
        errors: [
            {
                message: string`Cannot query field "invalidField" on type "Subscription".`,
                locations: [
                    {
                        line: 1,
                        column: 16
                    }
                ]
            }
        ]
    };
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["fragments", "subscriptions"]
}
isolated function testSubscriptionsWithFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_fragments.graphql");
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = { data : { students: { id: 1, name: "Eren Yeager" }}};
    check validateWebSocketResponse(wsClient, expectedPayload);
    expectedPayload = { data : { students: { id: 2, name: "Mikasa Ackerman" }}};
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionsWithVariables() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_variable_values.graphql");
    json variables = { "value": 4 };
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient, variables);
    foreach int i in 1..< 3 {
        json expectedPayload = { data : { filterValues: i }};
        check validateWebSocketResponse(wsClient, expectedPayload);
    }
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testInvalidSubscriptionWithMultipleRootFields() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_multiple_root_fields.graphql");
    string url = "ws://localhost:9091/subscriptions";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = {
        errors: [
            {
                message: string`Subscription operations must have exactly one root field.`,
                locations: [
                    {
                        line: 3,
                        column: 5
                    }
                ]
            }
        ]
    };
    check validateWebSocketResponse(wsClient, expectedPayload);
}
