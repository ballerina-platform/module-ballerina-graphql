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
    groups: ["directives"],
    dataProvider: dataProviderDirectiveValidation
}
function testDirectiveValidation(string documentFileName) returns error? {
    string document = check getGraphQLDocumentFromFile(appendGraphqlExtension(documentFileName));
    parser:DocumentNode documentNode = check getDocumentNode(document);
    NodeModifierContext nodeModifierContext = new;
    FragmentValidatorVisitor fragmentValidator = new FragmentValidatorVisitor(documentNode.getFragments(), nodeModifierContext);
    documentNode.accept(fragmentValidator);
    DirectiveValidatorVisitor validator = new DirectiveValidatorVisitor(schemaWithInputValues, nodeModifierContext);
    documentNode.accept(validator);
    json expectedPayload = check getJsonContentFromFile(appendJsonExtension(documentFileName));
    test:assertEquals(validator.getErrors(), expectedPayload);
}

function dataProviderDirectiveValidation() returns (string[][]) {
    return [
        ["unknown_directives"],
        ["directives_without_argument"],
        ["directives_with_unknown_arguments"],
        ["directives_in_invalid_locations1"],
        ["directives_in_invalid_locations2"],
        ["duplicate_directives_in_same_location"]
    ];
}
