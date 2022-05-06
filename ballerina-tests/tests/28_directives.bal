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
    groups: ["directives", "fragments", "input"]
}
isolated function testDirectives() returns error? {
    string document = check getGraphQLDocumentFromFile("directives.graphql");
    string url = "http://localhost:9092/service_types";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            profile: {
                name: {
                    last: "Holmes"
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["directives", "input"]
}
isolated function testUnknownDirectives() returns error? {
    string document = check getGraphQLDocumentFromFile("unknown_directives.graphql");
    string url = "http://localhost:9092/service_types";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("unknown_directives.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
@test:Config {
    groups: ["directives", "input"]
}
isolated function testDirectivesInInvalidLocations1() returns error? {
    string document = check getGraphQLDocumentFromFile("directives_in_invalid_locations1.graphql");
    string url = "http://localhost:9092/service_types";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("directives_in_invalid_locations1.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["directives", "mutations", "input"]
}
isolated function testDirectivesInInvalidLocations2() returns error? {
    string document = string`mutation @skip(if: false){ setName(name: "Heisenberg") { name } }`;
    string url = "http://localhost:9091/mutations";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "Directive \"skip\" may not be used on MUTATION.",
                locations: [
                    {
                        line: 1,
                        column: 10
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["directives", "input"]
}
isolated function testDirectivesWithoutArgument() returns error? {
    string document = check getGraphQLDocumentFromFile("directives_without_argument.graphql");
    string url = "http://localhost:9092/service_types";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("directives_without_argument.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["directives", "input"]
}
isolated function testDirectivesWithUnknownArguments() returns error? {
    string document = check getGraphQLDocumentFromFile("directives_with_unknown_arguments.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("directives_with_unknown_arguments.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["directives", "fragments", "variables"]
}
isolated function testDirectivesWithVariablesAndFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("directives_with_variables_and_fragments.graphql");
    json variables = { optional: false  };
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data: {
            profile: {
                name: "Walter White",
                address: {
                    street: "Negra Arroyo Lane"
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["directives", "fragments", "variables"]
}
isolated function testDuplicateDirectivesInSameLocation() returns error? {
    string document = check getGraphQLDocumentFromFile("duplicate_directives_in_same_location.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("duplicate_directives_in_same_location.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["directives", "variables"]
}
isolated function testDirectivesWithDuplicateFields() returns error? {
    string document = check getGraphQLDocumentFromFile("directives_with_duplicate_fields.graphql");
    string url = "http://localhost:9091/records";
    json variables = { optional: false };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data: {
            profile: {
                name: "Walter White",
                address: {
                    number: "308"
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["directives", "array", "service"]
}
isolated function testDirectivesWithServiceReturningObjectsArray() returns error? {
    string graphqlUrl = "http://localhost:9092/service_objects";
    string document = string `{ searchVehicles(keyword: "vehicle") { ...on Vehicle { id @skip(if: true) } } }`;
    json actualPayload = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = {
        data: {
            searchVehicles: [
                {},
                {},
                {}
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["directives", "input"]
}
isolated function testDirectivesSkipAllSelections() returns error? {
    string document = string`query getData { profile(id: 1) @skip(if: true) { name } }`;
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {}
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["directives", "input"]
}
isolated function testMultipleDirectiveUsageInFields() returns error? {
    string document = check getGraphQLDocumentFromFile("multiple_directive_usage_in_fields.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            detective: {
                address: {
                    street: "Baker Street"
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
