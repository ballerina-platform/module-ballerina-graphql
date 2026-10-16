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

const string SUBSCRIPTION_SERVER_ERROR_MESSAGE = "The server responded with an error for the subscription";

type MessagesResponse record {|
    record {| int messages; |} data;
|};

type Student record {|
    int id;
    string name;
|};

type StudentsResponse record {|
    record {| Student students; |} data;
|};

type StudentTypenameResponse record {|
    record {| record {| string __typename; |} students; |} data;
|};

@test:Config {
    groups: ["introspection", "typename", "subscriptions"]
}
isolated function testSubscriptionWithIntrospectionInFields() returns error? {
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<StudentTypenameResponse, graphql:ClientError?> students =
        check graphqlClient->subscribe("subscription { students { __typename } }");
    // The original test validates only the first event, so read just that prefix of the stream.
    record {|StudentTypenameResponse value;|}|graphql:ClientError? event = students.next();
    test:assertTrue(event is record {|StudentTypenameResponse value;|}, "Expected a students event");
    if event is record {|StudentTypenameResponse value;|} {
        test:assertEquals(event.value.data.students.__typename, "StudentService");
    }
    check graphqlClient->close();
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testInvalidSubscription() returns error? {
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<record {}, graphql:ClientError?> invalidSubscription =
        check graphqlClient->subscribe("subscription { invalidField }");
    record {|record {} value;|}|graphql:ClientError? result = invalidSubscription.next();
    test:assertTrue(result is graphql:SubscriptionError, "Expected a SubscriptionError");
    if result is graphql:SubscriptionError {
        test:assertEquals(result.message(), SUBSCRIPTION_SERVER_ERROR_MESSAGE);
        graphql:ErrorDetail[]? errors = result.detail().errors;
        test:assertTrue(errors is graphql:ErrorDetail[], "Expected the GraphQL errors in the detail");
        if errors is graphql:ErrorDetail[] {
            test:assertEquals(errors, <graphql:ErrorDetail[]>[
                {
                    message: string `Cannot query field "invalidField" on type "Subscription".`,
                    locations: [{line: 1, column: 16}]
                }
            ]);
        }
    }
    check graphqlClient->close();
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionFunctionWithErrors() returns error? {
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<record {}, graphql:ClientError?> values =
        check graphqlClient->subscribe("subscription getNames { values }");
    record {|record {} value;|}|graphql:ClientError? result = values.next();
    test:assertTrue(result is graphql:SubscriptionError, "Expected a SubscriptionError");
    if result is graphql:SubscriptionError {
        test:assertEquals(result.message(), SUBSCRIPTION_SERVER_ERROR_MESSAGE);
        graphql:ErrorDetail[]? errors = result.detail().errors;
        test:assertTrue(errors is graphql:ErrorDetail[], "Expected the GraphQL errors in the detail");
        if errors is graphql:ErrorDetail[] {
            test:assertEquals(errors, <graphql:ErrorDetail[]>[
                {
                    message: "{ballerina/lang.array}IndexOutOfRange",
                    locations: [{line: 1, column: 25}],
                    path: ["values"]
                }
            ]);
        }
    }
    check graphqlClient->close();
}

@test:Config {
    groups: ["service", "subscriptions"]
}
isolated function testSubscriptionWithServiceObjects() returns error? {
    string document = check common:getGraphqlDocumentFromFile("subscriptions_with_service_objects");
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
    groups: ["subscriptions"]
}
isolated function testSubscriptionWithMultipleClients() returns error? {
    string document = string `subscription { messages }`;
    graphql:Client graphqlClient1 = check new (SUBSCRIPTION_URL);
    graphql:Client graphqlClient2 = check new (SUBSCRIPTION_URL);
    stream<MessagesResponse, graphql:ClientError?> messages1 = check graphqlClient1->subscribe(document);
    stream<MessagesResponse, graphql:ClientError?> messages2 = check graphqlClient2->subscribe(document);

    foreach int i in 1 ..< 6 {
        record {|MessagesResponse value;|}|graphql:ClientError? event1 = messages1.next();
        test:assertTrue(event1 is record {|MessagesResponse value;|}, "Expected a messages event on client 1");
        if event1 is record {|MessagesResponse value;|} {
            test:assertEquals(event1.value.data.messages, i);
        }
        record {|MessagesResponse value;|}|graphql:ClientError? event2 = messages2.next();
        test:assertTrue(event2 is record {|MessagesResponse value;|}, "Expected a messages event on client 2");
        if event2 is record {|MessagesResponse value;|} {
            test:assertEquals(event2.value.data.messages, i);
        }
    }
    check graphqlClient1->close();
    check graphqlClient2->close();
}

// The following are raw `websocket:Client` smoke tests: they exercise `graphql-transport-ws`
// protocol/transport edges that the GraphQL client manages internally and therefore cannot express.

// The GraphQL client performs the `connection_init`/`connection_ack` handshake internally, so the
// bare handshake can only be observed by driving the WebSocket directly.
@test:Config {
    groups: ["subscriptions"]
}
isolated function testConnectionInitMessage() returns error? {
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:sendConnectionInitMessage(wsClient);
    check common:validateConnectionAckMessage(wsClient);
    check wsClient->close();
}

// The GraphQL client sends exactly one `connection_init`, so the duplicate-init rejection (4429)
// can only be triggered by sending a second `connection_init` over a raw WebSocket.
@test:Config {
    groups: ["subscriptions"]
}
isolated function testInvalidMultipleConnectionInitMessages() returns error? {
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendConnectionInitMessage(wsClient);

    string expectedErrorMsg = "Too many initialisation requests: Status code: 4429";
    common:validateConnectionClosureWithError(wsClient, expectedErrorMsg);
}

// The GraphQL client always completes the `connection_init` handshake before subscribing, so the
// unauthorized-access closure (4401) for a subscribe-before-init can only be exercised directly.
@test:Config {
    groups: ["subscriptions"]
}
isolated function testUnauthorizedAccess() returns error? {
    string document = check common:getGraphqlDocumentFromFile("subscriptions_with_service_objects");
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:sendSubscriptionMessage(wsClient, document);

    string expectedErrorMsg = "Unauthorized: Status code: 4401";
    common:validateConnectionClosureWithError(wsClient, expectedErrorMsg);
}
