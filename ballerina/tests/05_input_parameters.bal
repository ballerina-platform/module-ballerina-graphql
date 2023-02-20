// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
    groups: ["inputs", "validation"],
    dataProvider: dataProviderInputParameterValidation
}
function testInputParameterValidation(string documentFileName) returns error? {
    string document = check getGraphqlDocumentFromFile(documentFileName);
    parser:DocumentNode documentNode = check getDocumentNode(document);
    NodeModifierContext nodeModifierContext = new;
    FragmentValidatorVisitor fragmentValidator = new FragmentValidatorVisitor(documentNode.getFragments(), nodeModifierContext);
    documentNode.accept(fragmentValidator);
    FieldValidatorVisitor validator = new (schemaWithInputValues, nodeModifierContext);
    documentNode.accept(validator);
    json expectedPayload = check getJsonContentFromFile(documentFileName);
    test:assertEquals(validator.getErrors(), expectedPayload);
}

function dataProviderInputParameterValidation() returns (string[][]) {
    return [
        ["invalid_argument1"],
        ["invalid_argument2"],
        ["invalid_argument_with_valid_argument"],
        ["missing_required_argument"]
    ];
}
