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
    groups: ["listener", "graphiql"],
    dataProvider: dataProviderGraphiqlClient
}
function testGraphiqlClientTest(string url, string path, string contentType) returns error? {
    http:Client httpClient = check new(url, httpVersion = "1.1");
    http:Response|error response = httpClient->get(path);
    test:assertFalse(response is error);
    http:Response graphiqlResponse = check response;
    test:assertEquals(graphiqlResponse.getContentType(), contentType);
}

function dataProviderGraphiqlClient() returns string[][] {
    string url1 = "http://localhost:9091";
    string url2 = "http://localhost:9092";

    return [
        [url1, "/ballerina graphql", CONTENT_TYPE_TEXT_PLAIN],
        [url1, "/graphiql", CONTENT_TYPE_TEXT_HTML],
        [url1, "/ballerina/graphiql", CONTENT_TYPE_TEXT_HTML],
        [url2, "/graphiql", CONTENT_TYPE_TEXT_HTML],
        [url1, "/graphiql/interface", CONTENT_TYPE_TEXT_HTML]
    ];
}
