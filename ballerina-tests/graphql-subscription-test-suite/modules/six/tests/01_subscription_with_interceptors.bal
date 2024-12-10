// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/graphql_test_common as common;
import ballerina/test;
import ballerina/websocket;

@test:Config {
    groups: ["interceptors", "subscriptions"]
}
isolated function testInterceptorsWithSubscriptionReturningScalar() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9091/subscription_interceptor1";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient1);
    check common:sendSubscriptionMessage(wsClient1, document, "1");

    websocket:Client wsClient2 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient2);
    check common:sendSubscriptionMessage(wsClient2, document, "2");

    foreach int i in 1 ..< 4 {
        json expectedMsgPayload = {data: {messages: (i * 5 - 5) * 5 - 5}};
        check common:validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        check common:validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    }
}

@test:Config {
    groups: ["interceptors", "subscriptions", "records"]
}
isolated function testInterceptorsWithSubscriptionReturningRecord() returns error? {
    string document = check common:getGraphqlDocumentFromFile("interceptors_with_subscription_return_records");
    string url = "ws://localhost:9091/subscription_interceptor2";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient1);
    check common:sendSubscriptionMessage(wsClient1, document, operationName = "A");
    json expectedMsgPayload = {data: {books: {name: "Crime and Punishment", author: "Athur Conan Doyle"}}};
    check common:validateNextMessage(wsClient1, expectedMsgPayload);
    expectedMsgPayload = {data: {books: {name: "A Game of Thrones", author: "Athur Conan Doyle"}}};
    check common:validateNextMessage(wsClient1, expectedMsgPayload);

    websocket:Client wsClient2 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient2);
    check common:sendSubscriptionMessage(wsClient2, document, operationName = "B");
    expectedMsgPayload = {data: {newBooks: {name: "A Game of Thrones", author: "George R.R. Martin"}}};
    check common:validateNextMessage(wsClient2, expectedMsgPayload);
}

@test:Config {
    groups: ["interceptors", "fragments", "subscriptions"]
}
isolated function testInterceptorsWithSubscriptionAndFragments() returns error? {
    string document = check common:getGraphqlDocumentFromFile("interceptors_with_fragments_and_subscription");
    string url = "ws://localhost:9091/subscription_interceptor3";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient1);
    check common:sendSubscriptionMessage(wsClient1, document, operationName = "getStudents");
    json expectedMsgPayload = {data: {students: {id: 1, name: "Harry Potter"}}};
    check common:validateNextMessage(wsClient1, expectedMsgPayload);
    expectedMsgPayload = {data: {students: {id: 2, name: "Harry Potter"}}};
    check common:validateNextMessage(wsClient1, expectedMsgPayload);

    websocket:Client wsClient2 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient2);
    check common:sendSubscriptionMessage(wsClient2, document, operationName = "getNewStudents");
    expectedMsgPayload = {data: {newStudents: {id: 4, name: "Ron Weasley"}}};
    check common:validateNextMessage(wsClient2, expectedMsgPayload);
}

@test:Config {
    groups: ["interceptors", "union", "subscriptions"]
}
isolated function testInterceptorsWithUnionTypeSubscription() returns error? {
    string document = check common:getGraphqlDocumentFromFile("interceptors_with_subscription_return_union_type");
    string url = "ws://localhost:9091/subscription_interceptor4";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient1);
    check common:sendSubscriptionMessage(wsClient1, document, operationName = "unionTypes1");
    json expectedMsgPayload = {
        data: {
            multipleValues1: {
                id: 100,
                name: "Jesse Pinkman"
            }
        }
    };
    check common:validateNextMessage(wsClient1, expectedMsgPayload);
    expectedMsgPayload = {
        data: {
            multipleValues1: {
                name: "Walter White",
                subject: "Physics"
            }
        }
    };
    check common:validateNextMessage(wsClient1, expectedMsgPayload);

    websocket:Client wsClient2 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient2);
    check common:sendSubscriptionMessage(wsClient2, document, operationName = "unionTypes2");
    expectedMsgPayload = {
        data: {
            multipleValues2: {
                name: "Walter White",
                subject: "Chemistry"
            }
        }
    };
    check common:validateNextMessage(wsClient2, expectedMsgPayload);
}

@test:Config {
    groups: ["interceptors", "subscriptions"]
}
isolated function testInterceptorsReturnBeforeResolverWithSubscription() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9091/subscription_interceptor5";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient1);
    check common:sendSubscriptionMessage(wsClient1, document, "1");

    websocket:Client wsClient2 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient2);
    check common:sendSubscriptionMessage(wsClient2, document, "2");

    json expectedMsgPayload = {data: {messages: 1}};
    foreach int i in 1 ..< 4 {
        check common:validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        check common:validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    }
}

@test:Config {
    groups: ["interceptors", "subscriptions"]
}
isolated function testInterceptorsDestructiveModificationWithSubscription() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9091/subscription_interceptor6";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient1);
    check common:sendSubscriptionMessage(wsClient1, document, "1");

    websocket:Client wsClient2 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient2);
    check common:sendSubscriptionMessage(wsClient2, document, "2");

    json expectedMsgPayload = {
        errors: [
            {
                message: "Invalid return type in Interceptor \"DestructiveModification\". Expected type Int!",
                locations: [
                    {
                        line: 1,
                        column: 16
                    }
                ],
                path: [
                    "messages"
                ]
            },
            {
                message: "Invalid return type in Interceptor \"DestructiveModification\". Expected type Int!",
                locations: [
                    {
                        line: 1,
                        column: 16
                    }
                ],
                path: ["messages"]
            }
        ],
        data: null
    };
    foreach int i in 1 ..< 4 {
        check common:validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        check common:validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    }
}

@test:Config {
    groups: ["interceptors", "subscriptions"]
}
isolated function testInterceptorsWithSubscribersRunSimultaniously1() returns error? {
    final string document = string `subscription { messages }`;
    string url = "ws://localhost:9091/subscription_interceptor1";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    final websocket:Client wsClient1 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient1);

    final websocket:Client wsClient2 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient2);

    final websocket:Client wsClient3 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient3);

    worker A returns error? {
        check common:sendSubscriptionMessage(wsClient1, document, "1");
        foreach int i in 1 ..< 4 {
            json expectedMsgPayload = {data: {messages: (i * 5 - 5) * 5 - 5}};
            check common:validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        }
    }
    worker B returns error? {
        check common:sendSubscriptionMessage(wsClient2, document, "2");
        foreach int i in 1 ..< 4 {
            json expectedMsgPayload = {data: {messages: (i * 5 - 5) * 5 - 5}};
            check common:validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
        }
    }
    check common:sendSubscriptionMessage(wsClient3, document, "3");
    foreach int i in 1 ..< 4 {
        json expectedMsgPayload = {data: {messages: (i * 5 - 5) * 5 - 5}};
        check common:validateNextMessage(wsClient3, expectedMsgPayload, id = "3");
    }
    check wait A;
    check wait B;
}

@test:Config {
    groups: ["interceptors", "union", "subscriptions"]
}
isolated function testInterceptorsWithSubscribersRunSimultaniously2() returns error? {
    final string document = check common:getGraphqlDocumentFromFile("interceptors_with_subscription_return_union_type");
    string url = "ws://localhost:9091/subscription_interceptor4";
    websocket:ClientConfiguration config = {subProtocols: [common:GRAPHQL_TRANSPORT_WS]};
    final websocket:Client wsClient1 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient1);

    final websocket:Client wsClient2 = check new (url, config);
    check common:initiateGraphqlWsConnection(wsClient2);

    worker A returns error? {
        check common:sendSubscriptionMessage(wsClient1, document, "1", operationName = "unionTypes1");
        json expectedMsgPayload = {
            data: {
                multipleValues1: {
                    id: 100,
                    name: "Jesse Pinkman"
                }
            }
        };
        check common:validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        expectedMsgPayload = {
            data: {
                multipleValues1: {
                    name: "Walter White",
                    subject: "Physics"
                }
            }
        };
        check common:validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
    }
    worker B returns error? {
        check common:sendSubscriptionMessage(wsClient2, document, "2", operationName = "unionTypes1");
        json expectedMsgPayload = {
            data: {
                multipleValues1: {
                    id: 100,
                    name: "Jesse Pinkman"
                }
            }
        };
        check common:validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
        expectedMsgPayload = {
            data: {
                multipleValues1: {
                    name: "Walter White",
                    subject: "Physics"
                }
            }
        };
        check common:validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    }
    check wait A;
    check wait B;
}
