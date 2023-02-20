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
    groups: ["variables", "input"],
    dataProvider: dataProviderInputVariables
}
isolated function testDuplicateInputVariables(string url, string documentFileName, json variables, string? operationName = ()) returns error? {
    string document = check getGraphQLDocumentFromFile(appendGraphqlExtension(documentFileName));
    json actualPayload = check getJsonPayloadFromService(url, document, variables, operationName);
    json expectedPayload = check getJsonContentFromFile(appendJsonExtension(documentFileName));
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderInputVariables() returns map<[string, string, json, string?]> {
    string url1 = "http://localhost:9091/inputs";
    string url2 = "http://localhost:9091/records";
    string url3 = "http://localhost:9095/special_types";
    json var1 = {
        name: "Thisaru",
        age: 30,
        weight: 70.5,
        day: FRIDAY,
        holiday: false
    };

    map<[string, string, json, string?]> dataSet = {
        "1": [url1, "duplicate_input_variables", {userName: "Thisaru"}],
        "2": [url2, "fragments_with_input_variables", {profileId: 1}],
        "3": [url2, "duplicate_variables_with_multiple_operations", {profileId: 1}, "B"],
        "4": [url2, "inline_fragments_with_variables", {profileId: 1}],
        "5": [url2, "variables_with_default_values"],
        "6": [url1, "variables_with_coerce_int_input_to_float", {weight: 1}],
        "7": [url1, "enum_type_variables", {day: MONDAY}],
        "8": [url1, "multiple_variable_types_with_single_query", var1],
        "9": [url3, "variables_with_nested_map", {workerKey: "id3", contractKey: "home"}],
        "10": [url1, "non_null_type_variables_with_nullable_rgument", {day: MONDAY}],
        "11": [url1, "variables_with_default_null_value"],
        "12": [url1, "nullable_variables_without_value"],
        "13": [url1, "invalid_enum_type_default_value_with_variables"],
        "14": [url1, "enum_type_default_value_with_variables"],
        "15": [url1, "variable_default_value_with_coerce_int_input_to_float"],
        "16": [url1, "float_type_variable_with_default_value"]
    };
    return dataSet;
}
