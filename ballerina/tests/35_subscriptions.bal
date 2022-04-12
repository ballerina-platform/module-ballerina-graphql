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
import ballerina/lang.value;

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscription() returns error? {
    string document = string`subscription getMessages { messages }`;
    string url = "ws://localhost:9091/subscriptions";
    json payload = {
        query: document,
        variables: ()
    };
    websocket:Client wsClient = check new(url);
    string payloadText = payload.toJsonString();
    check wsClient->writeTextMessage(payloadText);
    string textResponse = check wsClient->readTextMessage();
    foreach int i in 1..< 4 {
        json actualPayload = check value:fromJsonString(textResponse);
        json expectedPayload = { data : { messages: i }};
        assertJsonValuesWithOrder(actualPayload, expectedPayload);
        textResponse = check wsClient->readTextMessage();
    }
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionsWithMultipleClients() returns error? {
    string document1 = string`subscription { messages }`;
    string url = "ws://localhost:9091/subscriptions";
    json payload = {query: document1,variables: ()};
    websocket:Client wsClient1 = check new(url);
    websocket:Client wsClient2 = check new(url);
    string payloadText = payload.toJsonString();
    check wsClient1->writeTextMessage(payload.toJsonString());
    check wsClient2->writeTextMessage(payload.toJsonString());
    string textResponse1 = check wsClient1->readTextMessage();
    string textResponse2 = check wsClient2->readTextMessage();
    foreach int i in 1..< 4 {
        json actualPayload1 = check value:fromJsonString(textResponse1);       
        json actualPayload2 = check value:fromJsonString(textResponse2);
        json expectedPayload = { data : { messages: i }};
        assertJsonValuesWithOrder(actualPayload1, expectedPayload);
        assertJsonValuesWithOrder(actualPayload2, expectedPayload);
        textResponse1 = check wsClient1->readTextMessage();
        textResponse2 = check wsClient2->readTextMessage();
    }
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testDifferentSubscriptionsWithMultipleClients() returns error? {
    string document1 = string`subscription getMessages { messages }`;
    string document2 = string`subscription getStringMessages { stringMessages }`;
    string url = "ws://localhost:9091/subscriptions";
    json payload1 = {query: document1,variables: ()};
    json payload2 = {query: document2,variables: ()};
    websocket:Client wsClient1 = check new(url);
    websocket:Client wsClient2 = check new(url);
    check wsClient1->writeTextMessage(payload1.toJsonString());
    check wsClient2->writeTextMessage(payload2.toJsonString());
    string textResponse1 = check wsClient1->readTextMessage();
    string textResponse2 = check wsClient2->readTextMessage();
    foreach int i in 1..< 4 {
        json actualPayload1 = check value:fromJsonString(textResponse1);
        json expectedPayload1 = { data : { messages: i }};       
        assertJsonValuesWithOrder(actualPayload1, expectedPayload1);
        textResponse1 = check wsClient1->readTextMessage();
        json actualPayload2 = check value:fromJsonString(textResponse2);
        json expectedPayload2 = { data : { stringMessages: i.toString() }};
        assertJsonValuesWithOrder(actualPayload2, expectedPayload2);
        textResponse2 = check wsClient2->readTextMessage();
    }
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionsWithServiceObjects() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_service_objects.graphql");
    string url = "ws://localhost:9091/subscriptions";
    json payload = {query: document,variables: ()};
    websocket:Client wsClient = check new(url);
    string payloadText = payload.toJsonString();
    check wsClient->writeTextMessage(payloadText);
    string textResponse = check wsClient->readTextMessage();
    json actualPayload = check value:fromJsonString(textResponse);
    json expectedPayload = { data : { characters: { name: "Jim Halpert", age: 30 }}};
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
    textResponse = check wsClient->readTextMessage();
    actualPayload = check value:fromJsonString(textResponse);
    expectedPayload = { data : { characters: { name: "Dwight Schrute", age: 32 }}};
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testQueryOnServiceWithSubscriptions() returns error? {
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
    string document = string`subscription { name }`;
    string url = "ws://localhost:9091/subscriptions";
    json payload = {query: document,variables: ()};
    websocket:Client wsClient = check new(url);
    string payloadText = payload.toJsonString();
    check wsClient->writeTextMessage(payloadText);
    string textResponse = check wsClient->readTextMessage();
    json actualPayload = check value:fromJsonString(textResponse);
    json expectedPayload = {
        errors: [
            {
                message: string`Cannot query field "name" on type "Subscription".`,
                locations: [
                    {
                        line: 1,
                        column: 16
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "subscriptions"]
}
isolated function testSubscriptionsWithFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_fragments.graphql");
    string url = "ws://localhost:9091/subscriptions";
    json payload = {query: document,variables: ()};
    websocket:Client wsClient = check new(url);
    string payloadText = payload.toJsonString();
    check wsClient->writeTextMessage(payloadText);
    string textResponse = check wsClient->readTextMessage();
    json actualPayload = check value:fromJsonString(textResponse);
    json expectedPayload = { data : { characters: { name: "Jim Halpert", age: 30 }}};
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
    textResponse = check wsClient->readTextMessage();
    actualPayload = check value:fromJsonString(textResponse);
    expectedPayload = { data : { characters: { name: "Dwight Schrute", age: 32 }}};
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionsWithVariables() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_variable_values.graphql");
    json variables = { "value": 4 };
    string url = "ws://localhost:9091/subscriptions";
    json payload = {query: document,variables: variables};
    websocket:Client wsClient = check new(url);
    string payloadText = payload.toJsonString();
    check wsClient->writeTextMessage(payloadText);
    string textResponse = check wsClient->readTextMessage();
    foreach int i in 1..< 3 {
        json actualPayload = check value:fromJsonString(textResponse);
        json expectedPayload = { data : { filterValues: i }};
        assertJsonValuesWithOrder(actualPayload, expectedPayload);
        textResponse = check wsClient->readTextMessage();
    }
}
