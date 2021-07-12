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

import ballerina/test;
import ballerina/http;
import ballerina/url;

@test:Config {
    groups: ["runtime_errors"]
}
isolated function testRuntimeError() returns error? {
    string graphqlUrl = "http://localhost:9091/records";
    string document = "{ profile (id: 10) { name } }";
    http:Client httpClient = check new(graphqlUrl);
    http:Response response = check httpClient->post("/", { query: document });
    test:assertEquals(response.statusCode, 200);
    json actualPayload = check response.getJsonPayload();

    string expectedMessage = "{ballerina/lang.array}IndexOutOfRange";
    json expectedPayload = {
        errors: [
            {
                message: expectedMessage,
                locations: [
                    {
                        line: 1,
                        column: 3
                    }
                ],
                path: ["profile"]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["runtime_errors"]
}
isolated function testRuntimeErrorWithGetRequest() returns error? {
    string graphqlUrl = "http://localhost:9091";
    string document = "{ profile (id: 10) { name } }";
    string encodedDocument = check url:encode(document, "UTF-8");
    http:Client httpClient = check new(graphqlUrl);
    string path = "/records?query=" + encodedDocument;
    http:Response response = check httpClient->get(path);
    test:assertEquals(response.statusCode, 200);
    json actualPayload = check response.getJsonPayload();

    string expectedMessage = "{ballerina/lang.array}IndexOutOfRange";
    json expectedPayload = {
        errors: [
            {
                message: expectedMessage,
                locations: [
                    {
                        line: 1,
                        column: 3
                    }
                ],
                path: ["profile"]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
