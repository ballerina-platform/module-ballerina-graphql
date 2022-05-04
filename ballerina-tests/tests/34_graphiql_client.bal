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
    graphql:Error? result = basicListener.attach(invalidGraphiqlPathConfigService1, "graphiql1");
    test:assertTrue(result is graphql:Error);
    graphql:Error err = <graphql:Error>result;
    test:assertEquals(err.message(), "Invalid path provided for GraphiQL client");
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testInvalidGraphiqlPath2() returns error? {
    graphql:Error? result = basicListener.attach(invalidGraphiqlPathConfigService2, "graphiql2");
    test:assertTrue(result is graphql:Error);
    graphql:Error err = <graphql:Error>result;
    test:assertEquals(err.message(), "Invalid path provided for GraphiQL client");
}

@test:Config {
    groups: ["listener", "graphiql"],
    enable: false
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
    string url = "http://localhost:9091";
    http:Client httpClient = check new(url);
    http:Response|error response = httpClient->get("/ballerina graphql");
    test:assertFalse(response is error);
    http:Response graphiqlResponse = check response;
    // 'text/plain' is the content type received when the service is not running.
    test:assertEquals(graphiqlResponse.getContentType(), CONTENT_TYPE_TEXT_PLAIN);
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiqlDefaultPath() returns error? {
    string url = "http://localhost:9091";
    http:Client httpClient = check new(url);
    http:Response|error response = httpClient->get("/graphiql");
    test:assertFalse(response is error);
    http:Response graphiqlResponse = check response;
    test:assertEquals(graphiqlResponse.getContentType(), CONTENT_TYPE_TEXT_HTML);
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiql() returns error? {
    string url = "http://localhost:9091";
    http:Client httpClient = check new(url);
    http:Response|error response = httpClient->get("/ballerina/graphiql");
    test:assertFalse(response is error);
    http:Response graphiqlResponse = check response;
    test:assertEquals(graphiqlResponse.getContentType(), CONTENT_TYPE_TEXT_HTML);
}

@test:Config {
    groups: ["listener", "graphiql"]
}
function testGraphiqlWithDefaultBasePath() returns error? {
    string url = "http://localhost:9092";
    http:Client httpClient = check new(url);
    http:Response|error response = httpClient->get("/graphiql");
    test:assertFalse(response is error);
    http:Response graphiqlResponse = check response;
    test:assertEquals(graphiqlResponse.getContentType(), CONTENT_TYPE_TEXT_HTML);
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
