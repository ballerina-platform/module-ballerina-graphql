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

import ballerina/test;
import ballerina/websocket;

@test:Config {
    groups: ["interceptors"],
    dataProvider: dataProviderInterceptors
}
isolated function testInterceptors(string url, string resourceFileName) returns error? {
    string document = check getGraphqlDocumentFromFile(resourceFileName);
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(resourceFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderInterceptors() returns string[][] {
    string url1 = "http://localhost:9091/intercept_service_obj";
    string url2 = "http://localhost:9091/intercept_arrays";
    string url3 = "http://localhost:9091/intercept_records";
    string url4 = "http://localhost:9091/invalid_interceptor1";
    string url5 = "http://localhost:9091/invalid_interceptor2";
    string url6 = "http://localhost:9091/invalid_interceptor3";
    string url7 = "http://localhost:9091/invalid_interceptor4";
    string url8 = "http://localhost:9091/intercept_errors1";
    string url9 = "http://localhost:9091/intercept_errors2";
    string url10 = "http://localhost:9091/intercept_errors3";
    string url11 = "http://localhost:9091/intercept_erros_with_hierarchical";
    string url12 = "http://localhost:9091/interceptors_with_null_values3";
    string url13 = "http://localhost:9091/intercept_enum";
    string url14 = "http://localhost:9091/intercept_int";
    string url15 = "http://localhost:9091/intercept_order";
    string url16 = "http://localhost:9091/intercept_hierarchical";
    string url17 = "http://localhost:9091/mutation_interceptor";
    string url18 = "http://localhost:9091/interceptors_with_null_values1";
    string url19 = "http://localhost:9091/interceptors_with_null_values2";
    string url20 = "http://localhost:9091/intercept_record_fields";
    string url21 = "http://localhost:9091/intercept_map";
    string url22 = "http://localhost:9091/intercept_table";
    string url23 = "http://localhost:9091/intercept_string";
    string url24 = "http://localhost:9091/intercept_service_obj_array1";
    string url25 = "http://localhost:9091/intercept_service_obj_array2";
    string url26 = "http://localhost:9092/intercept_unions";

    return [
        [url1, "interceptors_with_service_object"],
        [url2, "interceptors_with_arrays"],
        [url3, "interceptors_with_records"],
        [url4, "interceptors_with_invalid_destructive_modification1"],
        [url5, "interceptors_with_invalid_destructive_modification2"],
        [url6, "interceptors_with_invalid_destructive_modification3"],
        [url7, "interceptors_with_invalid_destructive_modification4"],
        [url8, "interceptors_returning_error1"],
        [url9, "interceptors_returning_error2"],
        [url10, "interceptors_returning_error3"],
        [url11, "interceptors_returning_errors_with_hierarchical_resources"],
        [url12, "interceptors_returning_invalid_value"],
        [url1, "interceptors_with_fragments"],
        [url13, "interceptors_with_enum"],
        [url14, "duplicate_interceptors"],
        [url15, "interceptor_execution_order"],
        [url16, "interceptors_with_hierarchical_paths"],
        [url17, "interceptors_with_mutation"],
        [url18, "interceptors_with_null_value1"],
        [url19, "interceptors_with_null_value2"],
        [url20, "interceptors_with_record_fields"],
        [url20, "interceptors_with_records_and_fragments"],
        [url21, "interceptors_with_map"],
        [url22, "interceptors_with_table"],
        [url23, "interceptors"],
        [url24, "interceptors_with_destructive_modification1"],
        [url25, "interceptors_with_destructive_modification2"],
        [url26, "interceptors_with_union"],
        [url14, "execute_same_interceptor_multiple_times"],
        [url17, "resource_interceptors"]
    ];
}

@test:Config {
    groups: ["interceptors", "subscriptions"],
    enable: false
}
isolated function testInterceptorsWithSubscriptionReturningScalar() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9099/subscription_interceptor1";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient1);
    check sendSubscriptionMessage(wsClient1, document, "1");

    websocket:Client wsClient2 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient2);
    check sendSubscriptionMessage(wsClient2, document, "2");

    foreach int i in 1 ..< 4 {
        json expectedMsgPayload = {data: {messages: (i * 5 - 5) * 5 - 5}};
        check validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        check validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    }
}

@test:Config {
    groups: ["interceptors", "subscriptions", "records"],
    enable: false
}
isolated function testInterceptorsWithSubscriptionReturningRecord() returns error? {
    string document = check getGraphqlDocumentFromFile("interceptors_with_subscription_return_records");
    string url = "ws://localhost:9099/subscription_interceptor2";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient1);
    check sendSubscriptionMessage(wsClient1, document, operationName = "A");
    json expectedMsgPayload = {data: {books: {name: "Crime and Punishment", author: "Athur Conan Doyle"}}};
    check validateNextMessage(wsClient1, expectedMsgPayload);
    expectedMsgPayload = {data: {books: {name: "A Game of Thrones", author: "Athur Conan Doyle"}}};
    check validateNextMessage(wsClient1, expectedMsgPayload);

    websocket:Client wsClient2 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient2);
    check sendSubscriptionMessage(wsClient2, document, operationName = "B");
    expectedMsgPayload = {data: {newBooks: {name: "A Game of Thrones", author: "George R.R. Martin"}}};
    check validateNextMessage(wsClient2, expectedMsgPayload);
}

@test:Config {
    groups: ["interceptors", "fragments", "subscriptions"],
    enable: false
}
isolated function testInterceptorsWithSubscriptionAndFragments() returns error? {
    string document = check getGraphqlDocumentFromFile("interceptors_with_fragments_and_subscription");
    string url = "ws://localhost:9099/subscription_interceptor3";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient1);
    check sendSubscriptionMessage(wsClient1, document, operationName = "getStudents");
    json expectedMsgPayload = {data: {students: {id: 1, name: "Harry Potter"}}};
    check validateNextMessage(wsClient1, expectedMsgPayload);
    expectedMsgPayload = {data: {students: {id: 2, name: "Harry Potter"}}};
    check validateNextMessage(wsClient1, expectedMsgPayload);

    websocket:Client wsClient2 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient2);
    check sendSubscriptionMessage(wsClient2, document, operationName = "getNewStudents");
    expectedMsgPayload = {data: {newStudents: {id: 4, name: "Ron Weasley"}}};
    check validateNextMessage(wsClient2, expectedMsgPayload);
}

@test:Config {
    groups: ["interceptors", "union", "subscriptions"],
    enable: false
}
isolated function testInterceptorsWithUnionTypeSubscription() returns error? {
    string document = check getGraphqlDocumentFromFile("interceptors_with_subscription_return_union_type");
    string url = "ws://localhost:9099/subscription_interceptor4";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient1);
    check sendSubscriptionMessage(wsClient1, document, operationName = "unionTypes1");
    json expectedMsgPayload = {
        data: {
            multipleValues1: {
                id: 100,
                name: "Jesse Pinkman"
            }
        }
    };
    check validateNextMessage(wsClient1, expectedMsgPayload);
    expectedMsgPayload = {
        data: {
            multipleValues1: {
                name: "Walter White",
                subject: "Physics"
            }
        }
    };
    check validateNextMessage(wsClient1, expectedMsgPayload);

    websocket:Client wsClient2 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient2);
    check sendSubscriptionMessage(wsClient2, document, operationName = "unionTypes2");
    expectedMsgPayload = {
        data: {
            multipleValues2: {
                name: "Walter White",
                subject: "Chemistry"
            }
        }
    };
    check validateNextMessage(wsClient2, expectedMsgPayload);
}

@test:Config {
    groups: ["interceptors", "subscriptions"],
    enable: false
}
isolated function testInterceptorsReturnBeforeResolverWithSubscription() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9099/subscription_interceptor5";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient1);
    check sendSubscriptionMessage(wsClient1, document, "1");

    websocket:Client wsClient2 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient2);
    check sendSubscriptionMessage(wsClient2, document, "2");

    json expectedMsgPayload = {data: {messages: 1}};
    foreach int i in 1 ..< 4 {
        check validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        check validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    }
}

@test:Config {
    groups: ["interceptors", "subscriptions"],
    enable: false
}
isolated function testInterceptorsDestructiveModificationWithSubscription() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9099/subscription_interceptor6";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient1);
    check sendSubscriptionMessage(wsClient1, document, "1");

    websocket:Client wsClient2 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient2);
    check sendSubscriptionMessage(wsClient2, document, "2");

    json expectedMsgPayload = {
        errors: [
            {
                message:"Invalid return type in Interceptor \"DestructiveModification\". Expected type Int!",
                locations:[
                    {
                        line:1,
                        column:16
                    }
                ],
                path:[
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
        check validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        check validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    }
}

@test:Config {
    groups: ["interceptors", "subscriptions"],
    enable: false
}
isolated function testInterceptorsWithSubscribersRunSimultaniously1() returns error? {
    final string document = string `subscription { messages }`;
    string url = "ws://localhost:9099/subscription_interceptor1";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    final websocket:Client wsClient1 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient1);

    final websocket:Client wsClient2 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient2);

    final websocket:Client wsClient3 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient3);

    worker A returns error? {
        check sendSubscriptionMessage(wsClient1, document, "1");
        foreach int i in 1 ..< 4 {
            json expectedMsgPayload = {data: {messages: (i * 5 - 5) * 5 - 5}};
            check validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        }
    }
    worker B returns error? {
        check sendSubscriptionMessage(wsClient2, document, "2");
        foreach int i in 1 ..< 4 {
            json expectedMsgPayload = {data: {messages: (i * 5 - 5) * 5 - 5}};
            check validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
        }
    }
    check sendSubscriptionMessage(wsClient3, document, "3");
    foreach int i in 1 ..< 4 {
        json expectedMsgPayload = {data: {messages: (i * 5 - 5) * 5 - 5}};
        check validateNextMessage(wsClient3, expectedMsgPayload, id = "3");
    }
    check wait A;
    check wait B;
}

@test:Config {
    groups: ["interceptors", "union", "subscriptions"],
    enable: false
}
isolated function testInterceptorsWithSubscribersRunSimultaniously2() returns error? {
    final string document = check getGraphqlDocumentFromFile("interceptors_with_subscription_return_union_type");
    string url = "ws://localhost:9099/subscription_interceptor4";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    final websocket:Client wsClient1 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient1);

    final websocket:Client wsClient2 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient2);

    worker A returns error? {
        check sendSubscriptionMessage(wsClient1, document, "1", operationName = "unionTypes1");
        json expectedMsgPayload = {
            data: {
                multipleValues1: {
                    id: 100,
                    name: "Jesse Pinkman"
                }
            }
        };
        check validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        expectedMsgPayload = {
            data: {
                multipleValues1: {
                    name: "Walter White",
                    subject: "Physics"
                }
            }
        };
        check validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
    }
    worker B returns error? {
        check sendSubscriptionMessage(wsClient2, document, "2", operationName = "unionTypes1");
        json expectedMsgPayload = {
            data: {
                multipleValues1: {
                    id: 100,
                    name: "Jesse Pinkman"
                }
            }
        };
        check validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
        expectedMsgPayload = {
            data: {
                multipleValues1: {
                    name: "Walter White",
                    subject: "Physics"
                }
            }
        };
        check validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    }
    check wait A;
    check wait B;
}
