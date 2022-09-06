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
import ballerina/test;
import ballerina/lang.runtime;

@test:Config {
    groups: ["listener", "configs"]
}
function testInvalidMaxQueryDepth() returns error? {
    graphql:Error? result = wrappedListener.attach(invalidMaxQueryDepthService, "invalid");
    test:assertTrue(result is graphql:Error);
    graphql:Error err = <graphql:Error>result;
    test:assertEquals(err.message(), "Max query depth value must be a positive integer");
}

graphql:Service greetingService = service object {
    resource function get greeting() returns string {
        return "Hello, World";
    }
};

@test:Config {
    groups: ["listener", "client"]
}
function testAttachingGraphQLServiceToDynamicListener() returns error? {
    graphql:Listener serverEP = check new (9600);
    check serverEP.attach(greetingService, "greet");
    check serverEP.'start();
    runtime:registerListener(serverEP);

    string url = "http://localhost:9600/greet";
    string document = string `query { greeting }`;
    graphql:Client graphqlClient = check new (url);
    GenericGreetingResponseWithErrors actualPayload = check graphqlClient->execute(document);
    GenericGreetingResponseWithErrors expectedPayload = {
        data: {
            greeting: "Hello, World"
        }
    };
    runtime:deregisterListener(serverEP);
    test:assertEquals(actualPayload, expectedPayload);
}

graphql:Service greetingService2 = @graphql:ServiceConfig {maxQueryDepth: 5} service object {
    resource function get greeting() returns string {
        return "Hello, World";
    }
};

@test:Config {
    groups: ["listener", "client"]
}
function testAttachingGraphQLServiceWithAnnotationToDynamicListener() returns error? {
    graphql:Listener serverEP = check new (9601);
    check serverEP.attach(greetingService2, "greet");
    check serverEP.'start();
    runtime:registerListener(serverEP);

    string url = "http://localhost:9601/greet";
    string document = string `query { greeting }`;
    graphql:Client graphqlClient = check new (url);
    GenericGreetingResponseWithErrors actualPayload = check graphqlClient->execute(document);
    GenericGreetingResponseWithErrors expectedPayload = {
        data: {
            greeting: "Hello, World"
        }
    };
    runtime:deregisterListener(serverEP);
    test:assertEquals(actualPayload, expectedPayload);
}
