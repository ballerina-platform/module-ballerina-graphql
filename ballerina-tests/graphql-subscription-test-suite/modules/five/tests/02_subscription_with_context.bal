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
import ballerina/test;

@test:Config {
    groups: ["context", "subscriptions"]
}
isolated function testContextWithSubscriptions() returns error? {
    string url = "http://localhost:9091/context";
    string document = string `subscription { messages }`;
    graphql:Client graphqlClient = check new (url,
        subscription = {
            websocketConfig: {
                customHeaders: {"scope": "admin"}
            }
        }
    );
    stream<MessagesResponse, graphql:ClientError?> messages = check graphqlClient->subscribe(document);
    foreach int i in 1 ..< 4 {
        record {|MessagesResponse value;|}|graphql:ClientError? event = messages.next();
        test:assertTrue(event is record {|MessagesResponse value;|}, "Expected a messages event");
        if event is record {|MessagesResponse value;|} {
            test:assertEquals(event.value.data.messages, i);
        }
    }
    check graphqlClient->close();
}

@test:Config {
    groups: ["context", "subscriptions"]
}
isolated function testContextWithInvalidScopeInSubscriptions() returns error? {
    string url = "http://localhost:9091/context";
    string document = string `subscription { messages }`;
    graphql:Client graphqlClient = check new (url,
        subscription = {
            websocketConfig: {
                customHeaders: {"scope": "user"}
            }
        }
    );
    // The `graphql-transport-ws` `error` message the server emits for the unauthorized scope
    // surfaces as a `graphql:SubscriptionError` on the first read of the stream.
    stream<record {}, graphql:ClientError?> messages = check graphqlClient->subscribe(document);
    record {|record {} value;|}|graphql:ClientError? result = messages.next();
    test:assertTrue(result is graphql:SubscriptionError, "Expected a SubscriptionError for the invalid scope");
    if result is graphql:SubscriptionError {
        graphql:ErrorDetail[]? errors = result.detail().errors;
        test:assertTrue(errors is graphql:ErrorDetail[], "Expected the GraphQL errors in the detail");
        if errors is graphql:ErrorDetail[] {
            json expectedErrors = [
                {
                    message: "You don't have permission to retrieve data",
                    locations: [{line: 1, column: 16}],
                    path: ["messages"]
                }
            ];
            test:assertEquals(errors.toJson(), expectedErrors);
        }
    }
    check graphqlClient->close();
}
