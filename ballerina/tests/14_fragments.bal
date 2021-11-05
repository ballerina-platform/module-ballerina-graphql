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
    groups: ["fragments", "validation"]
}
isolated function testUnknownFragment() returns error? {
    string document = check getGraphQLDocumentFromFile("unknown_fragment.graphql");
    string url = "http://localhost:9091/validation";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    string message = string`Unknown fragment "friend".`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 2,
                        column: 8
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "validation"]
}
isolated function testUnknownNestedFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("unknown_nested_fragments.graphql");
    string url ="http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    string message = string`Unknown fragment "fail".`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 14,
                        column: 12
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "validation"]
}
isolated function testFragmentOnInvalidType() returns error? {
    string document = check getGraphQLDocumentFromFile("fragment_on_invalid_type.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    string message = string`Fragment "data" cannot be spread here as objects of type "Query" can never be of type "Person".`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 2,
                        column: 5
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "validation"]
}
isolated function testFragmentWithInvalidField() returns error? {
    string document = check getGraphQLDocumentFromFile("fragment_with_invalid_field.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    string message = string`Cannot query field "invalid" on type "Person".`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 7,
                        column: 9
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "records", "array"]
}
isolated function testFragmentsOnRecordObjects() returns error? {
    string document = check getGraphQLDocumentFromFile("fragments_on_record_objects.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("fragments_on_record_objects.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments"]
}
isolated function testNestedFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("nested_fragments.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("nested_fragments.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments"]
}
isolated function testFragmentsWithMultipleResourceInvocation() returns error? {
    string document = check getGraphQLDocumentFromFile("fragments_with_multiple_resource_invocation.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("fragments_with_multiple_resource_invocation.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "introspection"]
}
isolated function testFragmentsWithInvalidIntrospection() returns error? {
    string document = check getGraphQLDocumentFromFile("fragments_with_invalid_introspection.graphql");
    string url = "http://localhost:9091/validation";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Cannot query field "invalid" on type "__Type".`,
                locations: [
                    {
                        line: 17,
                        column: 9
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "introspection", "test"]
}
isolated function testFragmentsWithIntrospection() returns error? {
    string document = check getGraphQLDocumentFromFile("fragments_with_introspection.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("fragments_with_introspection.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "service"]
}
isolated function testFragmentsQueryingServiceObjects() returns error? {
    string document = check getGraphQLDocumentFromFile("fragments_querying_service_objects.graphql");
    string url = "http://localhost:9092/service_types";
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
    groups: ["fragments", "validation"]
}
isolated function testUnusedFragment() returns error? {
    string document = check getGraphQLDocumentFromFile("unused_fragment.graphql");
    string url = "http://localhost:9092/service_types";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Fragment "fullNameFragment" is never used.`,
                locations: [
                    {
                        line: 9,
                        column: 1
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "inline"]
}
isolated function testInlineFragment() returns error? {
    string document = check getGraphQLDocumentFromFile("inline_fragment.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("inline_fragment.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "inline"]
}
isolated function testUnknownInlineFragment() returns error? {
    string document = check getGraphQLDocumentFromFile("unknown_inline_fragment.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("unknown_inline_fragment.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "inline"]
}
isolated function testInvalidSpreadInlineFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("invalid_spread_inline_fragments.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("invalid_spread_inline_fragments.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments"]
}
isolated function testFragmentsInsideFragmentsWhenReturningServices() returns error? {
    string document = check getGraphQLDocumentFromFile("fragments_inside_fragments_when_returning_services.graphql");
    string url = "http://localhost:9092/service_objects";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            teacher: {
                name: "Walter White"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments"]
}
isolated function testNestedFragmentsQueryingServiceObjectsWithMultipleFields() returns error? {
    string document =
        check getGraphQLDocumentFromFile("nested_fragments_querying_service_objects_with_multiple_fields.graphql");
    string url = "http://localhost:9092/service_objects";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            teacher: {
                name: "Walter White",
                subject: "Chemistry"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
