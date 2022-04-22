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

@test:Config {
    groups: ["listener", "graphiql"]
}
function testInvalidGraphiqlPath1() returns error? {
    graphql:Error? result = wrappedListener.attach(invalidGraphiqlPathConfigService1, "graphiql1");
    test:assertTrue(result is graphql:Error);
    graphql:Error err = <graphql:Error>result;
    test:assertEquals(err.message(), "Invalid path provided for GraphiQL client");
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testInvalidGraphiqlPath2() returns error? {
    graphql:Error? result = wrappedListener.attach(invalidGraphiqlPathConfigService2, "graphiql2");
    test:assertTrue(result is graphql:Error);
    graphql:Error err = <graphql:Error>result;
    test:assertEquals(err.message(), "Invalid path provided for GraphiQL client");
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiqlWithSamePathAsGraphQLService() returns error? {
    graphql:Error? result = basicListener.attach(graphiqlConfigService, "ballerina/graphiql");
    test:assertTrue(result is graphql:Error);
    graphql:Error err = <graphql:Error>result;
    test:assertEquals(err.message(), "Error occurred while attaching the GraphiQL endpoint");
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiqlPathWhenClientDisabled() returns error? {
    graphql:Error? result = wrappedListener.attach(invalidGraphiqlPathConfigService3, "clientDisabled");
    test:assertFalse(result is graphql:Error);
    result = wrappedListener.detach(invalidGraphiqlPathConfigService3);
    test:assertFalse(result is graphql:Error);
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiqlDefaultPath() returns error? {
    graphql:Error? result = wrappedListener.attach(graphiqlDefaultPathConfigService, ["graphql", "/\\ballerina"]);
    test:assertFalse(result is graphql:Error);
    string url = "http://localhost:9090";
    http:Client httpClient = check new(url);
    http:Response|error response = httpClient->get("/graphiql");
    test:assertFalse(response is error);
    http:Response graphiqlResponse = check response;
    test:assertEquals(graphiqlResponse.getContentType(), CONTENT_TYPE_TEXT_HTML);
    result = wrappedListener.detach(graphiqlDefaultPathConfigService);
    test:assertFalse(result is graphql:Error);
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiql() returns error? {
    graphql:Error? result = wrappedListener.attach(graphiqlConfigService, "/ballerina-graphql");
    test:assertFalse(result is graphql:Error);
    string url = "http://localhost:9090";
    http:Client httpClient = check new(url);
    http:Response|error response = httpClient->get("/ballerina/graphiql");
    test:assertFalse(response is error);
    http:Response graphiqlResponse = check response;
    test:assertEquals(graphiqlResponse.getContentType(), CONTENT_TYPE_TEXT_HTML);
    result = wrappedListener.detach(graphiqlConfigService);
    test:assertFalse(result is graphql:Error);
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiqlWithDefaultBasePath() returns error? {
    graphql:Error? result = basicListener.attach(graphiqlDefaultPathConfigService);
    test:assertFalse(result is graphql:Error);
    string url = "http://localhost:9091";
    http:Client httpClient = check new(url);
    http:Response|error response = httpClient->get("/graphiql");
    test:assertFalse(response is error);
    http:Response graphiqlResponse = check response;
    test:assertEquals(graphiqlResponse.getContentType(), CONTENT_TYPE_TEXT_HTML);
    result = basicListener.detach(graphiqlDefaultPathConfigService);
    test:assertFalse(result is graphql:Error);
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiql1() returns error? {
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
function testGraphiql2() returns error? {
    string url = "http://localhost:9092/";
    http:Client httpClient = check new(url);
    http:Response|error response = httpClient->get("graphiql");
    test:assertFalse(response is error);
    http:Response graphiqlResponse = check response;
    test:assertEquals(graphiqlResponse.getContentType(), CONTENT_TYPE_TEXT_HTML);
}
