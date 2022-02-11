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
    groups: ["intersection", "input"]
}
isolated function testInputWithIntersectionParameter() returns error? {
    string document = check getGraphQLDocumentFromFile("intersection_input.graphql");
    string url = "http://localhost:9091/intersection_types";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "getName");
    json expectedPayload = {
        data: {
            name: "trigonocephalus"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["intersection", "input"]
}
isolated function testInputWithIntersectionParameterReference() returns error? {
    string document = check getGraphQLDocumentFromFile("intersection_input.graphql");
    string url = "http://localhost:9091/intersection_types";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "getCity");
    json expectedPayload = {
        data: {
            city: "Albuquerque"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["intersection"]
}
isolated function testOutputWithIntersectionParameter() returns error? {
    string document = check getGraphQLDocumentFromFile("intersection_input.graphql");
    string url = "http://localhost:9091/intersection_types";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "getProfile");
    json expectedPayload = {
        data: {
            profile: {
                name: "Walter White",
                age: 52
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["intersection"]
}
isolated function testOutputWithIntersectionParameterReference() returns error? {
    string document = check getGraphQLDocumentFromFile("intersection_input.graphql");
    string url = "http://localhost:9091/intersection_types";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "getBook");
    json expectedPayload = {
        data: {
            book: {
                name: "Nineteen Eighty-Four",
                author: "George Orwell"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["intersection", "input"]
}
isolated function testInputWithIntersectionParameterArray() returns error? {
    string document = check getGraphQLDocumentFromFile("intersection_input.graphql");
    string url = "http://localhost:9091/intersection_types";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "getNames");
    json expectedPayload = {
        data: {
            names: ["trigonocephalus", "philarchus"]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["intersection", "input"]
}
isolated function testInputWithIntersectionParameterReferenceArray() returns error? {
    string document = check getGraphQLDocumentFromFile("intersection_input.graphql");
    string url = "http://localhost:9091/intersection_types";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "getCities");
    json expectedPayload = {
        data: {
            cities: ["Albuquerque", "Albuquerque"]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["intersection"]
}
isolated function testOutputWithIntersectionParameterArray() returns error? {
    string document = check getGraphQLDocumentFromFile("intersection_input.graphql");
    string url = "http://localhost:9091/intersection_types";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "getProfiles");
    json expectedPayload = {
        data: {
            profiles: [
                {
                    name: "Walter White",
                    age: 52
                },
                {
                    name: "Jesse Pinkman",
                    age: 25
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["intersection"]
}
isolated function testOutputWithIntersectionParameterReferenceArray() returns error? {
    string document = check getGraphQLDocumentFromFile("intersection_input.graphql");
    string url = "http://localhost:9091/intersection_types";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "getBooks");
    json expectedPayload = {
        data: {
            books: [
                {
                    name: "Nineteen Eighty-Four",
                    author: "George Orwell"
                },
                {
                    name: "The Magic of Reality",
                    author: "Richard Dawkins"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
