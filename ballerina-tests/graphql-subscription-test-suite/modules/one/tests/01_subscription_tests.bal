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

import ballerina/graphql;
import ballerina/graphql_test_common as common;
import ballerina/test;
import ballerina/websocket;

const string SUBSCRIPTION_URL = "http://localhost:9091/subscriptions";
const string SUBSCRIPTION_WS_URL = "ws://localhost:9091/subscriptions";

type NameResponse record {|
    record {| string name; |} data;
|};

type MessagesResponse record {|
    record {| int messages; |} data;
|};

// The `stringMessages` operation begins with a `{data: null}` event before it starts emitting
// `stringMessages` values, so `data` is typed as nullable rather than being bound to `json`.
type StringMessagesResponse record {|
    record {| string stringMessages; |}? data;
|};

type BooksResponse record {|
    record {| Book books; |} data;
|};

type Student record {|
    int id;
    string name;
|};

type StudentsResponse record {|
    record {| Student students; |} data;
|};

type FilterValuesResponse record {|
    record {| int filterValues; |} data;
|};

type PersonData record {|
    int id?;
    string name;
    string subject?;
|};

type MultipleValuesResponse record {|
    record {| PersonData multipleValues; |} data;
|};

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscription() returns error? {
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<NameResponse, graphql:ClientError?> names = check graphqlClient->subscribe("subscription { name }");
    NameResponse[] received = [];
    check from NameResponse response in names
        do {
            received.push(response);
        };
    test:assertEquals(received, <NameResponse[]>[{data: {name: "Walter"}}, {data: {name: "Skyler"}}]);
    check graphqlClient->close();
}

// A raw `websocket:Client` smoke test: the GraphQL client always sets the `graphql-transport-ws`
// subprotocol, so the missing-subprotocol handshake rejection can only be exercised directly.
@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionWithoutSubProtocol() returns error? {
    websocket:Client|error wsClient = new (SUBSCRIPTION_WS_URL);
    string expectedErrorMsg = "InvalidHandshakeError: Invalid handshake response getStatus: 400 Bad Request";
    test:assertTrue(wsClient is websocket:InvalidHandshakeError, "Invalid handshake error expected");
    test:assertEquals((<error>wsClient).message(), expectedErrorMsg);
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionsWithMultipleOperations() returns error? {
    string document = check common:getGraphqlDocumentFromFile("subscriptions_with_multiple_operations");
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<MessagesResponse, graphql:ClientError?> messages =
        check graphqlClient->subscribe(document, operationName = "getMessages", id = "1");
    stream<StringMessagesResponse, graphql:ClientError?> stringMessages =
        check graphqlClient->subscribe(document, operationName = "getStringMessages", id = "2");

    record {|StringMessagesResponse value;|}|graphql:ClientError? firstStringMessage = stringMessages.next();
    test:assertTrue(firstStringMessage is record {|StringMessagesResponse value;|},
            "Expected the first stringMessages event");
    if firstStringMessage is record {|StringMessagesResponse value;|} {
        common:assertJsonValuesWithOrder(firstStringMessage.value, {data: null});
    }
    foreach int i in 1 ..< 4 {
        record {|MessagesResponse value;|}|graphql:ClientError? messageEvent = messages.next();
        test:assertTrue(messageEvent is record {|MessagesResponse value;|}, "Expected a messages event");
        if messageEvent is record {|MessagesResponse value;|} {
            test:assertEquals(messageEvent.value.data.messages, i);
        }
        record {|StringMessagesResponse value;|}|graphql:ClientError? stringMessageEvent = stringMessages.next();
        test:assertTrue(stringMessageEvent is record {|StringMessagesResponse value;|},
                "Expected a stringMessages event");
        if stringMessageEvent is record {|StringMessagesResponse value;|} {
            common:assertJsonValuesWithOrder(stringMessageEvent.value, {data: {stringMessages: i.toString()}});
        }
    }
    NameResponse queryResult = check graphqlClient->query(document, operationName = "getName");
    test:assertEquals(queryResult.data.name, "Walter White");
    check graphqlClient->close();
}

@test:Config {
    groups: ["records", "subscriptions"]
}
isolated function testSubscriptionWithRecords() returns error? {
    string document = check common:getGraphqlDocumentFromFile("subscriptions_with_records");
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<BooksResponse, graphql:ClientError?> books = check graphqlClient->subscribe(document);
    BooksResponse[] received = [];
    check from BooksResponse response in books
        do {
            received.push(response);
        };
    test:assertEquals(received, <BooksResponse[]>[
        {data: {books: {name: "Crime and Punishment", author: "Fyodor Dostoevsky"}}},
        {data: {books: {name: "A Game of Thrones", author: "George R.R. Martin"}}}
    ]);
    check graphqlClient->close();
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testQueryWithSameSubscriptionFieldName() returns error? {
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    NameResponse queryResult = check graphqlClient->query("query { name }");
    test:assertEquals(queryResult.data.name, "Walter White");
    check graphqlClient->close();
}

@test:Config {
    groups: ["fragments", "subscriptions"]
}
isolated function testSubscriptionWithFragments() returns error? {
    string document = check common:getGraphqlDocumentFromFile("subscriptions_with_fragments");
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<StudentsResponse, graphql:ClientError?> students = check graphqlClient->subscribe(document);
    StudentsResponse[] received = [];
    check from StudentsResponse response in students
        do {
            received.push(response);
        };
    test:assertEquals(received, <StudentsResponse[]>[
        {data: {students: {id: 1, name: "Eren Yeager"}}},
        {data: {students: {id: 2, name: "Mikasa Ackerman"}}}
    ]);
    check graphqlClient->close();
}

@test:Config {
    groups: ["union", "subscriptions"]
}
isolated function testSubscriptionWithUnionType() returns error? {
    string document = check common:getGraphqlDocumentFromFile("subscriptions_with_union_type");
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<MultipleValuesResponse, graphql:ClientError?> multipleValues = check graphqlClient->subscribe(document);
    MultipleValuesResponse[] received = [];
    check from MultipleValuesResponse response in multipleValues
        do {
            received.push(response);
        };
    test:assertEquals(received, <MultipleValuesResponse[]>[
        {data: {multipleValues: {id: 1, name: "Jesse Pinkman"}}},
        {data: {multipleValues: {name: "Walter White", subject: "Chemistry"}}}
    ]);
    check graphqlClient->close();
}

@test:Config {
    groups: ["variables", "subscriptions"]
}
isolated function testSubscriptionWithVariables() returns error? {
    string document = check common:getGraphqlDocumentFromFile("subscriptions_with_variable_values");
    map<anydata> variables = {"value": 4};
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<FilterValuesResponse, graphql:ClientError?> filterValues =
        check graphqlClient->subscribe(document, variables);
    FilterValuesResponse[] received = [];
    check from FilterValuesResponse response in filterValues
        do {
            received.push(response);
        };
    test:assertEquals(received, <FilterValuesResponse[]>[
        {data: {filterValues: 1}},
        {data: {filterValues: 2}},
        {data: {filterValues: 3}}
    ]);
    check graphqlClient->close();
}
