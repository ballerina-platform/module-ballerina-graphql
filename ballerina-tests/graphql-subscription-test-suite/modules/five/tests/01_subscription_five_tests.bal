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
import ballerina/http;
import ballerina/test;

type MessagesResponse record {|
    record {| int messages; |} data;
|};

@test:Config {
    groups: ["listener", "subscriptions"]
}
function testAttachServiceWithSubscriptionToHttp2BasedListener() returns error? {
    http:Listener http2Listener = check new http:Listener(9090);
    graphql:Listener http2BasedListener = check new (http2Listener);
    graphql:Error? result = http2BasedListener.attach(subscriptionService);
    test:assertTrue(result is graphql:Error);
    graphql:Error err = <graphql:Error>result;
    string expectedMessage = "GraphQL subscriptions are only supported over HTTP/1.1 or HTTP/1.0. Found 2.0";
    test:assertEquals(err.message(), expectedMessage);
}

@test:Config {
    groups: ["listener", "subscriptions"]
}
function testAttachServiceWithSubscriptionToHttp1BasedListener() returns error? {
    string document = string `subscription { messages }`;
    string url = "http://localhost:9091/service_with_http1";

    graphql:Client graphqlClient1 = check new (url);
    stream<MessagesResponse, graphql:ClientError?> messages1 = check graphqlClient1->subscribe(document);
    graphql:Client graphqlClient2 = check new (url);
    stream<MessagesResponse, graphql:ClientError?> messages2 = check graphqlClient2->subscribe(document);

    foreach int i in 1 ..< 4 {
        record {|MessagesResponse value;|}|graphql:ClientError? event1 = messages1.next();
        test:assertTrue(event1 is record {|MessagesResponse value;|}, "Expected a messages event from the first client");
        if event1 is record {|MessagesResponse value;|} {
            test:assertEquals(event1.value.data.messages, i);
        }
        record {|MessagesResponse value;|}|graphql:ClientError? event2 = messages2.next();
        test:assertTrue(event2 is record {|MessagesResponse value;|}, "Expected a messages event from the second client");
        if event2 is record {|MessagesResponse value;|} {
            test:assertEquals(event2.value.data.messages, i);
        }
    }
    check graphqlClient1->close();
    check graphqlClient2->close();
}
