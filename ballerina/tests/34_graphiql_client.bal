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

import ballerina/test;
import ballerina/http;

@test:Config {
    groups: ["listener", "graphiql"]
}
function testInvalidGraphiQLPath1() returns error? {
    Error? result = wrappedListener.attach(invalidGraphiQLPathConfigService1, "graphiql1");
    test:assertTrue(result is Error);
    Error err = <Error>result;
    test:assertEquals(err.message(), "Invalid path provided for GraphiQL client");
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testInvalidGraphiQLPath2() returns error? {
    Error? result = wrappedListener.attach(invalidGraphiQLPathConfigService2, "graphiql2");
    test:assertTrue(result is Error);
    Error err = <Error>result;
    test:assertEquals(err.message(), "Invalid path provided for GraphiQL client");
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiQLWithSamePathAsGraphQLService() returns error? {
    Error? result = basicListener.attach(graphiQLConfigService, "ballerina/graphiql");
    test:assertTrue(result is Error);
    Error err = <Error>result;
    test:assertEquals(err.message(), "Error occurred while attaching the GraphiQL endpoint");
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiQLPathWhenClientDisabled() returns error? {
    Error? result = wrappedListener.attach(invalidGraphiQLPathConfigService3, "clientDisabled");
    test:assertFalse(result is Error);
    result = wrappedListener.detach(invalidGraphiQLPathConfigService3);
    test:assertFalse(result is Error);
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiQLDefaultPath() returns error? {
    Error? result = wrappedListener.attach(graphiQLDefaultPathConfigService, ["graphql", "/\\ballerina"]);
    test:assertFalse(result is Error);
    string url = "http://localhost:9090";
    http:Client httpClient = check new(url);
    http:Response|error response = httpClient->get("/graphiql");
    test:assertFalse(response is error);
    http:Response graphiqlResponse = check response;
    test:assertEquals(graphiqlResponse.getContentType(), CONTENT_TYPE_TEXT_HTML);
    result = wrappedListener.detach(graphiQLDefaultPathConfigService);
    test:assertFalse(result is Error);
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiQL() returns error? {
    Error? result = wrappedListener.attach(graphiQLConfigService, "/ballerina-graphql");
    test:assertFalse(result is Error);
    string url = "http://localhost:9090";
    http:Client httpClient = check new(url);
    http:Response|error response = httpClient->get("/ballerina/graphiql");
    test:assertFalse(response is error);
    http:Response graphiqlResponse = check response;
    test:assertEquals(graphiqlResponse.getContentType(), CONTENT_TYPE_TEXT_HTML);
    result = wrappedListener.detach(graphiQLConfigService);
    test:assertFalse(result is Error);
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiQLWithDefaultBasePath() returns error? {
    Error? result = basicListener.attach(graphiQLDefaultPathConfigService);
    test:assertFalse(result is Error);
    string url = "http://localhost:9091";
    http:Client httpClient = check new(url);
    http:Response|error response = httpClient->get("/graphiql");
    test:assertFalse(response is error);
    http:Response graphiqlResponse = check response;
    test:assertEquals(graphiqlResponse.getContentType(), CONTENT_TYPE_TEXT_HTML);
    result = basicListener.detach(graphiQLDefaultPathConfigService);
    test:assertFalse(result is Error);
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiQL1() returns error? {
    string url = "http://localhost:9091/";
    http:Client httpClient = check new(url);
    http:Response|error response = httpClient->get("graphiql/interface");
    test:assertFalse(response is error);
    http:Response graphiqlResponse = check response;
    test:assertEquals(graphiqlResponse.getContentType(), CONTENT_TYPE_TEXT_HTML);
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiQL2() returns error? {
    string url = "http://localhost:9092/";
    http:Client httpClient = check new(url);
    http:Response|error response = httpClient->get("graphiql");
    test:assertFalse(response is error);
    http:Response graphiqlResponse = check response;
    test:assertEquals(graphiqlResponse.getContentType(), CONTENT_TYPE_TEXT_HTML);
}
