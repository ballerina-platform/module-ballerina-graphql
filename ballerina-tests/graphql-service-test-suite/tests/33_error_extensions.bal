// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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
    groups: ["error_extensions"]
}
isolated function testServiceErrorWithExtensions() returns error? {
    string url = "http://localhost:9091/error_extensions";
    string document = "{ book(id: 7) }";
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "Book 7 not found",
                locations: [{line: 1, column: 3}],
                path: ["book"],
                extensions: {code: "NOT_FOUND", id: 7}
            }
        ],
        data: null
    };
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["error_extensions"]
}
isolated function testErrorWithExtensionsInDetail() returns error? {
    string url = "http://localhost:9091/error_extensions";
    string document = "{ author }";
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "Author not found",
                locations: [{line: 1, column: 3}],
                path: ["author"],
                extensions: {code: "NOT_FOUND"}
            }
        ],
        data: null
    };
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["error_extensions"]
}
isolated function testNestedFieldErrorWithExtensions() returns error? {
    string url = "http://localhost:9091/error_extensions";
    string document = "{ account(id: 1) { id balance } }";
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "Balance is not available",
                locations: [{line: 1, column: 23}],
                path: ["account", "balance"],
                extensions: {code: "UNAVAILABLE", retryable: true}
            }
        ],
        data: {
            account: {id: 1, balance: null}
        }
    };
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["error_extensions"]
}
isolated function testRemoteFunctionErrorWithExtensions() returns error? {
    string url = "http://localhost:9091/error_extensions";
    string document = string `mutation { addBook(title: "Dune") }`;
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "Book already exists",
                locations: [{line: 1, column: 12}],
                path: ["addBook"],
                extensions: {code: "CONFLICT", title: "Dune"}
            }
        ],
        data: null
    };
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["error_extensions"]
}
isolated function testErrorWithoutExtensions() returns error? {
    string url = "http://localhost:9091/error_extensions";
    string document = "{ publisher }";
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "Publisher not found",
                locations: [{line: 1, column: 3}],
                path: ["publisher"]
            }
        ],
        data: null
    };
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
