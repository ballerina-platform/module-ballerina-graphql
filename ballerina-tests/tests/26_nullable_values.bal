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
    groups: ["inputs", "nullable"],
    dataProvider: dataProviderNullableValues
}
isolated function testNullableValues(string url, string documentFileName, json variables = ()) returns error? {
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderNullableValues() returns map<[string, string, json]> {
    string url1 = "http://localhost:9091/inputs";
    string url2 = "http://localhost:9091/null_values";
    string url3 = "http://localhost:9091/list_inputs";

    map<[string, string, json]> dataSet = {
        "1": [url1, "null_as_enum_input"],
        "2": [url2, "null_as_scalar_input"],
        "3": [url1, "null_value_for_non_null_argument"],
        "4": [url2, "null_value_for_defaultable_arguments"],
        "5": [url2, "null_value_in_input_object_field"],
        "6": [url2, "null_as_resource_function_name"],
        "7": [url1, "null_as_enum_input_with_variable_value", {day: null}],
        "8": [url2, "null_as_scalar_input_with_variable_value", {id: null}],
        "9": [url1, "null_value_for_non_null_argument_with_variable_value", {name: null}],
        "10": [url2, "null_value_for_defaultable_arguments_with_variable", {name: null}],
        "11": [url2, "null_value_in_input_object_field_with_variable_value", {author: {name: null, id: 1}}],
        "12": [url3, "null_value_in_list_type_input_with_variables", {words: ["Hello!", null, "GraphQL"]}],
        "13": [url2, "null_value_for_nullable_input_object_with_variable_value", {author: null}],
        "14": [url3, "null_value_for_nullable_list_type_input_with_variables", {words: null}]
    };
    return dataSet;
}
