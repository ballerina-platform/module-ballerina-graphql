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
import ballerina/websocket;
import ballerina/test;

@test:Config {
    groups: ["dataloader", "query"],
    after: resetDispatchCounters
}
isolated function testDataLoaderWithQuery() returns error? {
    graphql:Client graphqlClient = check new ("localhost:9090/dataloader");
    string document = check getGraphqlDocumentFromFile("dataloader_with_query");
    json response = check graphqlClient->execute(document);
    json expectedPayload = check getJsonContentFromFile("dataloader_with_query");
    assertJsonValuesWithOrder(response, expectedPayload);
    assertDispatchCountForAuthorLoader(1);
    assertDispatchCountForBookLoader(1);
}

@test:Config {
    groups: ["dataloader", "query"],
    after: resetDispatchCounters
}
isolated function testDataLoaderWithDifferentAliasForSameField() returns error? {
    graphql:Client graphqlClient = check new ("localhost:9090/dataloader");
    string document = check getGraphqlDocumentFromFile("dataloader_with_different_alias_for_same_field");
    json response = check graphqlClient->execute(document);
    json expectedPayload = check getJsonContentFromFile("dataloader_with_different_alias_for_same_field");
    assertJsonValuesWithOrder(response, expectedPayload);
    assertDispatchCountForAuthorLoader(1);
    assertDispatchCountForBookLoader(1);
}

@test:Config {
    groups: ["dataloader", "subscription"],
    after: resetDispatchCounters
}
isolated function testDataLoaderWithSubscription() returns error? {
    string document = check getGraphqlDocumentFromFile("dataloader_with_subscription");
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new ("ws://localhost:9090/dataloader", config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document, "1");
    json[] authorSequence = check getJsonContentFromFile("data_loader_with_subscription").ensureType();
    foreach int i in 0 ..< 5 {
        json expectedMsgPayload = {data: {authors: authorSequence[i]}};
        check validateNextMessage(wsClient, expectedMsgPayload, id = "1");
    }
    assertDispatchCountForBookLoader(5);
}

@test:Config {
    groups: ["dataloader", "mutation"],
    dependsOn: [testDataLoaderWithQuery, testDataLoaderWithSubscription],
    after: resetDispatchCounters
}
isolated function testDataLoaderWithMutation() returns error? {
    graphql:Client graphqlClient = check new ("localhost:9090/dataloader");
    string document = check getGraphqlDocumentFromFile("dataloader_with_mutation");
    json response = check graphqlClient->execute(document);
    json expectedPayload = check getJsonContentFromFile("dataloader_with_mutation");
    assertJsonValuesWithOrder(response, expectedPayload);
    assertDispatchCountForUpdateAuthorLoader(1);
    assertDispatchCountForBookLoader(1);
}

@test:Config {
    groups: ["dataloader", "interceptor"],
    after: resetDispatchCounters
}
isolated function testDataLoaderWithInterceptors() returns error? {
    graphql:Client graphqlClient = check new ("localhost:9090/dataloader_with_interceptor");
    string document = check getGraphqlDocumentFromFile("dataloader_with_interceptor");
    json response = check graphqlClient->execute(document);
    json expectedPayload = check getJsonContentFromFile("dataloader_with_interceptor");
    assertJsonValuesWithOrder(response, expectedPayload);
    assertDispatchCountForAuthorLoader(1);
    assertDispatchCountForBookLoader(1);
}

@test:Config {
    groups: ["dataloader", "dispatch-error"],
    after: resetDispatchCounters
}
isolated function testBatchFunctionReturningErrors() returns error? {
    graphql:Client graphqlClient = check new ("localhost:9090/dataloader");
    string document = check getGraphqlDocumentFromFile("batch_function_returing_errors");
    json response = check graphqlClient->execute(document);
    json expectedPayload = check getJsonContentFromFile("batch_function_returing_errors");
    assertJsonValuesWithOrder(response, expectedPayload);
    assertDispatchCountForAuthorLoader(1);
    assertDispatchCountForBookLoader(0);
}

@test:Config {
    groups: ["dataloader", "dispatch-error"],
    after: resetDispatchCounters
}
isolated function testBatchFunctionReturingNonMatchingNumberOfResults() returns error? {
    graphql:Client graphqlClient = check new ("localhost:9090/dataloader_with_faulty_batch_function");
    string document = check getGraphqlDocumentFromFile("batch_function_returning_non_matcing_number_of_results");
    json response = check graphqlClient->execute(document);
    json expectedPayload = check getJsonContentFromFile("batch_function_returning_non_matcing_number_of_results");
    assertJsonValuesWithOrder(response, expectedPayload);
}

isolated function resetDispatchCounters() {
    lock {
        dispatchCountOfAuthorLoader = 0;
    }
    lock {
        dispatchCountOfBookLoader = 0;
    }
    lock {
        dispatchCountOfUpdateAuthorLoader = 0;
    }
}

isolated function assertDispatchCountForBookLoader(int expectedCount) {
    lock {
        test:assertEquals(dispatchCountOfBookLoader, expectedCount);
    }
}

isolated function assertDispatchCountForUpdateAuthorLoader(int expectedCount) {
    lock {
        test:assertEquals(dispatchCountOfUpdateAuthorLoader, expectedCount);
    }
}

isolated function assertDispatchCountForAuthorLoader(int expectedCount) {
    lock {
        test:assertEquals(dispatchCountOfAuthorLoader, expectedCount);
    }
}
