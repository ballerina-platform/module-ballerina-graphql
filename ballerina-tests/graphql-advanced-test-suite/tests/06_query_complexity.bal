// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/graphql_test_common as common;
import ballerina/test;

@test:Config {
    groups: ["query_complexity"]
}
isolated function testValidComplexityQuery() returns error? {
    string url = "http://localhost:9090/complexity";
    string document = check common:getGraphqlDocumentFromFile("valid_complexity_query");
    string resourceFileName = "valid_complexity_query";
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    json expectedPayload = check common:getJsonContentFromFile(resourceFileName);
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["query_complexity"]
}
isolated function testInvalidComplexityQuery() returns error? {
    string url = "http://localhost:9090/complexity";
    string document = check common:getGraphqlDocumentFromFile("invalid_complexity_query");
    string resourceFileName = "invalid_complexity_query";
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    json expectedPayload = check common:getJsonContentFromFile(resourceFileName);
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["query_complexity"]
}
isolated function testPrimitiveTypeFieldComplexity() returns error? {
    string url = "http://localhost:9090/complexity";
    string document = "{ greeting }";
    json expectedPayload = {"data": {"greeting": "Hello"}};
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["query_complexity"]
}
isolated function testComplexityWithUnionTypes() returns error? {
    string url = "http://localhost:9090/complexity";
    string document = check common:getGraphqlDocumentFromFile("complexity_with_union_types");
    json expectedPayload = check common:getJsonContentFromFile("complexity_with_union_types");
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["query_complexity"]
}
isolated function testComplexityWithMutation() returns error? {
    string url = "http://localhost:9090/complexity";
    string document = check common:getGraphqlDocumentFromFile("complexity_with_mutation");
    json expectedPayload = check common:getJsonContentFromFile("complexity_with_mutation");
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["query_complexity", "introspection"]
}
isolated function testGraphqlPlaygroundIntrospectionQueryWithComplexityVaildation() returns error? {
    string url = "http://localhost:9090/complexity";
    string document = check common:getGraphqlDocumentFromFile("graphql_playground_introspection_query");
    json expectedPayload = check common:getJsonContentFromFile("graphql_playground_introspection_query_with_complexity_validation");
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
