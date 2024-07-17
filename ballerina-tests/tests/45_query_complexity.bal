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

import ballerina/test;

@test:Config {
    groups: ["query_complexity"]
}
isolated function testValidComplexityQuery() returns error? {
    string url = "http://localhost:9090/reviews";
    string document = check getGraphqlDocumentFromFile("complexity");
    string resourceFileName = "valid_complexity_query";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "SimpleQuery");
    json expectedPayload = check getJsonContentFromFile(resourceFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["query_complexity"]
}
isolated function testInvalidComplexityQuery() returns error? {
    string url = "http://localhost:9090/reviews";
    string document = check getGraphqlDocumentFromFile("complexity");
    string resourceFileName = "invalid_complexity_query";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "ComplexQuery");
    json expectedPayload = check getJsonContentFromFile(resourceFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["query_complexity"]
}
isolated function testPrimitiveTypeFieldComplexity() returns error? {
    string url = "http://localhost:9090/annotations";
    string document = "{ greeting }";
    json expectedPayload = { "data": { "greeting": "Hello" } };
    json actualPayload = check getJsonPayloadFromService(url, document);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
