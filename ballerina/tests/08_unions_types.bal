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

type Information Address|Person;

type Details record {
    Information information;
};

@test:Config {
    groups: ["union"]
}
isolated function testResourceReturningUnionTypes() returns error? {
    string graphqlUrl = "http://localhost:9091/records_union";
    string document = "{ profile (id: 5) { name } }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

    json expectedPayload = {
        errors: [
            {
                message: "Invalid ID provided",
                locations: [
                    {
                        line: 1,
                        column: 3
                    }
                ],
                path: ["profile"]
            }
        ],
        data: {
            profile: null
        }
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["union"]
}
isolated function testResourceReturningUnionWithNull() returns error? {
    string graphqlUrl = "http://localhost:9091/records_union";
    string document = "{ profile (id: 4) { name } }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

    json expectedPayload = {
        data: {
            profile: null
        }
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["union"]
}
isolated function testQueryUnionType() returns error? {
    string graphqlUrl = "http://localhost:9091/records_union";
    string document = check getGraphQLDocumentFromFile("query_union_type.graphql");
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = {
        data: {
            information: {
                name: "Sherlock Holmes"
            }
        }
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["union"]
}
isolated function testUnionTypeWithIncorrectFragment() returns error? {
    string graphqlUrl = "http://localhost:9091/records_union";
    string document = check getGraphQLDocumentFromFile("union_type_with_incorrect_fragment.graphql");
    json result = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Fragment "invalidFragment" cannot be spread here as objects of type "Information" can never be of type "Student".`,
                locations: [
                    {
                        line: 3,
                        column: 9
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["union"]
}
isolated function testQueryUnionTypeWithFieldAndFragment() returns error? {
    string graphqlUrl = "http://localhost:9091/records_union";
    string document = check getGraphQLDocumentFromFile("union_type_with_field_and_fragment.graphql");
    json result = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Cannot query field "name" on type "Information". Did you mean to use a fragment on "Address" or "Person"?`,
                locations: [
                    {
                        line: 3,
                        column: 9
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["union"]
}
isolated function testUnionTypeWithFragmentAndField() returns error? {
    string graphqlUrl = "http://localhost:9091/records_union";
    string document = check getGraphQLDocumentFromFile("union_type_with_fragment_and_field.graphql");
    json result = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Cannot query field "name" on type "Information". Did you mean to use a fragment on "Address" or "Person"?`,
                locations: [
                    {
                        line: 4,
                        column: 9
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["union"]
}
isolated function testUnionTypeWithoutSelection() returns error? {
    string graphqlUrl = "http://localhost:9091/records_union";
    string document = "{ information(id: 2) }";
    json result = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    string message = string`Field "information" of type "Information!" must have a selection of subfields. Did you mean "information { ... }"?`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 1,
                        column: 3
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["union"]
}
isolated function testUnionTypeWithSelectionField() returns error? {
    string graphqlUrl = "http://localhost:9091/records_union";
    string document = "{ information(id: 2) { name } }";
    json result = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    string message = string`Cannot query field "name" on type "Information". Did you mean to use a fragment on "Address" or "Person"?`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 1,
                        column: 24
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["union"]
}
isolated function testUnionTypeAsRecordFieldWithoutFragment() returns error? {
    string graphqlUrl = "http://localhost:9091/records_union";
    string document = check getGraphQLDocumentFromFile("union_type_as_record_field_without_fragment.graphql");
    json result = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Cannot query field "name" on type "Information". Did you mean to use a fragment on "Address" or "Person"?`,
                locations: [
                    {
                        line: 4,
                        column: 13
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["union"]
}
isolated function testUnionTypeAsRecordField() returns error? {
    string graphqlUrl = "http://localhost:9091/records_union";
    string document = check getGraphQLDocumentFromFile("union_type_as_record_field.graphql");
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = {
        data: {
            details: {
                information: {
                    city: "London"
                }
            }
        }
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["union"]
}
isolated function testUnionTypesWithMissingTypesInDocument() returns error? {
    string graphqlUrl = "http://localhost:9091/records_union";
    string document = check getGraphQLDocumentFromFile("union_types_with_missing_types_in_document.graphql");
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = check getJsonContentFromFile("union_types_with_missing_types_in_document.json");
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["union"]
}
isolated function testUnionTypesWithMissingTypesInDocumentWithInlineFragments() returns error? {
    string graphqlUrl = "http://localhost:9091/records_union";
    string document = string`query { learningSources { ... on Book { name } } }`;
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload =
        check getJsonContentFromFile("union_types_with_missing_types_in_document_with_inline_fragments.json");
    assertJsonValuesWithOrder(result, expectedPayload);
}
