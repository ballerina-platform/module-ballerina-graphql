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
    groups: ["validation"],
    dataProvider: dataProviderDocumentValidation1
}
function testDocumentValidation1(string documentFileName) returns error? {
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    parser:DocumentNode documentNode = check getDocumentNode(document);
    NodeModifierContext nodeModifierContext = new;
    FragmentValidatorVisitor fragmentValidator = new FragmentValidatorVisitor(documentNode.getFragments(), nodeModifierContext);
    documentNode.accept(fragmentValidator);
    FieldValidatorVisitor validator = new (schemaWithInputValues, nodeModifierContext);
    documentNode.accept(validator);
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    test:assertEquals(validator.getErrors(), expectedPayload);
}

function dataProviderDocumentValidation1() returns (string[][]) {
    return [
        ["subtype_from_primitive_type"]
    ];
}

@test:Config {
    groups: ["fragment", "validation"],
    dataProvider: dataProviderDocumentValidation2
}
isolated function testDocumentValidation2(string documentFileName) returns error? {
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    parser:Parser parser = new (document);
    _ = check parser.parse();
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    test:assertEquals(parser.getErrors(), expectedPayload);
}

function dataProviderDocumentValidation2() returns (string[][]) {
    return [
        ["invalid_document_having_fragment_with_same_name"]
    ];
}
