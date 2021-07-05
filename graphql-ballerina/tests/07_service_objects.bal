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

@test:Config {
    groups: ["service"]
}
isolated function testResourceReturningServiceObject() returns error? {
    string graphqlUrl = "http://localhost:9092/service_types";
    string document = "{ greet { generalGreeting } }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

    json expectedPayload = {
        data: {
            greet: {
                generalGreeting: "Hello, world"
            }
        }
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["service", "validation"]
}
isolated function testInvalidQueryFromServiceObjectResource() returns error? {
    string graphqlUrl = "http://localhost:9092/service_types";
    string document = "{ profile { name { nonExisting } } }";
    json actualPayload = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedPayload = {
        errors: [
            {
                message: "Cannot query field \"nonExisting\" on type \"Name\".",
                locations: [
                    {
                        line: 1,
                        column: 20
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["service"]
}
isolated function testComplexService() returns error? {
    string graphqlUrl = "http://localhost:9092/service_types";
    string document = "{ profile { name { first, last } } }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

    json expectedPayload = {
        data: {
            profile: {
                name: {
                    first: "Sherlock",
                    last: "Holmes"
                }
            }
        }
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}
