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
    groups: ["interceptors"]
}
isolated function testInterceptors() returns error? {
    string document = string `{ enemy }`;
    string url = "http://localhost:9091/intercept_string";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data:{
            enemy: "Tom Marvolo Riddle - voldemort"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "service"]
}
isolated function testInterceptorsWithServiceObjects() returns error? {
    string document = string `{ teacher{ id, name, subject }}`;
    string url = "http://localhost:9091/intercept_service_obj";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_service_object.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "array"]
}
isolated function testInterceptorsWithArrays() returns error? {
    string document = string `{ houses }`;
    string url = "http://localhost:9091/intercept_arrays";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_arrays.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "records"]
}
isolated function testInterceptorsWithRecords() returns error? {
    string document = string `{ profile{ name, address{ number, street }}}`;
    string url = "http://localhost:9091/intercept_records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_records.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "enums"]
}
isolated function testInterceptorsWithEnums() returns error? {
    string document = string `{ holidays }`;
    string url = "http://localhost:9091/intercept_enum";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            holidays: [SATURDAY, SUNDAY, MONDAY, TUESDAY]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "union"]
}
isolated function testInterceptorsWithUnion() returns error? {
    string document = string `{ profile(id: 4){ ...on StudentService{ id, name }}}`;
    string url = "http://localhost:9092/intercept_unions";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            profile: {
                id: 3,
                name: "Minerva McGonagall"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testExecuteSameInterceptorMultipleTimes() returns error? {
    string document = string `{ age }`;
    string url = "http://localhost:9091/intercept_int";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data:{
            age: 26
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorWithDestructiveModification1() returns error? {
    string document = string `{ students{ id, name }}`;
    string url = "http://localhost:9091/intercept_service_obj_arrays";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            students: [
                {
                    id: 3,
                    name: "Minerva McGonagall"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsWithDestructiveModification2() returns error? {
    string document = string `{ students{ id, name }}`;
    string url = "http://localhost:9091/intercept_service_obj_array";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            students: ["Ballerina","GraphQL"]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsWithHierarchicalPaths() returns error? {
    string document = string `{ name{ first, last } }`;
    string url = "http://localhost:9091/intercept_hierarchical";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            name: {
                first: "Harry",
                last: "Potter"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "fragments"]
}
isolated function testInterceptorsWithFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("interceptors_with_fragments.graphql");
    string url = "http://localhost:9091/intercept_service_obj";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_service_object.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "mutation"]
}
isolated function testInterceptorWithMutation() returns error? {
    string document = string `mutation { setName(name: "Heisenberg") { name } }`;
    string url = "http://localhost:9091/mutation_interceptor";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            setName: {
                name: "Albus Percival Wulfric Brian Dumbledore"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsWithInvalidDestructiveModification1() returns error? {
    string document = string `{ age }`;
    string url = "http://localhost:9091/invalid_interceptor1";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_invalid_destructive_modification1.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsWithInvalidDestructiveModification2() returns error? {
    string document = string `{ friends }`;
    string url = "http://localhost:9091/invalid_interceptor2";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_invalid_destructive_modification2.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsWithInvalidDestructiveModification3() returns error? {
    string document = string `{ person { name, address{ city }}}`;
    string url = "http://localhost:9091/invalid_interceptor3";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_invalid_destructive_modification3.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsWithInvalidDestructiveModification4() returns error? {
    string document = string `{ student{ id, name }}`;
    string url = "http://localhost:9091/invalid_interceptor4";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_invalid_destructive_modification4.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsReturningError1() returns error? {
    string document = string `{ greet }`;
    string url = "http://localhost:9091/intercept_errors1";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_returning_error1.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsReturningError2() returns error? {
    string document = string `{ friends }`;
    string url = "http://localhost:9091/intercept_errors2";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_returning_error2.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsReturningError3() returns error? {
    string document = string `{ person{ name, age } }`;
    string url = "http://localhost:9091/intercept_errors3";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_returning_error3.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorExecutionOrder() returns error? {
    string document = string `{ quote }`;
    string url = "http://localhost:9091/intercept_order";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            quote: "Ballerina is an open-source programming language."
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "hierarchical_paths"]
}
isolated function testInterceptorsReturningErrorsWithHierarchicalResources() returns error? {
    string document = string `{ name, age, address{city, street, number}}`;
    string url = "http://localhost:9091/intercept_erros_with_hierarchical";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_returning_errors_with_hierarchical_resources.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsReturningNullValues1() returns error? {
    string document = string `{ name }`;
    string url = "http://localhost:9091/interceptors_with_null_values1";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            name: null
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsReturningNullValues2() returns error? {
    string document = string `{ name }`;
    string url = "http://localhost:9091/interceptors_with_null_values2";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            name: null
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsReturningInvalidValue() returns error? {
    string document = string `{ name }`;
    string url = "http://localhost:9091/interceptors_with_null_values3";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_returning_invalid_value.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "records"]
}
isolated function testInterceptorsWithRecordFields() returns error? {
    string document = string `{ profile{ name, age, address{ number, street, city }}}`;
    string url = "http://localhost:9091/intercept_record_fields";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            profile: {
                name: "Albus Percival Wulfric Brian Dumbledore",
                age: 80,
                address: {
                    number: "100",
                    street: "Margo Street",
                    city: "London"
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "records", "fragments"]
}
isolated function testInterceptorsWithRecordFieldsAndFragments() returns error? {
    string document = string `{ profile{ name, age, ...P1 }} fragment P1 on Person{ address{ number, street, city }}`;
    string url = "http://localhost:9091/intercept_record_fields";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            profile: {
                name: "Albus Percival Wulfric Brian Dumbledore",
                age: 80,
                address: {
                    number: "100",
                    street: "Margo Street",
                    city: "London"
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "map"]
}
isolated function testInterceptorsWithMap() returns error? {
    string document = check getGraphQLDocumentFromFile("interceptors_with_map.graphql");
    string url = "http://localhost:9091/intercept_map";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data:{
            languages:{
                backend: "Java",
                frontend: "Flutter",
                data: "Ballerina",
                native: "C#"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "table"]
}
isolated function testInterceptorsWithTables() returns error? {
    string document = "{ employees { name } }";
    string url = "http://localhost:9091/intercept_table";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            employees: [
                {
                    name: "Eng. John Doe"
                },
                {
                    name: "Eng. Jane Doe"
                },
                {
                    name: "Eng. Johnny Roe"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "subscriptions"]
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
        json expectedMsgPayload = {data: {messages: i * 5 - 5}};
        check validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        check validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
    }
}

@test:Config {
    groups: ["interceptors", "subscriptions", "records"]
}
isolated function testInterceptorsWithSubscriptionReturningRecord() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_records.graphql");
    string url = "ws://localhost:9099/subscription_interceptor2";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document);
    json expectedMsgPayload = {data: {books: {name: "Crime and Punishment", author: "Athur Conan Doyle"}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {books: {name: "A Game of Thrones", author: "Athur Conan Doyle"}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["interceptors", "fragments", "subscriptions"]
}
isolated function testInterceptorsWithSubscriptionAndFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_fragments.graphql");
    string url = "ws://localhost:9099/subscription_interceptor3";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document);
    json expectedMsgPayload = {data: {students: {id: 1, name: "Harry Potter"}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {data: {students: {id: 2, name: "Harry Potter"}}};
    check validateNextMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["interceptors", "union", "subscriptions"]
}
isolated function testInterceptorsWithUnionTypeSubscription() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_union_type.graphql");
    string url = "ws://localhost:9099/subscription_interceptor4";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document);
    json expectedMsgPayload = {
        data: {
            multipleValues: {
                id: 100,
                name: "Jesse Pinkman"
            }
        }
    };
    check validateNextMessage(wsClient, expectedMsgPayload);
    expectedMsgPayload = {
        data: {
            multipleValues: {
                name: "Walter White",
                subject: "Physics"
            }
        }
    };
    check validateNextMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["interceptors", "subscriptions"]
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
    groups: ["interceptors", "subscriptions"]
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
    groups: ["interceptors", "subscriptions"]
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
            json expectedMsgPayload = {data: {messages: i * 5 - 5}};
            check validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        }
    }
    worker B returns error? {
        check sendSubscriptionMessage(wsClient2, document, "2");
        foreach int i in 1 ..< 4 {
            json expectedMsgPayload = {data: {messages: i * 5 - 5}};
            check validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
        }
    }
    check sendSubscriptionMessage(wsClient3, document, "3");
    foreach int i in 1 ..< 4 {
        json expectedMsgPayload = {data: {messages: i * 5 - 5}};
        check validateNextMessage(wsClient3, expectedMsgPayload, id = "3");
    }
    check wait A;
    check wait B;
}

@test:Config {
    groups: ["interceptors", "union", "subscriptions"]
}
isolated function testInterceptorsWithSubscribersRunSimultaniously2() returns error? {
    final string document = check getGraphQLDocumentFromFile("subscriptions_with_union_type.graphql");
    string url = "ws://localhost:9099/subscription_interceptor4";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    final websocket:Client wsClient1 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient1);

    final websocket:Client wsClient2 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient2);

    worker A returns error? {
        check sendSubscriptionMessage(wsClient1, document, "1");
        json expectedMsgPayload = {
            data: {
                multipleValues: {
                    id: 100,
                    name: "Jesse Pinkman"
                }
            }
        };
        check validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
        expectedMsgPayload = {
            data: {
                multipleValues: {
                    name: "Walter White",
                    subject: "Physics"
                }
            }
        };
        check validateNextMessage(wsClient1, expectedMsgPayload, id = "1");
    }
    worker B returns error? {
        check sendSubscriptionMessage(wsClient2, document, "2");
        json expectedMsgPayload = {
            data: {
                multipleValues: {
                    id: 100,
                    name: "Jesse Pinkman"
                }
            }
        };
        check validateNextMessage(wsClient2, expectedMsgPayload, id = "2");
        expectedMsgPayload = {
            data: {
                multipleValues: {
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
