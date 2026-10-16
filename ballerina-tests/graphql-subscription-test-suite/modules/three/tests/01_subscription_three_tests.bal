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
const string REVIEWS_URL = "http://localhost:9092/reviews";

type MessagesResponse record {|
    record {| int messages; |} data;
|};

type LiveResponse record {|
    record {| record {| record {| string id; |} product; int score; |} live; |} data;
|};

type AccountUpdatesResponse record {|
    record {| record {| record {| string name; |} details; |} accountUpdates; |} data;
|};

// A raw `websocket:Client` smoke test: reusing a subscriber id triggers a `4409` connection
// closure, a transport-level protocol edge the GraphQL client (which rejects duplicate ids
// locally with a `SubscriptionError`) cannot exercise against the server.
@test:Config {
    groups: ["subscriptions"]
}
function testAlreadyExistingSubscriber() returns error? {
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

// A raw `websocket:Client` smoke test: the protocol-level ping/pong handshake is not surfaced
// through the GraphQL client API.
@test:Config {
    groups: ["subscriptions"]
}
isolated function testOnPing() returns error? {
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check wsClient->writeMessage({'type: common:WS_PING});
    json response = check wsClient->readMessage();
    test:assertEquals(response.'type, common:WS_PONG);
    check wsClient->close();
}

// A raw `websocket:Client` smoke test: the GraphQL client always negotiates the
// `graphql-transport-ws` subprotocol, so a mismatched subprotocol handshake can only be
// exercised directly.
@test:Config {
    groups: ["subscriptions"]
}
isolated function testInvalidSubProtocolInSubscriptions() returns error? {
    string url = "ws://localhost:9091/subscriptions";
    string subProtocol = "graphql-invalid-ws";
    websocket:ClientConfiguration config = {subProtocols: [subProtocol]};
    websocket:Client|error wsClient = new (url, config);
    test:assertTrue(wsClient is websocket:InvalidHandshakeError, "Invalid handshake error expected");
    string expectedErrorMsg = "InvalidHandshakeError: Invalid subprotocol. Actual: null. Expected one of: graphql-invalid-ws";
    test:assertEquals((<error>wsClient).message(), expectedErrorMsg);
}

@test:Config {
    groups: ["subscriptions", "runtime_errors"]
}
isolated function testErrorsInStreams() returns error? {
    string document = "subscription { evenNumber }";
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    // A mid-stream runtime error arrives as a `next` message carrying `{data: null, errors: [...]}`,
    // disjoint from the regular `{data: {evenNumber: ...}}` events, so the stream is bound to the
    // generic open record rather than a fixed shape.
    stream<record {}, graphql:ClientError?> evenNumbers = check graphqlClient->subscribe(document);
    record {}[] received = [];
    check from record {} response in evenNumbers
        do {
            received.push(response);
        };
    json errorsInStream = check common:getJsonContentFromFile("errors_in_streams");
    test:assertEquals(received, <json[]>[
        {data: {evenNumber: 2}},
        errorsInStream,
        {data: {evenNumber: 6}}
    ]);
    check graphqlClient->close();
}

@test:Config {
    groups: ["subscriptions"]
}
isolated function testMultipleSubscriptionUsingSingleClient() returns error? {
    string document = string `subscription { messages }`;
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);

    stream<MessagesResponse, graphql:ClientError?> first = check graphqlClient->subscribe(document, id = "1");
    int expected = 1;
    check from MessagesResponse response in first
        do {
            test:assertEquals(response.data.messages, expected);
            expected += 1;
        };
    test:assertEquals(expected, 6, "Expected 5 events from the first subscription");

    stream<MessagesResponse, graphql:ClientError?> second = check graphqlClient->subscribe(document, id = "2");
    expected = 1;
    check from MessagesResponse response in second
        do {
            test:assertEquals(response.data.messages, expected);
            expected += 1;
        };
    test:assertEquals(expected, 6, "Expected 5 events from the second subscription");
    check graphqlClient->close();
}

// A raw `websocket:Client` smoke test: sending a message that violates the
// `graphql-transport-ws` format triggers a `1003` connection closure, an invalid-message-format
// transport edge the GraphQL client cannot produce.
@test:Config {
    groups: ["subscriptions"]
}
isolated function testSubscriptionWithInvalidPayload() returns error? {
    string url = "ws://localhost:9091/subscriptions";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    json invalidPayload = {'type: "start"};
    check wsClient->writeMessage(invalidPayload);

    string expectedErrorMsg = "Invalid format: payload does not conform to the format required by the" +
        " 'graphql-transport-ws' subprotocol: Status code: 1003";
    common:validateConnectionClosureWithError(wsClient, expectedErrorMsg);
}

@test:Config {
    groups: ["subscriptions", "recrods", "service"]
}
isolated function testResolverReturingStreamOfRecordsWithServiceObjects() returns error? {
    string document = "subscription { live { product { id } score } }";
    graphql:Client graphqlClient = check new (REVIEWS_URL);
    stream<LiveResponse, graphql:ClientError?> live = check graphqlClient->subscribe(document);
    record {|LiveResponse value;|}|graphql:ClientError? event = live.next();
    test:assertTrue(event is record {|LiveResponse value;|}, "Expected an event from the live subscription");
    if event is record {|LiveResponse value;|} {
        test:assertEquals(event.value, <LiveResponse>{data: {live: {product: {id: "1"}, score: 20}}});
    }
    check graphqlClient->close();
}

@test:Config {
    groups: ["subscriptions", "recrods", "service", "maps"]
}
isolated function testResolverReturingStreamOfRecordsWithMapOfServiceObjects() returns error? {
    string document = string `subscription { accountUpdates { details(key: "acc1") { name } } }`;
    graphql:Client graphqlClient = check new (REVIEWS_URL);
    stream<AccountUpdatesResponse, graphql:ClientError?> accountUpdates = check graphqlClient->subscribe(document);
    AccountUpdatesResponse[] received = [];
    check from AccountUpdatesResponse response in accountUpdates
        do {
            received.push(response);
        };
    test:assertEquals(received, <AccountUpdatesResponse[]>[
        {data: {accountUpdates: {details: {name: "James"}}}},
        {data: {accountUpdates: {details: {name: "James Deen"}}}}
    ]);
    check graphqlClient->close();
}
