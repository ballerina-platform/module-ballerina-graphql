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
    groups: ["mutations", "validation"]
}
isolated function testMutationRequestOnNonMutatableSchema() returns error? {
    string document = string`mutation { setName(name: "Heisenberg") { name } }`;
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "Schema is not configured for mutations.",
                locations: [
                    {
                        line: 1,
                        column: 1
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["mutations"]
}
isolated function testMutation() returns error? {
    string document = string`mutation { setName(name: "Heisenberg") { name } }`;
    string url = "http://localhost:9091/mutations";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            setName: {
                name: "Heisenberg"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["mutations"]
}
isolated function testMultipleMutations() returns error? {
    string document = check getGraphQLDocumentFromFile("multiple_mutations.graphql");
    string url = "http://localhost:9091/mutations";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("multiple_mutations.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["mutations"]
}
isolated function testInvalidMutation() returns error? {
    string document = string`mutation { setAge }`;
    string url = "http://localhost:9091/mutations";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Cannot query field "setAge" on type "Mutation".`,
                locations: [
                    {
                        line: 1,
                        column: 12
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["mutations"]
}
isolated function testMultipleMutationsOnServiceObjects() returns error? {
    string document = check getGraphQLDocumentFromFile("multiple_mutations_on_service_objects.graphql");
    string url = "http://localhost:9091/mutations";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("multiple_mutations_on_service_objects.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
