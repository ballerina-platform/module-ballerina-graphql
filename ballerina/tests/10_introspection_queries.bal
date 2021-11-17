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
    groups: ["introspection"]
}
isolated function testComplexIntrospectionQuery() returns error? {
    string graphqlUrl = "http://localhost:9092/service_objects";
    string document = "{ __schema { types { name kind } } }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedResult = check getJsonContentFromFile("complex_introspection_query.json");
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection"]
}
isolated function testInvalidIntrospectionQuery() returns error? {
    string graphqlUrl = "http://localhost:9092/service_objects";
    string document = "{ __schema { greet } }";
    json actualResult = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    string expectedMessage = "Cannot query field \"greet\" on type \"__Schema\".";
    json expectedResult = {
        errors: [
            {
                message: expectedMessage,
                locations: [
                    {
                        line: 1,
                        column: 14
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection"]
}
isolated function testIntrospectionQueryWithMissingSelection() returns error? {
    string graphqlUrl = "http://localhost:9092/service_objects";
    string document = "{ __schema }";
    json actualResult = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedResult = check getJsonContentFromFile("introspection_query_with_missing_selection.json");
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection"]
}
isolated function testInvalidSchemaIntrospectionField() returns error? {
    string graphqlUrl ="http://localhost:9091/records";
    string document = "{ profile(id: 1) { name __schema { queryType { name } } } }";
    json actualResult = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedResult = {
        errors: [
            {
                message: string`Cannot query field "__schema" on type "Person".`,
                locations: [
                    {
                        line: 1,
                        column: 25
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection"]
}
isolated function testQueryTypeIntrospection() returns error? {
    string graphqlUrl ="http://localhost:9091/validation";
    string document = "{ __schema { queryType { kind fields { name } } } }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedResult = check getJsonContentFromFile("query_type_introspection.json");
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection"]
}
isolated function testMutationTypeIntrospection() returns error? {
    string graphqlUrl ="http://localhost:9091/mutations";
    string document = "{ __schema { mutationType { kind fields { name } } } }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedResult = check getJsonContentFromFile("mutation_type_introspection.json");
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection"]
}
isolated function testComplexIntrospectionQueryWithOtherFields() returns error? {
    string graphqlUrl = "http://localhost:9092/service_objects";
    string document = "{ __schema { types { name kind } } allVehicles { name } }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedResult = check getJsonContentFromFile("complex_introspection_query_with_other_fields.json");
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection"]
}
isolated function testEnumValueIntrospection() returns error? {
    string graphqlUrl ="http://localhost:9092/service_objects";
    string document = "{ __schema { types { enumValues } } }";
    json actualResult = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedResult = check getJsonContentFromFile("enum_value_introspection.json");
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection", "typename"]
}
isolated function testTypeNameIntrospectionOnOperation() returns error? {
    string graphqlUrl ="http://localhost:9091/records";
    string document = "{ __typename }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedResult = {
        data: {
            __typename: "Query"
        }
    };
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection", "typename"]
}
isolated function testTypeNameIntrospectionOnRecordTypes() returns error? {
    string graphqlUrl ="http://localhost:9091/records";
    string document = "{ detective { __typename } }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedResult = {
        data: {
            detective: {
                __typename: "Person"
            }
        }
    };
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection", "validation", "typename"]
}
isolated function testQueryingSubFieldsOnTypeName() returns error? {
    string graphqlUrl ="http://localhost:9091/records";
    string document = "{ detective { __typename { name } } }";
    json actualResult = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedResult = {
        errors: [
            {
                message: "Field \"__typename\" must not have a selection since type \"String!\" has no subfields.",
                locations: [
                    {
                        line: 1,
                        column: 15
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["union", "introspection", "typename"]
}
isolated function testTypeNameIntrospectionOnUnionOfRecordTypes() returns error? {
    string graphqlUrl = "http://localhost:9091/records_union";
    string document = string`query { learningSources { __typename ... on Book { name } } }`;
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = check getJsonContentFromFile("type_name_introspection_on_union_of_record_types.json");
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["introspection", "typename"]
}
isolated function testTypeNameIntrospectionOnServiceTypes() returns error? {
    string graphqlUrl = "http://localhost:9092/service_objects";
    string document = check getGraphQLDocumentFromFile("type_name_introspection_on_service_types.graphql");
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = check getJsonContentFromFile("type_name_introspection_on_service_types.json");
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["union", "introspection", "typename"]
}
isolated function testTypeNameIntrospectionOnUnionOfServiceTypes() returns error? {
    string graphqlUrl = "http://localhost:9092/unions";
    string document = check getGraphQLDocumentFromFile("type_name_introspection_on_union_of__service_types.graphql");
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = check getJsonContentFromFile("type_name_introspection_on_union_of__service_types.json");
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["union", "introspection", "typename"]
}
isolated function testTypeNameIntrospectionInFragments() returns error? {
    string graphqlUrl = "http://localhost:9092/unions";
    string document = check getGraphQLDocumentFromFile("type_name_introspection_in_fragments.graphql");
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = check getJsonContentFromFile("type_name_introspection_in_fragments.json");
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "introspection"]
}
isolated function testIntrospectionOnServiceWithInputObjects() returns error? {
    string graphqlUrl = "http://localhost:9091/input_objects";
    string document = check getGraphQLDocumentFromFile("introspection_on_service_with_input_objects.graphql");
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = check getJsonContentFromFile("introspection_on_service_with_input_objects.json");
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["introspection", "typename", "validation"]
}
isolated function testTypeNameIntrospectionOnScalar() returns error? {
    string graphqlUrl ="http://localhost:9091/validation";
    string document = "{ name { __typename } }";
    json actualResult = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedResult = {
        errors: [
            {
                message: string`Field "name" must not have a selection since type "String!" has no subfields.`,
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
    groups: ["introspection", "type"]
}
isolated function testTypeIntrospectionWithoutTypeNameArgument() returns error? {
    string graphqlUrl = "http://localhost:9091/records";
    string document = check getGraphQLDocumentFromFile("type_introspection_without_type_name_argument.graphql");
    json result = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedPayload = check getJsonContentFromFile("type_introspection_without_type_name_argument.json");
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["introspection", "type"]
}
isolated function testTypeIntrospectionInInvalidPlace() returns error? {
    string graphqlUrl = "http://localhost:9091/records";
    string document = check getGraphQLDocumentFromFile("type_introspection_in_invalid_place.graphql");
    json result = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedPayload = check getJsonContentFromFile("type_introspection_in_invalid_place.json");
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["introspection", "type"]
}
isolated function testTypeIntrospection() returns error? {
    string graphqlUrl = "http://localhost:9091/records";
    string document = check getGraphQLDocumentFromFile("type_introspection.graphql");
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = check getJsonContentFromFile("type_introspection.json");
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["introspection", "type"]
}
isolated function testTypeIntrospectionOnNonExistingType() returns error? {
    string graphqlUrl = "http://localhost:9091/records";
    string document = string`{ __type(name: "INVALID") { kind } }`;
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = { data: { __type: null } };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["introspection", "type"]
}
isolated function testTypeIntrospectionWithoutFields() returns error? {
    string graphqlUrl = "http://localhost:9091/records";
    string document = string`{ __type(name: "Person") }`;
    json result = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Field "__type" of type "__Type" must have a selection of subfields. Did you mean "__type { ... }"?`,
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
    groups: ["introspection", "type", "inputs"]
}
isolated function testIntrospectionOnInputsWithDefaultValues() returns error? {
    string graphqlUrl = "http://localhost:9091/input_type_introspection";
    string document = check getGraphQLDocumentFromFile("introspection_on_inputs_with_default_values.graphql");
    json actualPayload = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = check getJsonContentFromFile("introspection_on_inputs_with_default_values.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
