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
    groups: ["records"]
}
isolated function testBallerinaRecordAsGraphqlObject() returns error? {
    string document = "query getPerson { detective { name, address { street } } }";
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            detective: {
                name: "Sherlock Holmes",
                address: {
                    street: "Baker Street"
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["records", "fragments", "inline"]
}
isolated function testInlineFragmentsOnRecordObjects() returns error? {
    string document = check getGraphQLDocumentFromFile("inline_fragments_on_record_objects.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("inline_fragments_on_record_objects.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["records", "fragments", "inline"]
}
isolated function testInlineNestedFragmentsOnRecordObjects() returns error? {
    string document = check getGraphQLDocumentFromFile("inline_nested_fragments_on_record_objects.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("inline_nested_fragments_on_record_objects.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["records", "validation"]
}
isolated function testRequestingObjectWithoutFields() returns error? {
    string graphqlUrl = "http://localhost:9091/records";
    string document = "{ profile(id: 4) }";
    json actualPayload = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    string expectedMessage = string`Field "profile" of type "Person!" must have a selection of subfields. Did you mean "profile { ... }"?`;
    json expectedPayload = {
        errors: [
            {
                message: expectedMessage,
                locations: [
                    {
                        line: 1,
                        column: 3
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["records", "validation"]
}
isolated function testRequestInvalidField() returns error? {
    string graphqlUrl = "http://localhost:9091/records";
    string document = "{ profile(id: 4) { status } }";
    json actualPayload = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    string expectedMessage = "Cannot query field \"status\" on type \"Person\".";
    json expectedPayload = {
        errors: [
            {
                message: expectedMessage,
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
    groups: ["records", "array"]
}
isolated function testRecordTypeArrays() returns error? {
    string graphqlUrl = "http://localhost:9091/records";
    string document = "{ people { name address { city } } }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedResult = check getJsonContentFromFile("record_type_arrays.json");
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["records", "array"]
}
isolated function testResourcesReturningArraysMissingFields() returns error? {
    string graphqlUrl = "http://localhost:9091/records";
    string document = "{ people }";
    json actualResult = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    string expectedMessage = string`Field "people" of type "[Person!]!" must have a selection of subfields. Did you mean "people { ... }"?`;
    json expectedResult = {
        errors: [
            {
                message: expectedMessage,
                locations: [
                    {
                        line: 1,
                        column: 3
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["array", "service"]
}
isolated function testNestedRecordsArray() returns error? {
    string graphqlUrl = "http://localhost:9091/records";
    string document = "{ students { name courses { name books { name } } } }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedResult = check getJsonContentFromFile("nested_records_array.json");
    assertJsonValuesWithOrder(actualResult, expectedResult);
}
