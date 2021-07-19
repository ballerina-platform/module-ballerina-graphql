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
import ballerina/lang.value;
import ballerina/io;
@test:Config {
    groups: ["variables", "input"]
}
isolated function testDuplicateInputVariables() returns error? {
    string document = string`($userName:string, $userName:int){ greet (name: $userName) }`;
    json variables = { "userName":"Thisaru" };
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
    json variables = { "userName":"Thisaru" };
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("undefined_input_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "input"]
}
isolated function testUnusedInputVariables() returns error? {
    string document = string`query ($userName:string, $extra:int){ greet (name: $userName) }`;
    json variables = { "userName":"Thisaru" };
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("unused_input_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "input"]
}
isolated function testInputVariablesWithInvalidArgumentType() returns error? {
    string document = string`query Greeting($userName:string){ greet (name: $userName ) }`;
    json variables = { "userName": 4 };
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("invalid_arguments_type_with_input_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "fragments", "input"]
}
isolated function testFragmentsWithInputVariables() returns error? {
    string document = check getGraphQLDocumentFromFile("fragments_with_input_variables.txt");
    json variables = { "profileId": 1 };
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("fragments_with_input_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "fragments", "input"]
}
isolated function testFragmentsWithUndefinedInputVariables() returns error? {
    string document = check getGraphQLDocumentFromFile("fragments_with_undefined_variables.txt");
    json variables = { "profileId": 1 };
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("fragments_with_undefined_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "fragments", "input"]
}
isolated function testDuplicateVariablesWithMultipleOperations() returns error? {
    string document = check getGraphQLDocumentFromFile("multiple_operations_with_duplicate_variables.txt");
    json variables = { "profileId": 1 };
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables, "B");
    io:println(actualPayload.toJsonString());
    json expectedPayload = check getJsonContentFromFile("multiple_operations_with_duplicate_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "fragments", "input"]
}
isolated function testFragmnetsWithUnsusedVariables() returns error? {
    string document = check getGraphQLDocumentFromFile("fragments_with_unused_variables.txt");
    json variables = { "profileId": 1 };
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document, variables, "B");
    json expectedPayload = check getJsonContentFromFile("fragments_with_unused_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "fragments", "input"]
}
isolated function testInlineFragmentsWithVariables() returns error? {
    string document = check getGraphQLDocumentFromFile("inline_fragments_with_variables.txt");
    json variables = { "profileId": 1 };
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile("inline_fragments_with_variables.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables", "fragments", "input"]
}
isolated function testVariablesWithDefaultValues() returns error? {
    string document = check getGraphQLDocumentFromFile("variables_with_default_values.txt");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("variables_with_default_values.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["variables1", "inputs", "input_coerce"]
}
isolated function testVariablesWithCoerceIntInputToFloat() returns error? {
    string document = "($weight:float){ weightInPounds(weightInKg:$weight) }";
    json variables = { "weight": 1};
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
isolated function testVariab() returns error? {
    string document = check getGraphQLDocumentFromFile("variables_with_default_values.txt");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("variables_with_default_values.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
