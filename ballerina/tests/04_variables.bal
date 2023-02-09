// Copyright (c) 2023, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import graphql.parser;

@test:Config {
    groups: ["variables", "input", "fragments", "enums"],
    dataProvider: dataProviderVariableValidation
}
function testVariableValidation(string documentFileName, map<json>? vars) returns error? {
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    parser:DocumentNode documentNode = check getDocumentNode(document);
    NodeModifierContext nodeModifierContext = new;
    FragmentValidatorVisitor fragmentValidator = new FragmentValidatorVisitor(documentNode.getFragments(), nodeModifierContext);
    documentNode.accept(fragmentValidator);
    VariableValidatorVisitor validator = new (schemaWithInputValues, vars, nodeModifierContext);
    documentNode.accept(validator);
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    test:assertEquals(validator.getErrors(), expectedPayload);
}

function dataProviderVariableValidation() returns map<[string, map<json>?]> {
    map<[string, map<json>?]> dataSet = {
        "1": ["undefined_input_variables", { userName:"Thisaru" }],
        "2": ["unused_input_variables", { userName:"Thisaru" }],
        "3": ["input_variables_with_invalid_argument_type", { userName: 4 }],
        "4": ["input_variables_with_empty_input_object_value", { userName: {} }],
        "5": ["fragments_with_undefined_variables", { profileId: 1 }],
        "6": ["fragments_with_unused_variables", { profileId: 1 }],
        "7": ["variables_with_missing_required_argument", {}],
        "8": ["invalid_usage_of_nullable_variable", { weight: 1 }],
        "9": ["variables_with_invalid_type", { userName: 4 }],
        "10": ["variables_with_unknown_type", { userName: 4 }],
        "11": ["variable_with_invalid_default_value1", {}],
        "12": ["variable_with_invalid_default_value2", {}],
        "13": ["variable_with_invalid_default_value3", {}],
        "14": ["variable_default_null_value_with_non_null_type", {}],
        "15": ["scalar_type_variable_with_input_object_value", {}],
        "16": ["enum_type_default_value_with_string_literal", {}]
    };
    return dataSet;
}
