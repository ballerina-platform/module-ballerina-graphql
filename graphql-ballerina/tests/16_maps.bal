// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

@test:Config {
    groups: ["map"]
}
isolated function testMap() returns error? {
    string document = string`query { company { workers(key: "id1") { name } } }`;
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            company: {
                workers: {
                    name: "John Doe"
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["map"]
}
isolated function testNestedMap() returns error? {
    string document = string`query { company { workers(key: "id3") { contacts(key: "home") { number } } } }`;
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            company: {
                workers: {
                    contacts: {
                        number: "+94771234567"
                    }
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["map"]
}
isolated function testMapWithoutKeyInput() returns error? {
    string document = string`query { company { workers { name } } }`;
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    string message = string`Field "workers" argument "key" of type "String!" is required, but it was not provided.`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 1,
                        column: 19
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["map"]
}
isolated function testNestedMapWithoutKeyInput() returns error? {
    string document = string`query { company { workers(key: "w1") { contacts } } }`;
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("nested_map_without_key_input.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
