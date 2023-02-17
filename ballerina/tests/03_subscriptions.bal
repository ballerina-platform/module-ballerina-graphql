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
    groups: ["subscriptions", "validation"],
    dataProvider: dataProviderSubscriptionValidation
}
function testSubscriptionValidation(string documentFileName) returns error? {
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    parser:DocumentNode documentNode = check getDocumentNode(document);
    NodeModifierContext nodeModifierContext = new;
    FragmentValidatorVisitor fragmentValidator = new FragmentValidatorVisitor(documentNode.getFragments(), nodeModifierContext);
    documentNode.accept(fragmentValidator);
    SubscriptionValidatorVisitor validator = new (nodeModifierContext);
    documentNode.accept(validator);
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    test:assertEquals(validator.getErrors(), expectedPayload);
}

function dataProviderSubscriptionValidation() returns (string[][]) {
    return [
        ["subscriptions_with_invalid_multiple_root_fields"],
        ["subscriptions_with_invalid_introspections"],
        ["invalid_anonymous_subscriptions_with_introspections"],
        ["multiple_subscriptions_root_fields_in_fragments"]
    ];
}
