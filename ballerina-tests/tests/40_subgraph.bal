// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

import ballerina/graphql;
import ballerina/regex;
import ballerina/test;

@test:Config {
    groups: ["federation", "subgraph"]
}
isolated function testSubgrapWithValidQuery() returns error? {
    string document = string `{ greet }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    json response = check graphqlClient->execute(document);
    json expectedPayload = {data: {greet: "welcome"}};
    assertJsonValuesWithOrder(response, expectedPayload);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"],
    dataProvider: dataProviderToQuerySubgraph
}
function testQueryingSubgraph(string documentFileName) returns error? {
    string document = check getGraphqlDocumentFromFile(documentFileName);
    string url = "localhost:9088/subgraph";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(documentFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderToQuerySubgraph() returns string[][] {
    string[][] dataSet = [
        ["querying_entities_field_on_subgraph"],
        ["querying_entities_field_with_list_of_null_values"],
        ["querying_entities_field_with_null_argument"],
        ["querying_entities_field_with_list_of_non_any_argument"],
        ["querying_entities_field_without_typename_in_argument"],
        ["querying_entities_field_with_object_argument"],
        ["introspection_on_subgraph"]
    ];
    return dataSet;
}

@test:Config {
    groups: ["federation", "subgraph", "entity", "variable"],
    dataProvider: dataProviderToQuerySubgraphWithVariable
}
function testQueryingSubgraphWithVariables(string responseFileName, json variable) returns error? {
    string document = check getGraphqlDocumentFromFile("querying_subgraph_with_variable");
    string url = "localhost:9088/subgraph";
    json actualPayload = check getJsonPayloadFromService(url, document, variable);
    json expectedPayload = check getJsonContentFromFile(responseFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderToQuerySubgraphWithVariable() returns map<[string, json]> {
    map<json> validRepresentation = {
        rep: [
            {__typename: "Star", name: "Acamar"},
            {__typename: "Planet", name: "Earth"}
        ]
    };
    map<[string, json]> dataSet = {
        "1": ["querying_entities_field_with_null_variable", {rep: null}],
        "2": ["querying_entities_field_with_list_of_null_variable", {rep: [null]}],
        "3": ["querying_entities_field_with_list_of_non_any_variable", {rep: [1, "string", 1.23]}],
        "4": ["querying_entities_field_without_typename_in_variable", {rep: [{name: "Acamar"}]}],
        "5": ["querying_entities_field_with_object_variable", {rep: {name: "Acamar"}}],
        "6": ["querying_entities_field_with_variable_on_subgraph", validRepresentation],
        "7": ["test_entities_resolver_returning_null_value", {rep: [{__typename: "Planet"}]}],
        "8": ["test_entities_resolver_returning_error_for_invalid_typename", {rep: [{__typename: "Invalid"}]}],
        "9": ["test_entities_resolver_returnig_error_for_unresolvable_entity", {rep: [{__typename: "Moon"}]}],
        "10": ["test_entities_resolver_returning_error_for_invalid_return_type", {rep: [{__typename: "Satellite"}]}]
    };
    return dataSet;
}

@test:Config {
    groups: ["federation", "subgraph", "entity", "introspection"]
}
isolated function testQueringSdlOnSubgraph() returns error? {
    string document = string `{ _service { sdl } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    json response = check graphqlClient->execute(document);
    string sdl = check response.data._service.sdl.ensureType();
    // Replace line seperator on windows "\r\n" with "\n"
    sdl = regex:replaceAll(sdl, "\r\n", "\n");
    response = {data: {_service: {sdl}}};
    json expectedPayload = check getJsonContentFromFile("quering_sdl_on_subgraph");
    assertJsonValuesWithOrder(response, expectedPayload);
}

@test:Config {
    groups: ["federation", "subgraph"]
}
function testAttachingSubgraphServiceToDynamicListener() returns error? {
    check specialTypesTestListener.attach(subgraphServivce, "subgraph");
    string url = "http://localhost:9095/subgraph";
    graphql:Client graphqlClient = check new (url);
    string document = check getGraphqlDocumentFromFile("querying_entities_field_on_subgraph");
    json response = check graphqlClient->execute(document);
    json expectedPayload = check getJsonContentFromFile("querying_entities_field_on_subgraph");
    check specialTypesTestListener.detach(subgraphServivce);
    assertJsonValuesWithOrder(response, expectedPayload);
}
