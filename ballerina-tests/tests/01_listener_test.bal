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
    groups: ["listener", "configs"]
}
function testInvalidMaxQueryDepth() returns error? {
    graphql:Error? result = wrappedListener.attach(invalidMaxQueryDepthService, "invalid");
    test:assertTrue(result is graphql:Error);
    graphql:Error err = <graphql:Error>result;
    test:assertEquals(err.message(), "Max query depth value must be a positive integer");
}

@test:Config {
    groups: ["listener"]
}
function testAttachServiceWithQueryToHttp2BasedListener() returns error? {
    string document = string `query { person{ age } }`;
    string url = "http://localhost:9190/service_with_http2";
    json actualPayload = check getJsonPayloadFromService(url, document);
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
    groups: ["listener"]
}
function testAttachServiceWithMutationToHttp2BasedListener() returns error? {
    string document = string `mutation { setName(name: "Heisenberg") { name } }`;
    string url = "http://localhost:9190/service_with_http2";
    json actualPayload = check getJsonPayloadFromService(url, document);
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
    groups: ["listener"]
}
function testAttachServiceWithQueryToHttp1BasedListener() returns error? {
    string document = string `query { person{ age } }`;
    string url = "http://localhost:9191/service_with_http1";
    json actualPayload = check getJsonPayloadFromService(url, document);
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
    groups: ["listener"]
}
function testAttachServiceWithMutationToHttp1BasedListener() returns error? {
    string document = string `mutation { setName(name: "Heisenberg") { name } }`;
    string url = "http://localhost:9191/service_with_http1";
    json actualPayload = check getJsonPayloadFromService(url, document);
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
    groups: ["listener", "client"]
}
function testAttachServiceWithQueryToHttp1BasedListenerAndClient() returns error? {
    string document = string `query { person{ age } }`;
    string url = "http://localhost:9191/service_with_http1";
    json actualPayload = check getJsonPayloadFromService(url, document, httpVersion = http:HTTP_1_0);
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
    json actualPayload = check getJsonPayloadFromService(url, document, httpVersion = http:HTTP_1_0);
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
    groups: ["listener"]
}
function testAttachServiceWithSubscriptionToHttp1BasedListener() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9191/service_with_http1";
    websocket:Client wsClient1 = check new(url);
    websocket:Client wsClient2 = check new(url);
    check writeWebSocketTextMessage(document, wsClient1);
    check writeWebSocketTextMessage(document, wsClient2);
    foreach int i in 1 ..< 4 {
        json expectedPayload = {data: {messages: i}};
        check validateWebSocketResponse(wsClient1, expectedPayload);
        check validateWebSocketResponse(wsClient2, expectedPayload);
    }
}

@test:Config {
    groups: ["listener", "service", "annotations"]
}
function testServiceWithOtherAnnotations() returns error? {
    string document = string `query { greeting }`;
    string url = "http://localhost:9090/annotations";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            greeting: "Hello"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
