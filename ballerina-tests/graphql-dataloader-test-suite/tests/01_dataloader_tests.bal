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
import ballerina/graphql_test_common as common;
import ballerina/test;
import ballerina/websocket;

@test:Config {
    groups: ["dataloader", "query"],
    after: resetDispatchCounters
}
isolated function testDataLoaderWithQuery() returns error? {
    graphql:Client graphqlClient = check new ("localhost:9090/dataloader");
    string document = check common:getGraphqlDocumentFromFile("dataloader_with_query");
    json response = check graphqlClient->execute(document);
    json expectedPayload = check common:getJsonContentFromFile("dataloader_with_query");
    common:assertJsonValuesWithOrder(response, expectedPayload);
    assertDispatchCountForAuthorLoader(1);
    assertDispatchCountForBookLoader(1);
}

@test:Config {
    groups: ["dataloader", "query"],
    after: resetDispatchCounters
}
isolated function testDataLoaderWithDifferentAliasForSameField() returns error? {
    graphql:Client graphqlClient = check new ("localhost:9090/dataloader");
    string document = check common:getGraphqlDocumentFromFile("dataloader_with_different_alias_for_same_field");
    json response = check graphqlClient->execute(document);
    json expectedPayload = check common:getJsonContentFromFile("dataloader_with_different_alias_for_same_field");
    common:assertJsonValuesWithOrder(response, expectedPayload);
    assertDispatchCountForAuthorLoader(1);
    assertDispatchCountForBookLoader(1);
}

@test:Config {
    groups: ["subscriptions", "dataloader"],
    after: resetDispatchCounters,
    enable: false
}
isolated function testDataLoaderWithSubscription() returns error? {
    string document = check common:getGraphqlDocumentFromFile("dataloader_with_subscription");
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new ("ws://localhost:9090/dataloader", config);
    check common:initiateGraphqlWsConnection(wsClient);
    check common:sendSubscriptionMessage(wsClient, document, "1");
    json[] authorSequence = check common:getJsonContentFromFile("data_loader_with_subscription").ensureType();
    foreach int i in 0 ..< 5 {
        json expectedMsgPayload = {data: {authors: authorSequence[i]}};
        check common:validateNextMessage(wsClient, expectedMsgPayload, id = "1");
    }
    assertDispatchCountForBookLoader(5);
}

@test:Config {
    groups: ["dataloader", "mutation"],
    dependsOn: [
        testDataLoaderWithQuery, testDataLoaderWithSubscription
    ],
    after: resetDispatchCounters,
    enable: false
}
isolated function testDataLoaderWithMutation() returns error? {
    graphql:Client graphqlClient = check new ("localhost:9090/dataloader");
    string document = check common:getGraphqlDocumentFromFile("dataloader_with_mutation");
    json response = check graphqlClient->execute(document);
    json expectedPayload = check common:getJsonContentFromFile("dataloader_with_mutation");
    common:assertJsonValuesWithOrder(response, expectedPayload);
    assertDispatchCountForUpdateAuthorLoader(1);
    assertDispatchCountForBookLoader(1);
}

@test:Config {
    groups: ["dataloader", "interceptor"],
    after: resetDispatchCounters
}
isolated function testDataLoaderWithInterceptors() returns error? {
    graphql:Client graphqlClient = check new ("localhost:9090/dataloader_with_interceptor");
    string document = check common:getGraphqlDocumentFromFile("dataloader_with_interceptor");
    json response = check graphqlClient->execute(document);
    json expectedPayload = check common:getJsonContentFromFile("dataloader_with_interceptor");
    common:assertJsonValuesWithOrder(response, expectedPayload);
    assertDispatchCountForAuthorLoader(1);
    assertDispatchCountForBookLoader(1);
}

@test:Config {
    groups: ["dataloader", "dispatch-error"],
    after: resetDispatchCounters
}
isolated function testBatchFunctionReturningErrors() returns error? {
    graphql:Client graphqlClient = check new ("localhost:9090/dataloader");
    string document = check common:getGraphqlDocumentFromFile("batch_function_returing_errors");
    json response = check graphqlClient->execute(document);
    json expectedPayload = check common:getJsonContentFromFile("batch_function_returing_errors");
    common:assertJsonValuesWithOrder(response, expectedPayload);
    assertDispatchCountForAuthorLoader(1);
    assertDispatchCountForBookLoader(0);
}

@test:Config {
    groups: ["dataloader", "dispatch-error"],
    after: resetDispatchCounters
}
isolated function testBatchFunctionReturingNonMatchingNumberOfResults() returns error? {
    graphql:Client graphqlClient = check new ("localhost:9090/dataloader_with_faulty_batch_function");
    string document = check common:getGraphqlDocumentFromFile("batch_function_returning_non_matcing_number_of_results");
    json response = check graphqlClient->execute(document);
    json expectedPayload = check common:getJsonContentFromFile("batch_function_returning_non_matcing_number_of_results");
    common:assertJsonValuesWithOrder(response, expectedPayload);
}
