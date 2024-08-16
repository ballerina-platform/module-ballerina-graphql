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

import graphql.parser;

import ballerina/http;
import ballerina/test;

@test:Config {
    groups: ["configs", "validation"],
    dataProvider: dataProviderQueryDepthConfigurations
}
function testQueryDepthConfigurations(int maxQueryDepth, string resourceFileName) returns error? {
    string document = check getGraphqlDocumentFromFile(resourceFileName);
    parser:DocumentNode documentNode = check getDocumentNode(document);
    QueryDepthValidatorVisitor validator = new (maxQueryDepth, new);
    documentNode.accept(validator);
    json expectedPayload = check getJsonContentFromFile(resourceFileName);
    test:assertEquals(validator.getErrors(), expectedPayload);
}

function dataProviderQueryDepthConfigurations() returns map<[int, string]> {
    map<[int, string]> dataSet = {
        "1": [2, "query_exceeding_max_depth"],
        "2": [2, "fragment_query_exceeding_max_depth"],
        "3": [2, "query_with_named_operation_exceeding_max_depth"]
    };
    return dataSet;
}

@test:Config {
    groups: ["configs", "validation", "introspection"],
    dataProvider: dataProviderIntrospectionConfigurations
}
function testIntrospectionConfigurations(boolean introspection, string resourceFileName) returns error? {
    string document = check getGraphqlDocumentFromFile(resourceFileName);
    parser:DocumentNode documentNode = check getDocumentNode(document);
    NodeModifierContext nodeModifierContext = new;
    FragmentValidatorVisitor fragmentValidator = new FragmentValidatorVisitor(documentNode.getFragments(), nodeModifierContext);
    documentNode.accept(fragmentValidator);
    IntrospectionValidatorVisitor validator = new (introspection, nodeModifierContext);
    documentNode.accept(validator);
    json|error expectedPayload = getJsonContentFromFile(resourceFileName);
    test:assertEquals(validator.getErrors(), expectedPayload is error ? () : expectedPayload);
}

function dataProviderIntrospectionConfigurations() returns map<[boolean, string]> {
    map<[boolean, string]> dataSet = {
        "1": [false, "schema_introspection_disable"],
        "2": [false, "type_introspection_disable"],
        "3": [false, "introspection_disable"],
        "4": [false, "introspection_disable_with_typename_introspection"],
        "5": [false, "introspection_disable_with_mutation"],
        "6": [false, "introspection_disable_config_with_fragments"]
    };
    return dataSet;
}

@test:Config {
    groups: ["listener", "graphiql"],
    dataProvider: dataProviderGraphiQLPath
}
function testGraphiQLPath(string path) returns error? {
    Error? validateGraphiqlPathResult = validateGraphiqlPath(path);
    test:assertTrue(validateGraphiqlPathResult is Error);
    Error err = <Error>validateGraphiqlPathResult;
    test:assertEquals(err.message(), "Invalid path provided for GraphiQL client");
}

function dataProviderGraphiQLPath() returns (string[][]) {
    return [
        ["/ballerina graphql"],
        ["/ballerina_+#@#$!"]
    ];
}

@test:Config {
    groups: ["listener", "configs"]
}
isolated function testInvalidMaxQueryDepth() returns error? {
    lock {
        Engine|Error engine = new ("", 0, testService, [], true, true);
        test:assertTrue(engine is Error);
        Error err = <Error>engine;
        test:assertEquals(err.message(), "Max query depth value must be a positive integer");
    }
}

@test:Config {
    groups: ["listener", "configs", "graphiql"],
    dataProvider: dataProviderGraphiqlPathLog
}
isolated function testGraphiqlPathLog(int|http:Listener listenTo, ListenerConfiguration config, string httpPath,
        string websocketPath) returns error? {
    [string, string] [expectedHttpPath, expectedWebsocketPath] = getEndpoints(listenTo, config);
    test:assertEquals(expectedHttpPath, httpPath);
    test:assertEquals(expectedWebsocketPath, websocketPath);
}

ListenerSecureSocket secureSocket = {
    key: {
        path: "./tests/resources/certs/ballerinaKeystore.p12",
        password: "ballerina"
    }
};

listener http:Listener testListener1 = new (9090);
listener http:Listener testListener2 = new (9091, {secureSocket});

function dataProviderGraphiqlPathLog() returns map<[(int|http:Listener), ListenerConfiguration, string, string]>|error {
    return {
        "1": [testListener1, {}, "http://localhost:9090", "ws://localhost:9090"],
        "2": [testListener2, {}, "https://localhost:9091", "wss://localhost:9091"],
        "3": [9092, {}, "http://localhost:9092", "ws://localhost:9092"],
        "4": [9093, {secureSocket}, "https://localhost:9093", "wss://localhost:9093"]
    };
}

@test:Config {
    groups: ["configs", "validation", "query_complexity"]
}
isolated function testInvalidMaxQueryComplexity() returns error? {
    lock {
        Engine|Error engine = new ("", 10, testService, [], true, true, queryComplexityConfig = {maxComplexity: -1});
        test:assertTrue(engine is Error);
        Error err = <Error>engine;
        test:assertEquals(err.message(), "Max complexity value must be greater than zero");
    }
}

@test:Config {
    groups: ["configs", "validation", "query_complexity"]
}
isolated function testInvalidDefaultFieldComplexity() returns error? {
    lock {
        Engine|Error engine = new ("", 10, testService, [], true, true, queryComplexityConfig = {
            defaultFieldComplexity: -1
        });
        test:assertTrue(engine is Error);
        Error err = <Error>engine;
        test:assertEquals(err.message(), "Default field complexity value must be greater than zero");
    }
}
