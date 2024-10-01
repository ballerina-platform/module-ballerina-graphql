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
import ballerina/graphql_test_common as common;
import ballerina/http;
import ballerina/test;

@test:Config {
    groups: ["listener", "client"]
}
function testAttachingGraphQLServiceToDynamicListener() returns error? {
    check wrappedListener.attach(greetingService, "greet");
    string url = "http://localhost:9090/greet";
    string document = string `query { greeting }`;
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            greeting: "Hello, World"
        }
    };
    check wrappedListener.detach(greetingService);
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["listener", "client"]
}
function testAttachingGraphQLServiceWithAnnotationToDynamicListener() returns error? {
    check wrappedListener.attach(greetingService2, "greeting");
    string url = "http://localhost:9090/greeting";
    string document = string `query { greeting }`;
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            greeting: "Hello, World"
        }
    };
    check wrappedListener.detach(greetingService2);
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["listener"],
    dataProvider: dataProviderListener
}
function testListener(string url, string resourceFileName) returns error? {
    string document = check common:getGraphqlDocumentFromFile(resourceFileName);
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    json expectedPayload = check common:getJsonContentFromFile(resourceFileName);
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderListener() returns string[][] {
    string url1 = "http://localhost:9095/service_with_http2";
    string url2 = "http://localhost:9090/service_with_http1";
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
    groups: ["listener", "client"]
}
function testAttachServiceWithQueryToHttp1BasedListenerAndClient() returns error? {
    string document = string `query { person{ age } }`;
    string url = "http://localhost:9090/service_with_http1";
    json actualPayload = check common:getJsonPayloadUsingHttpClient(url, document, httpVersion = http:HTTP_1_0);
    json expectedPayload = {
        data: {
            person: {
                age: 50
            }
        }
    };
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["listener", "client"]
}
function testAttachServiceWithMutationToHttp1BasedListenerAndClient() returns error? {
    string document = string `mutation { setName(name: "Heisenberg") { name } }`;
    string url = "http://localhost:9090/service_with_http1";
    json actualPayload = check common:getJsonPayloadUsingHttpClient(url, document, httpVersion = http:HTTP_1_0);
    json expectedPayload = {
        data: {
            setName: {
                name: "Heisenberg"
            }
        }
    };
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["listener", "service_object"]
}
function testServiceDeclarationUsingLocalServiceObject() returns error? {
    graphql:Service localService = service object {
        resource function get greeting() returns string {
            return "Hello world";
        }
    };
    check basicListener.attach(localService, "/local_service_object");

    string url = "http://localhost:9091/local_service_object";
    string document = string `query { greeting }`;
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            greeting: "Hello world"
        }
    };
    check basicListener.detach(localService);
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["listener", "service_object"]
}
function testServiceDeclarationUsingObjectField() returns error? {
    graphql:Service localService = (new ServiceDeclarationOnObjectField()).getService();
    check basicListener.attach(localService, "/object_field_service_object");

    string url = "http://localhost:9091/object_field_service_object";
    string document = string `query { greeting }`;
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            greeting: "Hello world"
        }
    };
    check basicListener.detach(localService);
    test:assertEquals(actualPayload, expectedPayload);
}
