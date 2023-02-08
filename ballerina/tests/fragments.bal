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
    groups: ["fragments", "validation"],
    dataProvider: dataGen1
}
isolated function testFragmentValidation(string documentFileName) returns error? {
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    parser:DocumentNode documentNode = check getDocumentNode(document);
    FragmentValidatorVisitor validator = new FragmentValidatorVisitor(documentNode.getFragments(), new);
    documentNode.accept(validator);
    json actualPayload = validator.getErrors().toJson();
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragment"],
    dataProvider: dataGen2
}
isolated function testFragmentsWithCycles(string documentFileName) returns error? {
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    parser:DocumentNode documentNode = check getDocumentNode(document);
    FragmentCycleFinderVisitor validator = new FragmentCycleFinderVisitor(documentNode.getFragments(), new);
    documentNode.accept(validator);
    json actualPayload = validator.getErrors().toJson();
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataGen1() returns (string[][]) {
    return [["unknown_fragment"], ["unknown_nested_fragments"], ["unused_fragment"]];
}

function dataGen2() returns (string[][]) {
    return [["fragments_with_cycles"], ["fragments_with_multiple_cycles"], ["fragments_with_multiple_cycles_in_same_fragment"]];
}
