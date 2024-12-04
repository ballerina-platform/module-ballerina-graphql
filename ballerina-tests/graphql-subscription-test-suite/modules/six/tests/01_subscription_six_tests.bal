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

import ballerina/graphql_test_common as common;
import ballerina/test;
import ballerina/websocket;

@test:Config {
    enable: false,
    groups: ["subscriptions", "service"]
}
isolated function testConnectionClousureWhenPongNotRecived() returns error? {
    string url = "ws://localhost:9091/subscription_interceptor1";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient);
    json|error response;
    while true {
        response = wsClient->readMessage();
        if response is json {
            test:assertTrue(response.'type == common:WS_PING);
            continue;
        }
        break;
    }
    test:assertTrue(response is error, "Expected connection clousure error");
    test:assertEquals((<error>response).message(), "Request timeout: Status code: 4408");
}