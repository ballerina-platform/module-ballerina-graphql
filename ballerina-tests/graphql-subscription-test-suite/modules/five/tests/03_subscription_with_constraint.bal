// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com).
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

@test:Config {
    groups: ["constraints", "subscriptions"]
}
isolated function testSubscriptionWithConstraints() returns error? {
    string document = check common:getGraphqlDocumentFromFile("constraints");
    json expectedErrors = check common:getJsonContentFromFile("constraints_with_subscription");
    graphql:Client graphqlClient = check new ("http://localhost:9091/constraints");
    // The constraint violation is reported as a `graphql-transport-ws` `error` message, which the
    // client surfaces as a `graphql:SubscriptionError` on the first read of the stream.
    stream<record {}, graphql:ClientError?> movies = check graphqlClient->subscribe(document, operationName = "Sub");
    record {|record {} value;|}|graphql:ClientError? result = movies.next();
    test:assertTrue(result is graphql:SubscriptionError, "Expected a SubscriptionError for the constraint violation");
    if result is graphql:SubscriptionError {
        graphql:ErrorDetail[]? errors = result.detail().errors;
        test:assertTrue(errors is graphql:ErrorDetail[], "Expected the GraphQL errors in the detail");
        if errors is graphql:ErrorDetail[] {
            test:assertEquals(errors.toJson(), expectedErrors);
        }
    }
    check graphqlClient->close();
}

@test:Config {
    groups: ["constraints", "subscriptions"]
}
isolated function testMultipleSubscriptionClientsWithConstraints() returns error? {
    string document = check common:getGraphqlDocumentFromFile("constraints");
    string url = "http://localhost:9091/constraints";
    json expectedErrors = check common:getJsonContentFromFile("constraints_with_subscription");

    graphql:Client graphqlClient1 = check new (url);
    stream<record {}, graphql:ClientError?> movies1 = check graphqlClient1->subscribe(document, operationName = "Sub");
    graphql:Client graphqlClient2 = check new (url);
    stream<record {}, graphql:ClientError?> movies2 = check graphqlClient2->subscribe(document, operationName = "Sub");

    record {|record {} value;|}|graphql:ClientError? result1 = movies1.next();
    test:assertTrue(result1 is graphql:SubscriptionError, "Expected a SubscriptionError from the first client");
    if result1 is graphql:SubscriptionError {
        graphql:ErrorDetail[]? errors = result1.detail().errors;
        test:assertTrue(errors is graphql:ErrorDetail[], "Expected the GraphQL errors in the detail");
        if errors is graphql:ErrorDetail[] {
            test:assertEquals(errors.toJson(), expectedErrors);
        }
    }

    record {|record {} value;|}|graphql:ClientError? result2 = movies2.next();
    test:assertTrue(result2 is graphql:SubscriptionError, "Expected a SubscriptionError from the second client");
    if result2 is graphql:SubscriptionError {
        graphql:ErrorDetail[]? errors = result2.detail().errors;
        test:assertTrue(errors is graphql:ErrorDetail[], "Expected the GraphQL errors in the detail");
        if errors is graphql:ErrorDetail[] {
            test:assertEquals(errors.toJson(), expectedErrors);
        }
    }

    check graphqlClient1->close();
    check graphqlClient2->close();
}
