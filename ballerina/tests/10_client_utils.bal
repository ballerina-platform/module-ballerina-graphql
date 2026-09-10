// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

import ballerina/test;

@test:Config {
    groups: ["client", "validation"]
}
isolated function testValidateOperationKindWithSingleAnonymousOperation() {
    string document = "{ greeting }";
    InvalidDocumentError? result = validateOperationKind(document, (), parser:OPERATION_QUERY);
    test:assertTrue(result is (), "Expected the validation to pass");
}

@test:Config {
    groups: ["client", "validation"]
}
isolated function testValidateOperationKindWithNamedOperationSelection() {
    string document = "query getGreeting { greeting } mutation setGreeting { setGreeting }";
    InvalidDocumentError? result = validateOperationKind(document, "setGreeting", parser:OPERATION_MUTATION);
    test:assertTrue(result is (), "Expected the validation to pass");
}

@test:Config {
    groups: ["client", "validation"]
}
isolated function testValidateOperationKindWithMissingNamedOperation() {
    string document = "query getGreeting { greeting }";
    InvalidDocumentError? result = validateOperationKind(document, "unknownOperation", parser:OPERATION_QUERY);
    test:assertTrue(result is InvalidDocumentError, "Expected an InvalidDocumentError");
    InvalidDocumentError err = <InvalidDocumentError>result;
    test:assertEquals(err.message(), string `Unknown operation named "unknownOperation".`);
}

@test:Config {
    groups: ["client", "validation"]
}
isolated function testValidateOperationKindWithMultipleOperationsWithoutName() {
    string document = "query getGreeting { greeting } mutation setGreeting { setGreeting }";
    InvalidDocumentError? result = validateOperationKind(document, (), parser:OPERATION_QUERY);
    test:assertTrue(result is InvalidDocumentError, "Expected an InvalidDocumentError");
    InvalidDocumentError err = <InvalidDocumentError>result;
    test:assertEquals(err.message(), "Must provide operation name if query contains multiple operations.");
}

@test:Config {
    groups: ["client", "validation"]
}
isolated function testValidateOperationKindWithParseError() {
    string document = "query getGreeting { greeting";
    InvalidDocumentError? result = validateOperationKind(document, (), parser:OPERATION_QUERY);
    test:assertTrue(result is InvalidDocumentError, "Expected an InvalidDocumentError");
    InvalidDocumentError err = <InvalidDocumentError>result;
    test:assertEquals(err.message(), "Invalid GraphQL document provided");
    ErrorDetail[]? errors = err.detail().errors;
    test:assertTrue(errors is ErrorDetail[] && errors.length() == 1, "Expected the parse error detail");
}

@test:Config {
    groups: ["client", "validation"],
    dataProvider: dataProviderOperationKindMismatch
}
isolated function testValidateOperationKindMismatch(string document, parser:RootOperationType expectedKind,
        string expectedMessage) {
    InvalidDocumentError? result = validateOperationKind(document, (), expectedKind);
    test:assertTrue(result is InvalidDocumentError, "Expected an InvalidDocumentError");
    InvalidDocumentError err = <InvalidDocumentError>result;
    test:assertEquals(err.message(), expectedMessage);
}

isolated function dataProviderOperationKindMismatch() returns map<[string, parser:RootOperationType, string]> {
    return {
        "mutationForQuery": [
            "mutation { setGreeting }",
            parser:OPERATION_QUERY,
            "expected a query operation, but found a mutation operation"
        ],
        "subscriptionForQuery": [
            "subscription { greetings }",
            parser:OPERATION_QUERY,
            "expected a query operation, but found a subscription operation"
        ],
        "queryForMutation": [
            "query { greeting }",
            parser:OPERATION_MUTATION,
            "expected a mutation operation, but found a query operation"
        ],
        "subscriptionForMutation": [
            "subscription { greetings }",
            parser:OPERATION_MUTATION,
            "expected a mutation operation, but found a subscription operation"
        ],
        "queryForSubscription": [
            "{ greeting }",
            parser:OPERATION_SUBSCRIPTION,
            "expected a subscription operation, but found a query operation"
        ],
        "mutationForSubscription": [
            "mutation { setGreeting }",
            parser:OPERATION_SUBSCRIPTION,
            "expected a subscription operation, but found a mutation operation"
        ]
    };
}

@test:Config {
    groups: ["client"],
    dataProvider: dataProviderWebSocketServiceUrl
}
isolated function testResolveWebSocketServiceUrl(string? subscriptionServiceUrl, string serviceUrl,
        string expectedUrl) returns error? {
    string resolvedUrl = check resolveWebSocketServiceUrl(subscriptionServiceUrl, serviceUrl);
    test:assertEquals(resolvedUrl, expectedUrl);
}

isolated function dataProviderWebSocketServiceUrl() returns map<[string?, string, string]> {
    return {
        "httpUrl": [(), "http://localhost:9090/graphql", "ws://localhost:9090/graphql"],
        "httpsUrl": [(), "https://localhost:9090/graphql", "wss://localhost:9090/graphql"],
        "schemeLessUrl": [(), "localhost:9090/graphql", "ws://localhost:9090/graphql"],
        "explicitWsUrl": ["ws://localhost:9091/subscriptions", "http://localhost:9090/graphql", "ws://localhost:9091/subscriptions"],
        "explicitWssUrl": ["wss://localhost:9091/subscriptions", "http://localhost:9090/graphql", "wss://localhost:9091/subscriptions"],
        "explicitHttpUrl": ["http://localhost:9091/subscriptions", "http://localhost:9090/graphql", "ws://localhost:9091/subscriptions"]
    };
}

@test:Config {
    groups: ["client"]
}
isolated function testResolveWebSocketServiceUrlWithInvalidScheme() {
    string|ClientError result = resolveWebSocketServiceUrl((), "ftp://localhost:9090/graphql");
    test:assertTrue(result is ClientError, "Expected a ClientError");
    ClientError err = <ClientError>result;
    test:assertEquals(err.message(),
            "Failed to derive the WebSocket URL for GraphQL subscriptions from the URL: ftp://localhost:9090/graphql");
}

@test:Config {
    groups: ["client"],
    dataProvider: dataProviderInvalidReconnectConfig
}
isolated function testValidateReconnectConfig(ReconnectConfig config, string expectedMessage) {
    ClientError? result = validateReconnectConfig(config);
    test:assertTrue(result is ClientError, "Expected a ClientError");
    ClientError err = <ClientError>result;
    test:assertEquals(err.message(), expectedMessage);
}

isolated function dataProviderInvalidReconnectConfig() returns map<[ReconnectConfig, string]> {
    return {
        "invalidMaxAttempts": [
            {maxAttempts: 0},
            "Invalid reconnect configuration: the maxAttempts must be greater than zero"
        ],
        "invalidInterval": [
            {interval: -1},
            "Invalid reconnect configuration: the interval must not be negative"
        ],
        "invalidBackOffFactor": [
            {backOffFactor: 0.0},
            "Invalid reconnect configuration: the backOffFactor must be greater than zero"
        ],
        "invalidMaxInterval": [
            {interval: 10, maxInterval: 5},
            "Invalid reconnect configuration: the maxInterval must not be less than the interval"
        ]
    };
}

@test:Config {
    groups: ["client"]
}
isolated function testValidateValidReconnectConfig() {
    ClientError? result = validateReconnectConfig({maxAttempts: 3, interval: 2, backOffFactor: 1.5, maxInterval: 10});
    test:assertTrue(result is (), "Expected the validation to pass");
    result = validateReconnectConfig(());
    test:assertTrue(result is (), "Expected the validation to pass");
}

@test:Config {
    groups: ["client"]
}
isolated function testCalculateBackOffDelay() {
    ReconnectConfig config = {interval: 2, backOffFactor: 2.0, maxInterval: 10};
    test:assertEquals(calculateBackOffDelay(config, 0), 2d);
    test:assertEquals(calculateBackOffDelay(config, 1), 4d);
    test:assertEquals(calculateBackOffDelay(config, 2), 8d);
    test:assertEquals(calculateBackOffDelay(config, 3), 10d);
}
