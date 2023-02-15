// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/websocket;

@test:Config {
    groups: ["listener", "client"]
}
function testAttachingGraphQLServiceToDynamicListener() returns error? {
    check specialTypesTestListener.attach(greetingService, "greet");
    string url = "http://localhost:9095/greet";
    string document = string `query { greeting }`;
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            greeting: "Hello, World"
        }
    };
    check specialTypesTestListener.detach(greetingService);
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["listener", "client"]
}
function testAttachingGraphQLServiceWithAnnotationToDynamicListener() returns error? {
    check specialTypesTestListener.attach(greetingService2, "greet");
    string url = "http://localhost:9095/greet";
    string document = string `query { greeting }`;
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            greeting: "Hello, World"
        }
    };
    check specialTypesTestListener.detach(greetingService2);
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["listener"],
    dataProvider: dataProviderListener
}
function testListener(string url, string documentFileName) returns error? {
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderListener() returns string[][] {
    string url1 = "http://localhost:9190/service_with_http2";
    string url2 = "http://localhost:9191/service_with_http1";
    string url3 = "http://localhost:9090/annotations";
    return [
        [url1, "attach_service_with_query_to_http2_based_listener"],
        [url1, "attach_service_with_mutation_to_http2_based_listener"],
        [url2, "attach_service_with_query_to_http1_based_listener"],
        [url2, "attch_service_with_mutation_to_http1_based_listener"],
        [url3, "service_with_other_annotations"]
    ];
}

@test:Config {
    groups: ["listener"]
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
    groups: ["listener", "client"]
}
function testAttachServiceWithQueryToHttp1BasedListenerAndClient() returns error? {
    string document = string `query { person{ age } }`;
    string url = "http://localhost:9191/service_with_http1";
    json actualPayload = check getJsonPayloadUsingHttpClient(url, document, httpVersion = http:HTTP_1_0);
    json expectedPayload = {
        data: {
            person: {
                age: 50
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["listener", "client"]
}
function testAttachServiceWithMutationToHttp1BasedListenerAndClient() returns error? {
    string document = string `mutation { setName(name: "Heisenberg") { name } }`;
    string url = "http://localhost:9191/service_with_http1";
    json actualPayload = check getJsonPayloadUsingHttpClient(url, document, httpVersion = http:HTTP_1_0);
    json expectedPayload = {
        data: {
            setName: {
                name: "Heisenberg"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["listener", "subscriptions"]
}
function testAttachServiceWithSubscriptionToHttp1BasedListener() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9191/service_with_http1";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient1);
    check sendSubscriptionMessage(wsClient1, document, "1");

    websocket:Client wsClient2 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient2);
    check sendSubscriptionMessage(wsClient2, document, "2");

    foreach int i in 1 ..< 4 {
        json expectedMsgPayload = {data: {messages: i}};
        check validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        check validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    }
}
