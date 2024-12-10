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

@test:Config {
    groups: ["listener", "subscriptions"]
}
function testAttachServiceWithSubscriptionToHttp2BasedListener() returns error? {
    graphql:Error? result = http2BasedListener.attach(subscriptionService);
    test:assertTrue(result is graphql:Error);
    graphql:Error err = <graphql:Error>result;
    string expecctedMessage = string `Websocket listener initialization failed due to the incompatibility of ` +
                            string `provided HTTP(version 2.0) listener`;
    test:assertEquals(err.message(), expecctedMessage);
}

@test:Config {
    groups: ["listener", "subscriptions"]
}
function testAttachServiceWithSubscriptionToHttp1BasedListener() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9091/service_with_http1";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient1);
    check common:sendSubscriptionMessage(wsClient1, document, "1");

    websocket:Client wsClient2 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient2);
    check common:sendSubscriptionMessage(wsClient2, document, "2");

    foreach int i in 1 ..< 4 {
        json expectedMsgPayload = {data: {messages: i}};
        check common:validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        check common:validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    }
}
