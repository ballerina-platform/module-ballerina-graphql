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

import ballerina/file;
import ballerina/http;
import ballerina/io;
import ballerina/test;

isolated function getJsonPayloadFromService(string url, string document, string? operationName = ())
returns json|error {
    http:Client httpClient = check new(url);
    return httpClient->post("/", { query: document, operationName: operationName });
}

isolated function getJsonContentFromFile(string fileName) returns json|error {
    string path = check file:joinPath("tests", "resources", "expected_results", fileName);
    return io:fileReadJson(path);
}

isolated function getGraphQLDocumentFromFile(string fileName) returns string|error {
    string path = check file:joinPath("tests", "resources", "documents", fileName);
    return io:fileReadString(path);
}

isolated function getJsonPayloadFromBadRequest(string url, string document, string? operationName = ())
returns json|error {
    http:Client httpClient = check new(url);
    http:Response response = check httpClient->post("/", { query: document, operationName: operationName });
    assertResponseForBadRequest(response);
    return response.getJsonPayload();
}

isolated function getTextPayloadFromBadRequest(string url, http:Request request) returns string|error {
    http:Client httpClient = check new(url);
    http:Response response = check httpClient->post("/", request);
    assertResponseForBadRequest(response);
    return response.getTextPayload();
}

isolated function assertResponseForBadRequest(http:Response response) {
    test:assertEquals(response.statusCode, http:STATUS_BAD_REQUEST);
    test:assertEquals(response.reasonPhrase, "Bad Request");
}

isolated function assertJsonValuesWithOrder(json actualPayload, json expectedPayload) {
    string actual = actualPayload.toJsonString();
    string expected = expectedPayload.toJsonString();
    test:assertEquals(actual, expected);
}
