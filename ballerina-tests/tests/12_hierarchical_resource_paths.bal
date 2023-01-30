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
    groups: ["hierarchical_paths"]
}
isolated function testHierarchicalResourcePaths() returns error? {
    string document = "{ profile { name { first } } }";
    string url = "http://localhost:9094/profiles";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            profile: {
                name: {
                    first: "Sherlock"
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["hierarchical_paths"]
}
isolated function testHierarchicalResourcePathsMultipleFields() returns error? {
    string document = "{ profile { name { first last } } }";
    string url = "http://localhost:9094/profiles";
    json actualPayload = check getJsonPayloadFromService(url, document);
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
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["hierarchical_paths"]
}
isolated function testHierarchicalResourcePathsComplete() returns error? {
    string document = "{ profile { name { first last } age } }";
    string url = "http://localhost:9094/profiles";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            profile: {
                name: {
                    first: "Sherlock",
                    last: "Holmes"
                },
                age: 40
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["hierarchical_paths"]
}
isolated function testHierarchicalPathsSameTypeInMultiplePaths() returns error? {
    string document = "{ profile { name { address { street } } } }";
    string url = "http://localhost:9094/profiles";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = { data: null };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["negative", "hierarchical_paths"]
}
isolated function testInvalidHierarchicalResourcePaths() returns error? {
    string document = "{ profile { name { first middle } } }";
    string url = "http://localhost:9094/profiles";
    json actualPayload = check getJsonPayloadFromService(url, document);

    string expectedErrorMessage = "Cannot query field \"middle\" on type \"name\".";
    json expectedPayload = {
        errors: [
            {
                message: expectedErrorMessage,
                locations: [
                    {
                        line: 1,
                        column: 26
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["introspection", "hierarchical_paths"]
}
isolated function testHierarchicalResourcePathsIntrospection() returns error? {
    string document = "{ __schema { types { name fields { name } } } }";
    string url = "http://localhost:9094/profiles";
    json expectedPayload = check getJsonContentFromFile("hierarchical_resource_paths_introspection.json");
    json actualPayload = check getJsonPayloadFromService(url, document);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["hierarchical_paths"]
}
isolated function testHierarchicalResourcePathsWithSameFieldRepeating() returns error? {
    string document = "{ mountain { trail { getLift { name } } } }";
    string url = "http://localhost:9094/snowtooth";
    json expectedPayload = {
        data: {
            mountain: {
                trail: {
                    getLift: {
                        name: "Lift2"
                    }
                }
            }
        }
    };
    json actualPayload = check getJsonPayloadFromService(url, document);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["hierarchical_paths"]
}
isolated function testHierarchicalResourcePathsWithSameFieldRepeating2() returns error? {
    string document = "{ lift { name } }";
    string url = "http://localhost:9094/snowtooth";
    json expectedPayload = {
        data: {
            lift: {
                name: "Lift1"
            }
        }
    };
    json actualPayload = check getJsonPayloadFromService(url, document);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["hierarchical_paths"]
}
isolated function testHierarchicalResourcePathsReturningServicesWithHierarchicalResourcePath() returns error? {
    string document = "{ profile { personal { name { first } } } }";
    string url = "http://localhost:9094/hierarchical";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            profile: {
                personal: {
                    name: {
                        first: "Sherlock"
                    }
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["hierarchical_paths", "fragments"]
}
isolated function testHierarchicalResourcePathsWithFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("hierarchical_resource_paths_with_fragments.graphql");
    string url = "http://localhost:9094/profiles";
    json actualPayload = check getJsonPayloadFromService(url, document);

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
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
