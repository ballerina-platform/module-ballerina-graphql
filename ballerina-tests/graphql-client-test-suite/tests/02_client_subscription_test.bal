// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
import ballerina/lang.runtime;
import ballerina/test;
import ballerina/time;

const string SUBSCRIPTION_URL = "http://localhost:9094/client_subscriptions";
const string MOCK_URL_BASE = "http://localhost:9092";

const string CLIENT_ALREADY_CLOSED_MESSAGE = "The GraphQL client is already closed";
const string HANDSHAKE_TIMED_OUT_MESSAGE = "GraphQL subscription handshake timed out while waiting for the connection_ack message";
const string CONNECTION_DROPPED_MESSAGE = "The GraphQL subscription connection was closed abnormally";
const string RECONNECTION_EXHAUSTED_MESSAGE = "The GraphQL subscription connection was lost and could not be re-established";
const string SUBSCRIPTION_SERVER_ERROR_MESSAGE = "The server responded with an error for the subscription";
const string KEEPALIVE_TIMEOUT_MESSAGE = "The GraphQL subscription server stopped responding to the keep-alive ping messages";

isolated int pingHandlerInvocationCount = 0;
isolated json receivedPingPayload = ();

// Named functions are used as the ping message handlers instead of anonymous functions due to
// a jBallerina backend issue: an anonymous isolated function used as a field value in a nested
// mapping constructor fails the code generation with `jVM generation is not supported for type
// other`. See: https://github.com/ballerina-platform/ballerina-lang/issues/44664
isolated function handlePingWithCustomPong(graphql:PingMessageCaller caller, map<json>? payload) returns error? {
    lock {
        receivedPingPayload = payload.clone();
    }
    check caller->pong({pong: "custom-payload"});
}

isolated function handlePingWithFailures(graphql:PingMessageCaller caller, map<json>? payload) returns error? {
    int invocationCount;
    lock {
        pingHandlerInvocationCount += 1;
        invocationCount = pingHandlerInvocationCount;
    }
    if invocationCount % 2 == 1 {
        return error("Error from the ping message handler");
    }
    panic error("Panic from the ping message handler");
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testSubscriptionWithRecordBinding() returns error? {
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<MessagesResponse, graphql:ClientError?> messages =
        check graphqlClient->subscribe("subscription { messages }");
    int expectedMessage = 1;
    check from MessagesResponse response in messages
        do {
            test:assertEquals(response.data.messages, expectedMessage);
            expectedMessage += 1;
        };
    test:assertEquals(expectedMessage, 6, "Expected 5 events from the subscription");
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testSubscriptionWithGenericResponseBinding() returns error? {
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<MessagesResponseWithErrors, graphql:ClientError?> messages =
        check graphqlClient->subscribe("subscription { messages }");
    int expectedMessage = 1;
    check from MessagesResponseWithErrors response in messages
        do {
            test:assertEquals(response.data.messages, expectedMessage);
            test:assertTrue(response?.errors is (), "Expected no errors in the response");
            expectedMessage += 1;
        };
    test:assertEquals(expectedMessage, 6, "Expected 5 events from the subscription");
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testMultipleConcurrentSubscriptions() returns error? {
    int initialConnectionCount = getSubscriptionConnectionCount();
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<EvergreenResponse, graphql:ClientError?> evergreen =
        check graphqlClient->subscribe("subscription { evergreen }");
    stream<BooksResponse, graphql:ClientError?> books =
        check graphqlClient->subscribe("subscription { books { name author } }");

    record {|EvergreenResponse value;|}|graphql:ClientError? evergreenEvent = evergreen.next();
    test:assertTrue(evergreenEvent is record {|EvergreenResponse value;|}, "Expected an event from evergreen");
    if evergreenEvent is record {|EvergreenResponse value;|} {
        test:assertEquals(evergreenEvent.value.data.evergreen, 1);
    }

    Book[] receivedBooks = [];
    check from BooksResponse response in books
        do {
            receivedBooks.push(response.data.books);
        };
    test:assertEquals(receivedBooks.length(), 2, "Expected 2 events from books");
    test:assertEquals(receivedBooks[0].name, "Crime and Punishment");

    evergreenEvent = evergreen.next();
    test:assertTrue(evergreenEvent is record {|EvergreenResponse value;|}, "Expected another event from evergreen");
    if evergreenEvent is record {|EvergreenResponse value;|} {
        test:assertEquals(evergreenEvent.value.data.evergreen, 2);
    }
    test:assertEquals(getSubscriptionConnectionCount() - initialConnectionCount, 1,
            "Expected a single WebSocket connection for both subscriptions");
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testUserProvidedOperationId() returns error? {
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<record {}, graphql:ClientError?> evergreen =
        check graphqlClient->subscribe("subscription { evergreen }", id = "user-provided-id");
    var firstEvent = evergreen.next();
    test:assertTrue(firstEvent is record {|record {} value;|}, "Expected an event from the subscription");

    stream<record {}, graphql:ClientError?>|graphql:ClientError duplicate =
        graphqlClient->subscribe("subscription { evergreen }", id = "user-provided-id");
    test:assertTrue(duplicate is graphql:SubscriptionError, "Expected a SubscriptionError for the duplicate id");
    if duplicate is graphql:SubscriptionError {
        test:assertEquals(duplicate.message(), string `A subscription with the id "user-provided-id" already exists`);
    }

    check evergreen.close();
    stream<record {}, graphql:ClientError?> reused =
        check graphqlClient->subscribe("subscription { evergreen }", id = "user-provided-id");
    var reusedEvent = reused.next();
    test:assertTrue(reusedEvent is record {|record {} value;|}, "Expected the id to be reusable after completion");
    check reused.close();
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testServerValidationError() returns error? {
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
            test:assertEquals(errors[0].message, string `Cannot query field "invalidField" on type "Subscription".`);
        }
    }
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testClientSideKindMismatch() returns error? {
    int initialConnectionCount = getSubscriptionConnectionCount();
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<record {}, graphql:ClientError?>|graphql:ClientError result = graphqlClient->subscribe("query { greet }");
    test:assertTrue(result is graphql:InvalidDocumentError, "Expected an InvalidDocumentError");
    if result is graphql:InvalidDocumentError {
        test:assertEquals(result.message(), "expected a subscription operation, but found a query operation");
    }
    test:assertEquals(getSubscriptionConnectionCount(), initialConnectionCount,
            "Expected no WebSocket connection to be opened");
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testStreamCloseUnsubscribes() returns error? {
    int initialConnectionCount = getSubscriptionConnectionCount();
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<EvergreenResponse, graphql:ClientError?> first =
        check graphqlClient->subscribe("subscription { evergreen }");
    stream<EvergreenResponse, graphql:ClientError?> second =
        check graphqlClient->subscribe("subscription { evergreen }");

    var firstEvent = first.next();
    test:assertTrue(firstEvent is record {|EvergreenResponse value;|});
    var secondEvent = second.next();
    test:assertTrue(secondEvent is record {|EvergreenResponse value;|});

    check first.close();

    secondEvent = second.next();
    test:assertTrue(secondEvent is record {|EvergreenResponse value;|},
            "Expected the other subscription to be unaffected");
    if secondEvent is record {|EvergreenResponse value;|} {
        test:assertEquals(secondEvent.value.data.evergreen, 2);
    }
    test:assertEquals(getSubscriptionConnectionCount() - initialConnectionCount, 1,
            "Expected the connection to stay open");
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testClientClose() returns error? {
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<EvergreenResponse, graphql:ClientError?> evergreen =
        check graphqlClient->subscribe("subscription { evergreen }");
    var event = evergreen.next();
    test:assertTrue(event is record {|EvergreenResponse value;|});

    check graphqlClient->close();
    var afterClose = evergreen.next();
    test:assertTrue(afterClose is (), "Expected the stream to be terminated with nil");

    record {}|graphql:ClientError queryResult = graphqlClient->query("query { greet }");
    test:assertTrue(queryResult is graphql:ClientError, "Expected a ClientError for query after close");
    if queryResult is graphql:ClientError {
        test:assertEquals(queryResult.message(), CLIENT_ALREADY_CLOSED_MESSAGE);
    }
    record {}|graphql:ClientError mutateResult = graphqlClient->mutate("mutation { setGreet }");
    test:assertTrue(mutateResult is graphql:ClientError, "Expected a ClientError for mutate after close");
    stream<record {}, graphql:ClientError?>|graphql:ClientError subscribeResult =
        graphqlClient->subscribe("subscription { evergreen }");
    test:assertTrue(subscribeResult is graphql:ClientError, "Expected a ClientError for subscribe after close");
    if subscribeResult is graphql:ClientError {
        test:assertEquals(subscribeResult.message(), CLIENT_ALREADY_CLOSED_MESSAGE);
    }
    graphql:ClientError? secondClose = graphqlClient->close();
    test:assertTrue(secondClose is (), "Expected the second close to be a no-op");
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testPingPongKeepAlive() returns error? {
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<record {}, graphql:ClientError?> messages = check graphqlClient->subscribe("subscription { slowMessages }");
    record {}[] receivedEvents = [];
    check from record {} response in messages
        do {
            receivedEvents.push(response);
        };
    test:assertEquals(receivedEvents, <json[]>[{data: {slowMessages: 1}}, {data: {slowMessages: 2}}],
            "Expected the subscription to stay alive past the server ping cadence");
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testKeepAliveMissingPongDoesNotTearDownConnection() returns error? {
    graphql:Client graphqlClient = check new (string `${MOCK_URL_BASE}/mock_keepalive_silent`,
        subscription = {keepAlive: {pingInterval: 1, pongTimeout: 1}}
    );
    stream<record {}, graphql:ClientError?> subscription = check graphqlClient->subscribe("subscription { seq }");
    record {}[] receivedEvents = [];
    check from record {} response in subscription
        do {
            receivedEvents.push(response);
        };
    test:assertEquals(receivedEvents, <json[]>[{data: {seq: 1}}, {data: {seq: 2}}],
            "Expected the subscription to stay alive and complete despite the server never ponging");
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testConnectionDropTriggersReconnect() returns error? {
    graphql:Client graphqlClient = check new (string `${MOCK_URL_BASE}/mock_keepalive_recover`,
        subscription = {keepAlive: {pingInterval: 1, pongTimeout: 1}, reconnect: {maxAttempts: 3, interval: 1}}
    );
    stream<record {}, graphql:ClientError?> subscription = check graphqlClient->subscribe("subscription { seq }");
    record {}[] receivedEvents = [];
    check from record {} response in subscription
        do {
            receivedEvents.push(response);
        };
    test:assertEquals(receivedEvents, <json[]>[{data: {seq: 1}}, {data: {seq: 2}}],
            "Expected the subscription to resume on a fresh connection after the connection drop");
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testKeepAliveKeepsHealthyConnectionAlive() returns error? {
    // The server responds to the client's ping messages, so the keep-alive must not tear down a
    // healthy connection: events keep flowing across several ping cycles.
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL,
        subscription = {keepAlive: {pingInterval: 1, pongTimeout: 3}}
    );
    stream<EvergreenResponse, graphql:ClientError?> evergreen =
        check graphqlClient->subscribe("subscription { evergreen }");
    int expected = 1;
    while expected <= 10 {
        var event = evergreen.next();
        test:assertTrue(event is record {|EvergreenResponse value;|},
                string `Expected event ${expected} while the keep-alive connection stays healthy`);
        if event is record {|EvergreenResponse value;|} {
            test:assertEquals(event.value.data.evergreen, expected);
        }
        expected += 1;
    }
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testKeepAliveDisabled() returns error? {
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL, subscription = {keepAlive: {enabled: false}});
    stream<record {}, graphql:ClientError?> messages = check graphqlClient->subscribe("subscription { messages }");
    int expectedMessage = 1;
    check from record {} response in messages
        do {
            test:assertEquals(response, <json>{data: {messages: expectedMessage}});
            expectedMessage += 1;
        };
    test:assertEquals(expectedMessage, 6, "Expected all events with the keep-alive disabled");
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testInvalidKeepAliveConfig() returns error? {
    graphql:Client|graphql:ClientError nonPositiveInterval = new (SUBSCRIPTION_URL,
        subscription = {keepAlive: {pingInterval: 0}}
    );
    test:assertTrue(nonPositiveInterval is graphql:ClientError,
            "Expected a ClientError for a non-positive pingInterval");
    if nonPositiveInterval is graphql:ClientError {
        test:assertTrue(nonPositiveInterval.message().includes("keep-alive"),
                "Expected a keep-alive configuration error");
    }
    graphql:Client|graphql:ClientError negativePongTimeout = new (SUBSCRIPTION_URL,
        subscription = {keepAlive: {pongTimeout: -1}}
    );
    test:assertTrue(negativePongTimeout is graphql:ClientError,
            "Expected a ClientError for a negative pongTimeout");
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testConnectionInitPayloadAuth() returns error? {
    graphql:Client graphqlClient = check new (string `${MOCK_URL_BASE}/mock_init_auth`,
        subscription = {connectionInitPayload: {token: "token-xyz"}}
    );
    stream<record {}, graphql:ClientError?> greetings = check graphqlClient->subscribe("subscription { greet }");
    var event = greetings.next();
    test:assertTrue(event is record {|record {} value;|}, "Expected an event from the authenticated subscription");
    if event is record {|record {} value;|} {
        test:assertEquals(event.value, <json>{data: {greet: "Hello"}});
    }
    check graphqlClient->close();

    graphql:Client unauthenticatedClient = check new (string `${MOCK_URL_BASE}/mock_init_auth`,
        timeout = 5, subscription = {connectionInitPayload: {token: "invalid-token"}}
    );
    stream<record {}, graphql:ClientError?>|graphql:ClientError result =
        unauthenticatedClient->subscribe("subscription { greet }");
    test:assertTrue(result is graphql:SubscriptionError, "Expected a SubscriptionError for the invalid token");
    check unauthenticatedClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testUpgradeHeaderAuth() returns error? {
    graphql:Client graphqlClient = check new (string `${MOCK_URL_BASE}/mock_header_auth`,
        subscription = {
            websocketConfig: {
                customHeaders: {"Authorization": "Bearer token-xyz"}
            }
        }
    );
    stream<record {}, graphql:ClientError?> greetings = check graphqlClient->subscribe("subscription { greet }");
    var event = greetings.next();
    test:assertTrue(event is record {|record {} value;|}, "Expected an event from the authenticated subscription");
    check graphqlClient->close();

    graphql:Client unauthenticatedClient = check new (string `${MOCK_URL_BASE}/mock_header_auth`, timeout = 5);
    stream<record {}, graphql:ClientError?>|graphql:ClientError result =
        unauthenticatedClient->subscribe("subscription { greet }");
    test:assertTrue(result is graphql:SubscriptionError, "Expected a SubscriptionError without the auth header");
    check unauthenticatedClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testHandshakeTimeout() returns error? {
    // The handshake is bounded by the WebSocket-scoped `connectionInitTimeout`, independent of the
    // HTTP `timeout` (kept high here to confirm the HTTP timeout does not bound the handshake).
    graphql:Client graphqlClient = check new (string `${MOCK_URL_BASE}/mock_no_ack`, timeout = 30,
        subscription = {connectionInitTimeout: 3});
    decimal startTime = time:monotonicNow();
    stream<record {}, graphql:ClientError?>|graphql:ClientError result = graphqlClient->subscribe("subscription { greet }");
    decimal elapsedTime = time:monotonicNow() - startTime;
    test:assertTrue(result is graphql:SubscriptionError, "Expected a SubscriptionError");
    if result is graphql:SubscriptionError {
        test:assertEquals(result.message(), HANDSHAKE_TIMED_OUT_MESSAGE);
    }
    test:assertTrue(elapsedTime >= 3d && elapsedTime < 8d,
            string `Expected the handshake to time out within the configured timeout, took ${elapsedTime.toString()}s`);
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testPayloadBindingFailure() returns error? {
    graphql:Client graphqlClient = check new (SUBSCRIPTION_URL);
    stream<StringMessagesResponse, graphql:ClientError?> messages =
        check graphqlClient->subscribe("subscription { messages }");
    record {|StringMessagesResponse value;|}|graphql:ClientError? result = messages.next();
    test:assertTrue(result is graphql:PayloadBindingError, "Expected a PayloadBindingError");
    if result is graphql:PayloadBindingError {
        test:assertEquals(result.message(), "Unable to perform data binding");
    }
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testSubscribeAfterConnectionDropWithoutReconnect() returns error? {
    graphql:Client graphqlClient = check new (string `${MOCK_URL_BASE}/mock_drop`);
    stream<record {}, graphql:ClientError?> firstSubscription = check graphqlClient->subscribe("subscription { seq }");
    var firstEvent = firstSubscription.next();
    test:assertTrue(firstEvent is record {|record {} value;|}, "Expected the first event before the drop");
    if firstEvent is record {|record {} value;|} {
        test:assertEquals(firstEvent.value, <json>{data: {seq: 1}});
    }
    record {|record {} value;|}|graphql:ClientError? terminalEvent = firstSubscription.next();
    test:assertTrue(terminalEvent is graphql:SubscriptionError, "Expected the stream to terminate with an error");
    if terminalEvent is graphql:SubscriptionError {
        test:assertEquals(terminalEvent.message(), CONNECTION_DROPPED_MESSAGE);
    }

    stream<record {}, graphql:ClientError?> secondSubscription = check graphqlClient->subscribe("subscription { seq }");
    record {}[] receivedEvents = [];
    check from record {} response in secondSubscription
        do {
            receivedEvents.push(response);
        };
    test:assertEquals(receivedEvents, <json[]>[{data: {seq: 2}}],
            "Expected a fresh connection to serve the new subscription");
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testPingMessageHandlerCustomPayload() returns error? {
    graphql:Client graphqlClient = check new (string `${MOCK_URL_BASE}/mock_ping`,
        subscription = {
            pingMessageHandler: handlePingWithCustomPong
        }
    );
    stream<record {}, graphql:ClientError?> greetings = check graphqlClient->subscribe("subscription { greet }");
    record {}[] receivedEvents = [];
    check from record {} response in greetings
        do {
            receivedEvents.push(response);
        };
    test:assertEquals(receivedEvents, <json[]>[{data: {greet: "Hello"}}],
            "Expected the subscription to complete after the custom pong");
    lock {
        test:assertEquals(receivedPingPayload, <json>{seq: "1"}, "Expected the ping payload to be received");
    }
    test:assertEquals(getRecordedPongPayload(), <json>{pong: "custom-payload"},
            "Expected the server to receive the custom pong payload");
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testPingMessageHandlerErrorResilience() returns error? {
    graphql:Client graphqlClient = check new (string `${MOCK_URL_BASE}/mock_ping_push`,
        subscription = {
            pingMessageHandler: handlePingWithFailures
        }
    );
    stream<record {}, graphql:ClientError?> greetings = check graphqlClient->subscribe("subscription { greet }");
    record {}[] receivedEvents = [];
    check from record {} response in greetings
        do {
            receivedEvents.push(response);
        };
    test:assertEquals(receivedEvents, <json[]>[{data: {greet: "Hello"}}],
            "Expected the subscription to be unaffected by the failing ping message handler");
    // The two ping handler strands run asynchronously; poll (bounded) until both have been
    // invoked instead of assuming they complete within a fixed sleep. Exactly two pings are sent
    // and the event stream has already drained, so the count settles at two.
    int invocationCount = 0;
    int waited = 0;
    while waited < 100 {
        lock {
            invocationCount = pingHandlerInvocationCount;
        }
        if invocationCount >= 2 {
            break;
        }
        runtime:sleep(0.1);
        waited += 1;
    }
    test:assertEquals(invocationCount, 2, "Expected the handler to be invoked for both ping messages");
    check graphqlClient->close();
}
