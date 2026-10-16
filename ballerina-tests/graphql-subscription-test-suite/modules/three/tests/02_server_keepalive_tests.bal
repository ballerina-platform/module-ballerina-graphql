// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
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
import ballerina/graphql_test_common as common;
import ballerina/lang.runtime;
import ballerina/test;
import ballerina/websocket;

const string KEEPALIVE_SUBSCRIPTION_URL = "ws://localhost:9091/server_keepalive";

isolated class LongLivedGenerator {
    private boolean produced = false;

    public isolated function next() returns record {|int value;|}|error? {
        boolean alreadyProduced;
        lock {
            alreadyProduced = self.produced;
            self.produced = true;
        }
        if alreadyProduced {
            // A brief, bounded delay is enough to exercise keep-alive against a "slow" resolver.
            // A long block here (this used to be 10s) risks colliding with the server's own
            // keep-alive-triggered close attempt under CI-level scheduling contention, in which case
            // the peer's read can hang indefinitely rather than observing the connection close.
            runtime:sleep(0.05);
        }
        return {value: 1};
    }
}

@graphql:ServiceConfig {
    keepAlive: {pingInterval: 0.3, pongTimeout: 0.3}
}
service /server_keepalive on subscriptionListener {
    isolated resource function get name() returns string {
        return "Walter White";
    }

    isolated resource function subscribe longLived() returns stream<int, error?> {
        return new (new LongLivedGenerator());
    }
}

// A responsive client must not be disconnected by the server's keep-alive: several ping/pong
// cycles must pass with the connection still open.
@test:Config {
    groups: ["subscriptions"]
}
isolated function testServerKeepAliveToleratesResponsiveClient() returns error? {
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (KEEPALIVE_SUBSCRIPTION_URL, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, "subscription { longLived }");

    int pingsSeen = 0;
    while pingsSeen < 3 {
        json response = check wsClient->readMessage();
        if response.'type == common:WS_PING {
            pingsSeen += 1;
            check common:sendPongMessage(wsClient);
        }
    }
    check wsClient->close();
}

// A client that never responds to the server's ping must eventually be disconnected, tolerating
// isolated misses rather than closing on the first one.
@test:Config {
    groups: ["subscriptions"]
}
isolated function testServerKeepAliveClosesSilentClient() returns error? {
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (KEEPALIVE_SUBSCRIPTION_URL, config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, "subscription { longLived }");

    int pingsSeen = 0;
    json|error response;
    while true {
        response = wsClient->readMessage();
        if response is error {
            break;
        }
        if response.'type == common:WS_PING {
            pingsSeen += 1;
        }
    }
    test:assertTrue(pingsSeen > 1, "Expected the server to tolerate more than one missed pong before closing");
    test:assertEquals((<error>response).message(), "Request timeout: Status code: 4408");
}
