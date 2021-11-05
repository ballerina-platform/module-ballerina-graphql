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

import ballerina/http;
import ballerina/test;
import ballerina/lang.value;

@test:Config {
    groups: ["variables", "request_validation"]
}
isolated function testInvalidRequestWithVariables() returns error? {
    http:Request request = new;
    string document = string`($userName:String){ greet (name: $userName) }`;
    json variables = "Thisaru";
    request.setJsonPayload({ query: document, variables: variables });
    string url = "http://localhost:9091/inputs";
    string actualPayload = check getTextPayloadFromBadRequest(url, request);
    test:assertEquals(actualPayload, "Invalid format in request parameter: variables");
}

@test:Config {
    groups: ["variables", "input"]
}
isolated function testDuplicateInputVariables() returns error? {
    string document = string`($userName:String!, $userName:Int!){ greet (name: $userName) }`;
    json variables = { userName:"Thisaru" };
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("duplicate_input_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "input"]
}
isolated function testUndefinedInputVariables() returns error? {
    string document = string`{ greet (name: $userName) }`;
    json variables = { userName:"Thisaru" };
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("undefined_input_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "input"]
}
isolated function testUnusedInputVariables() returns error? {
    string document = string`query ($userName:String!, $extra:Int){ greet (name: $userName) }`;
    json variables = { userName:"Thisaru" };
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("unused_input_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "input"]
}
isolated function testInputVariablesWithInvalidArgumentType() returns error? {
    string document = string`query Greeting($userName:String!){ greet (name: $userName ) }`;
    json variables = { userName: 4 };
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("input_variables_with_invalid_argument_type.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "input"]
}
isolated function testInputVariablesWithEmptyInputObjectValue() returns error? {
    string document = string`query Greeting($userName:String!){ greet (name: $userName ) }`;
    json variables = { userName: {} };
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("input_variables_with_empty_input_object_value.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "fragments", "input"]
}
isolated function testFragmentsWithInputVariables() returns error? {
    string document = check getGraphQLDocumentFromFile("fragments_with_input_variables.graphql");
    json variables = { profileId: 1 };
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("fragments_with_input_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "fragments", "input"]
}
isolated function testFragmentsWithUndefinedInputVariables() returns error? {
    string document = check getGraphQLDocumentFromFile("fragments_with_undefined_variables.graphql");
    json variables = { profileId: 1 };
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("fragments_with_undefined_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "fragments", "input"]
}
isolated function testDuplicateVariablesWithMultipleOperations() returns error? {
    string document = check getGraphQLDocumentFromFile("duplicate_variables_with_multiple_operations.graphql");
    json variables = { profileId: 1 };
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document, variables, "B");
    json expectedPayload = check getJsonContentFromFile("duplicate_variables_with_multiple_operations.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "fragments", "input"]
}
isolated function testFragmnetsWithUnsusedVariables() returns error? {
    string document = check getGraphQLDocumentFromFile("fragments_with_unused_variables.graphql");
    json variables = { profileId: 1 };
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables, "B");
    json expectedPayload = check getJsonContentFromFile("fragments_with_unused_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "fragments", "input"]
}
isolated function testInlineFragmentsWithVariables() returns error? {
    string document = check getGraphQLDocumentFromFile("inline_fragments_with_variables.graphql");
    json variables = { profileId: 1 };
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("inline_fragments_with_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "fragments", "input", "test"]
}
isolated function testVariablesWithDefaultValues() returns error? {
    string document = check getGraphQLDocumentFromFile("variables_with_default_values.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("variables_with_default_values.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs", "input_coerce"]
}
isolated function testVariablesWithCoerceIntInputToFloat() returns error? {
    string document = "($weight:Float!){ weightInPounds(weightInKg:$weight) }";
    json variables = { weight: 1};
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            weightInPounds: <float>2.205
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["variables", "fragments", "input"]
}
isolated function testVariablesWithMissingRequiredArgument() returns error? {
    string document = string`query Greeting($userName:String!){ greet (name: $userName ) }`;
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("variables_with_missing_required_argument.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs", "enums"]
}
isolated function testEnumTypeVariables() returns error? {
    string document = "($day:Weekday){ isHoliday(weekday: $day) }";
    json variables = { day: MONDAY };
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data: {
            isHoliday: false
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs"]
}
isolated function testMultipleVariableTypesWithSingleQuery() returns error? {
    string document = check getGraphQLDocumentFromFile("multiple_variable_types_with_single_query.graphql");
    json variables = {
        name: "Thisaru",
        age: 30,
        weight: 70.5,
        day: FRIDAY,
        holiday: false
    };
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("multiple_variable_types_with_single_query.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables","map"]
}
isolated function testVariablesWithNestedMap() returns error? {
    string document = string`query ($workerKey:String, $contractKey:String ){ company { workers(key:$workerKey) { contacts(key:$contractKey) { number } } } }`;
    json variables = { workerKey: "id3", contractKey: "home" };
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data: {
            company: {
                workers: {
                    contacts: {
                        number: "+94771234567"
                    }
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs", "input_coerce"]
}
isolated function testInvalidUsageOfNullableVariable() returns error? {
    string document = "($weight:Float){ weightInPounds(weightInKg:$weight) }";
    json variables = { weight: 1};
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("invalid_usage_of_nullable_variable.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "input"]
}
isolated function testVariablesWithInvalidType() returns error? {
    string document = string`query Greeting($userName:Int!){ greet(name: $userName) }`;
    json variables = { userName: 4 };
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("variables_with_invalid_type.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "input"]
}
isolated function testVariablesWithUnknownType() returns error? {
    string document = string`query Greeting($userName: userName){ greet(name: $userName) }`;
    json variables = { userName: 4 };
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("variables_with_unknown_type.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs", "enums"]
}
isolated function testNonNullTypeVariablesWithNullableArgument() returns error? {
    string document = "($day:Weekday!){ isHoliday(weekday: $day) }";
    json variables = { day: MONDAY };
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data: {
            isHoliday: false
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "input"]
}
isolated function testVariableWithInvalidDefaultValue1() returns error? {
    string document = string`query Greeting($userName:String = 3){ greet (name: $userName ) }`;
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("variable_with_invalid_default_value1.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs", "input_coerce"]
}
isolated function testVariableWithInvalidDefaultValue2() returns error? {
    string document = string`($weight:Float = "Walter"){ weightInPounds(weightInKg:$weight) }`;
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("variable_with_invalid_default_value2.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs"]
}
isolated function testVariableWithInvalidDefaultValue3() returns error? {
    string document = string`query Greeting($userName:String = Walter){ greet (name: $userName ) }`;
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("variable_with_invalid_default_value3.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs", "enums"]
}
isolated function testVariablesWithDefaultNullValue() returns error? {
    string document = "($day:Weekday = null){ isHoliday(weekday: $day) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            isHoliday: false
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs", "enums"]
}
isolated function testNullableVariablesWithoutValue() returns error? {
    string document = "($day:Weekday){ isHoliday(weekday: $day) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            isHoliday: false
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs", "enums"]
}
isolated function testVariableDefaultNullValueWithNonNullType() returns error? {
    string document = "($age:Int! = null){ isLegal(age: $age) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("variable_default_null_value_with_non_null_type.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs", "enums"]
}
isolated function testScalarTypeVariableWithInputObjectValue() returns error? {
    string document = "($age:Int! = {}){ isLegal(age: $age) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("scalar_type_variable_with_input_object_value.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs", "enums"]
}
isolated function testEnumTypeDefaultValueWithVariables() returns error? {
    string document = "($day:Weekday = SUNDAY){ isHoliday(weekday: $day) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            isHoliday: true
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs", "enums"]
}
isolated function testInvalidEnumTypeDefaultValueWithVariables() returns error? {
    string document = "($day:Weekday = SNDAY){ isHoliday(weekday: $day) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("invalid_enum_type_default_value_with_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs", "enums"]
}
isolated function testEnumTypeDefaultValueWithStringLiteral() returns error? {
    string document = "($day:Weekday = \"MONDAY\"){ isHoliday(weekday: $day) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("enum_type_default_value_with_string_literal.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs", "input_coerce"]
}
isolated function testVariableDefaultValueWithCoerceIntInputToFloat() returns error? {
    string document = "($weight:Float = 4){ weightInPounds(weightInKg: $weight) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            weightInPounds: <float>8.82
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "inputs"]
}
isolated function testFloatTypeVariableWithDefaultValue() returns error? {
    string document = "($weight:Float = 4.3534){ weightInPounds(weightInKg: $weight) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            weightInPounds: <float>9.599247
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
