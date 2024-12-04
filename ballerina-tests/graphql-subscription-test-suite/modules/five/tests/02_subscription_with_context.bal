// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com).
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

import ballerina/graphql_test_common as common;
import ballerina/test;
import ballerina/websocket;

@test:Config {
    enable: false,
    groups: ["context", "subscriptions"]
}
isolated function testContextWithSubscriptions() returns error? {
    string url = "ws://localhost:9091/context";
    string document = string `subscription { messages }`;
    websocket:ClientConfiguration configs = {
        customHeaders: {
            "scope": "admin"
        },
        subProtocols: [common:GRAPHQL_TRANSPORT_WS]
    };
    websocket:Client wsClient = check new (url, configs);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document);
    foreach int i in 1 ..< 4 {
        json expectedMsgPayload = {data: {messages: i}};
        check common:validateNextMessage(wsClient, expectedMsgPayload);
    }
}

@test:Config {
    enable: false,
    groups: ["context", "subscriptions"]
}
isolated function testContextWithInvalidScopeInSubscriptions() returns error? {
    string url = "ws://localhost:9091/context";
    string document = string `subscription { messages }`;
    websocket:ClientConfiguration configs = {
        customHeaders: {
            "scope": "user"
        },
        subProtocols: [common:GRAPHQL_TRANSPORT_WS]
    };
    websocket:Client wsClient = check new (url, configs);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document);
    json expectedErrorPayload = [
        {
            message: "You don't have permission to retrieve data",
            locations: [{line: 1, column: 16}],
            path: ["messages"]
        }
    ];
    check common:validateErrorMessage(wsClient, expectedErrorPayload);
}
