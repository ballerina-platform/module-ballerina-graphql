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

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testReconnectResumesSubscriptions() returns error? {
    graphql:Client graphqlClient = check new (string `${MOCK_URL_BASE}/mock_reconnect`,
        subscription = {reconnect: {maxAttempts: 3, interval: 1}}
    );
    stream<record {}, graphql:ClientError?> firstSubscription =
        check graphqlClient->subscribe("subscription { seq }", id = "op-a");
    var firstEvent = firstSubscription.next();
    test:assertTrue(firstEvent is record {|record {} value;|}, "Expected the first event before the drop");

    stream<record {}, graphql:ClientError?> secondSubscription =
        check graphqlClient->subscribe("subscription { seq }", id = "op-b");

    record {}[] firstStreamEvents = [];
    if firstEvent is record {|record {} value;|} {
        firstStreamEvents.push(firstEvent.value);
    }
    check from record {} response in firstSubscription
        do {
            firstStreamEvents.push(response);
        };
    record {}[] secondStreamEvents = [];
    check from record {} response in secondSubscription
        do {
            secondStreamEvents.push(response);
        };

    test:assertEquals(firstStreamEvents, <json[]>[{data: {seq: 1}}, {data: {seq: 2}}],
            "Expected the first subscription to resume after the reconnection");
    test:assertEquals(secondStreamEvents, <json[]>[{data: {seq: 1}}, {data: {seq: 2}}],
            "Expected the second subscription to resume after the reconnection");

    string[] resubscribedIds;
    lock {
        resubscribedIds = mockReconnectSecondConnectionIds.clone();
    }
    test:assertEquals(resubscribedIds.sort(), ["op-a", "op-b"],
            "Expected both operations to be resubscribed with the original ids");
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testReconnectExhaustion() returns error? {
    graphql:Client graphqlClient = check new (string `${MOCK_URL_BASE}/mock_exhaustion`, timeout = 5,
        subscription = {reconnect: {maxAttempts: 2, interval: 1, backOffFactor: 2.0}}
    );
    // The mock server drops the connection upon the subscribe message and rejects every
    // subsequent connection upgrade, so every reconnection attempt fails.
    decimal startTime = time:monotonicNow();
    stream<record {}, graphql:ClientError?> subscription = check graphqlClient->subscribe("subscription { seq }");

    record {|record {} value;|}|graphql:ClientError? terminalEvent = subscription.next();
    decimal elapsedTime = time:monotonicNow() - startTime;
    test:assertTrue(terminalEvent is graphql:SubscriptionError, "Expected the stream to terminate with an error");
    if terminalEvent is graphql:SubscriptionError {
        test:assertEquals(terminalEvent.message(), RECONNECTION_EXHAUSTED_MESSAGE);
    }
    // Two attempts with the backoff delays of 1s and 2s must take at least 3 seconds.
    test:assertTrue(elapsedTime >= 3d, string `Expected the backoff delays to apply, took ${elapsedTime.toString()}s`);
    test:assertTrue(elapsedTime < 15d, string `Expected the attempts to stop, took ${elapsedTime.toString()}s`);
    check graphqlClient->close();
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testCloseDuringReconnect() returns error? {
    graphql:Client graphqlClient = check new (string `${MOCK_URL_BASE}/mock_close_reconnect`,
        subscription = {reconnect: {maxAttempts: 2, interval: 4}}
    );
    stream<record {}, graphql:ClientError?> subscription = check graphqlClient->subscribe("subscription { seq }");
    // The server drops the connection upon the subscribe message. Wait (bounded) for the
    // server-side drop signal, then allow the client to detect the drop and enter the reconnection
    // backoff before closing. Closing only after the client has released the dropped connection
    // avoids racing the server-initiated closure (which caused a close-frame code collision), while
    // the short settle stays well within the 4-second backoff so close() still lands mid-reconnect.
    int waited = 0;
    while !isMockCloseReconnectDropped() && waited < 100 {
        runtime:sleep(0.1);
        waited += 1;
    }
    test:assertTrue(isMockCloseReconnectDropped(), "Expected the server to drop the first connection");
    runtime:sleep(2);
    int connectionCountBeforeClose;
    lock {
        connectionCountBeforeClose = mockCloseReconnectConnectionCount;
    }
    check graphqlClient->close();

    record {|record {} value;|}|graphql:ClientError? terminalEvent = subscription.next();
    test:assertTrue(terminalEvent is (), "Expected the stream to be terminated with nil upon close");

    // Wait past the reconnect interval and verify that no new connection attempts were made.
    runtime:sleep(5);
    lock {
        test:assertEquals(mockCloseReconnectConnectionCount, connectionCountBeforeClose,
                "Expected no further connection attempts after close");
    }
}

@test:Config {
    groups: ["client", "client_subscriptions"]
}
isolated function testClosedStreamNotResubscribed() returns error? {
    graphql:Client graphqlClient = check new (string `${MOCK_URL_BASE}/mock_selective_reconnect`,
        // A generous `pongTimeout` tolerates a delayed pong under CI scheduling contention, so the
        // keep-alive watchdog doesn't tear down the reconnected connection before it can resume.
        subscription = {reconnect: {maxAttempts: 3, interval: 1}, keepAlive: {pongTimeout: 45}}
    );
    stream<record {}, graphql:ClientError?> firstSubscription =
        check graphqlClient->subscribe("subscription { seq }", id = "op-a");
    var firstEvent = firstSubscription.next();
    test:assertTrue(firstEvent is record {|record {} value;|}, "Expected an event for the first subscription");

    stream<record {}, graphql:ClientError?> secondSubscription =
        check graphqlClient->subscribe("subscription { seq }", id = "op-b");
    var secondEvent = secondSubscription.next();
    test:assertTrue(secondEvent is record {|record {} value;|}, "Expected an event for the second subscription");

    // Closing the first stream sends a complete message, upon which the mock server drops the
    // connection abnormally, triggering the reconnection.
    check firstSubscription.close();

    record {}[] secondStreamEvents = [];
    check from record {} response in secondSubscription
        do {
            secondStreamEvents.push(response);
        };
    test:assertEquals(secondStreamEvents, <json[]>[{data: {seq: 2}}],
            "Expected the remaining subscription to resume after the reconnection");

    string[] resubscribedIds;
    lock {
        resubscribedIds = mockSelectiveSecondConnectionIds.clone();
    }
    test:assertEquals(resubscribedIds, ["op-b"], "Expected only the remaining operation to be resubscribed");
    check graphqlClient->close();
}
