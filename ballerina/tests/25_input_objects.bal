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
    groups: ["input_objects", "input"]
}
isolated function testInputObject() returns error? {
    string document = string`{ searchProfile(profileDetail:{name:"Jessie", age:28}) { name } }`;
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            searchProfile: {
                name: "Jessie Pinkman"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithMissingArgs() returns error? {
    string document = string`{ searchProfile(profileDetail:{age: 34}) { name } }`;
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("input_object_with_missing_arguments.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithInvalidArguments1() returns error? {
    string document = string`{searchProfile(profileDetail:{name: 5, age: "Arthur"}){ name }}`;
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("input_object_with_invalid_arguments1.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input", "variables"]
}
isolated function testInputObjectWithInvalidArguments2() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_with_invalid_arguments2.graphql");
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("input_object_with_invalid_arguments2.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithVariables() returns error? {
    string document = string`($profile: ProfileDetail!){searchProfile(profileDetail:$profile){ name }}`;
    json variables = { profile: {name: "Arthur", age: 5} };
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("input_object_with_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectIncludeFieldsWithVariables() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_include_fields_with_variables.graphql");
    json variables = { bName: "Harry Potter", authorAge: 50 };
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("input_object_include_fields_with_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithDuplicateFields() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_with_duplicate_fields.graphql");
    json variables = {
        bName: "Harry Potter",
        bAuthor: {
            name: "J.K Rowling",
            age: 50
        }
    };
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("input_object_with_duplicate_fields.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithUndefinedFields() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_with_undefined_fields.graphql");
    json variables = {
        bName: "Harry Potter",
        bAuthor: {
            name: "J.K Rowling",
            age: 50
        }
    };
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("input_object_with_undefined_fields.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectIncludeFieldsWithUndefinedVariables() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_include_fields_with_undefined_variables.graphql");
    json variables = { authorAge: 50 };
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("input_object_include_fields_with_undefined_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectIncludeFieldsWithComplexVariables() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_include_fields_with_complex_variables.graphql");
    json variables = {
        bName: "Study in Scarlet",
        bAuthor: {
            name: "J.K Rowling",
            age: 50
        }
    };
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("input_object_include_fields_with_complex_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithNestedObjects() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_with_nested_object.graphql");
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("input_object_with_nested_objects.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithDefaultValues() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_with_default_value.graphql");
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("input_object_with_default_value.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithoutOptionalFields() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_without_optional_fields.graphql");
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("input_object_without_optional_fields.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithMissingVariablesArguments() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_include_fields_with_complex_variables.graphql");
    json variables = {
        bName: "Study in Scarlet",
        bAuthor: {
            age: 50
        }
    };
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("input_object_with_missing_variables_arguments.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithEnumTypeVariables() returns error? {
    string document = "($day:Date!){ isHoliday(date: $day) }";
    json variables = {
        day: { day: SUNDAY }
    };
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data: {
            isHoliday: true
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithFragmentsAndVaraibles() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_with_fragment_and_variables.graphql");
    string url = "http://localhost:9091/input_objects";
    json variables = {
        bName: "Harry",
        bAuthor: {
            name: "J.K Rowling"
        }
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("input_object_with_fragment_and_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithInlineFragmentsAndVaraibles() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_with_inline_fragment_with_variables.graphql");
    string url = "http://localhost:9091/input_objects";
    json variables = {
        bName: "Harry",
        bAuthor: {
            name: "Doyle"
        },
        dir: "Chris Columbus"
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("input_object_with_inline_fragment_with_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithFloatTypeVariables() returns error? {
    string document = "($weight:Weight!){ weightInPounds (weight:$weight) }";
    json variables = {
        weight: { weightInKg: 70.5 }
    };
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data:{
            weightInPounds:155.45250000000001
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithInvalidTypeVariables1() returns error? {
    string document = "($weight:WeightInKg!){ convertKgToGram (weight:$weight) }";
    json variables = {
        weight: { weight: 70.5 }
    };
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("input_object_with_invalid_type_variables1.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input", "variables"]
}
isolated function testInputObjectWithInvalidTypeVariables2() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_with_invalid_type_variables2.graphql");
    string url = "http://localhost:9091/input_objects";
    json variables = {
        bAuthor: {name:{}, age:{}}
    };
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("input_object_with_invalid_type_variables2.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithUnexpectedVaraibleValues() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_with_inline_fragment_with_variables.graphql");
    string url = "http://localhost:9091/input_objects";
    json variables = {
        bName: "Harry",
        bAuthor: [{name:"arthur"},{name:"J.K Rowling"}],
        dir: "Chris Columbus"
    };
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("input_object_with_unexpected_variable_values.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectVariablesWithInvalidTypeName() returns error? {
    string document = string`($profile: Details!){ searchProfile(profileDetail: $profile){ name } }`;
    json variables = { profile: {name: "Arthur", age: 5} };
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("input_object_variables_with_invalid_type_name.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_objects", "input"]
}
isolated function testInputObjectWithMissingNullableVariableValue() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_with_missing_nullable_variable_value.graphql");
    string url = "http://localhost:9091/input_objects";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("input_object_with_missing_nullable_variable_value.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
