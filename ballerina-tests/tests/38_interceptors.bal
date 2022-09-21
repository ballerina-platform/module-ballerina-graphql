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
    string url = "http://localhost:9091/intercept_hierachical";
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
    websocket:Client wsClient1 = check new(url);
    websocket:Client wsClient2 = check new(url);
    check writeWebSocketTextMessage(document, wsClient1);
    check writeWebSocketTextMessage(document, wsClient2);
    foreach int i in 1 ..< 4 {
        json expectedPayload = {data: {messages: i * 5 - 5}};
        check validateWebSocketResponse(wsClient1, expectedPayload);
        check validateWebSocketResponse(wsClient2, expectedPayload);
    }
}

@test:Config {
    groups: ["interceptors", "subscriptions", "records"]
}
isolated function testInterceptorsWithSubscriptionReturningRecord() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_records.graphql");
    string url = "ws://localhost:9099/subscription_interceptor2";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = {data: {books: {name: "Crime and Punishment", author: "Athur Conan Doyle"}}};
    check validateWebSocketResponse(wsClient, expectedPayload);
    expectedPayload = {data: {books: {name: "A Game of Thrones", author: "Athur Conan Doyle"}}};
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "fragments", "subscriptions"]
}
isolated function testInterceptorsWithSubscriptionAndFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_fragments.graphql");
    string url = "ws://localhost:9099/subscription_interceptor3";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = {data: {students: {id: 1, name: "Harry Potter"}}};
    check validateWebSocketResponse(wsClient, expectedPayload);
    expectedPayload = {data: {students: {id: 2, name: "Harry Potter"}}};
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "union", "subscriptions"]
}
isolated function testInterceptorsWithUnionTypeSubscription() returns error? {
    string document = check getGraphQLDocumentFromFile("subscriptions_with_union_type.graphql");
    string url = "ws://localhost:9099/subscription_interceptor4";
    websocket:Client wsClient = check new(url);
    check writeWebSocketTextMessage(document, wsClient);
    json expectedPayload = {
        data: {
            multipleValues: {
                id: 100,
                name: "Jesse Pinkman"
            }
        }
    };
    check validateWebSocketResponse(wsClient, expectedPayload);
    expectedPayload = {
        data: {
            multipleValues: {
                name: "Walter White",
                subject: "Physics"
            }
        }
    };
    check validateWebSocketResponse(wsClient, expectedPayload);
}

@test:Config {
    groups: ["interceptors", "subscriptions"]
}
isolated function testInterceptorsReturnBeforeResolverWithSubscription() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9099/subscription_interceptor5";
    websocket:Client wsClient1 = check new(url);
    websocket:Client wsClient2 = check new(url);
    check writeWebSocketTextMessage(document, wsClient1);
    check writeWebSocketTextMessage(document, wsClient2);
    json expectedPayload = {data: {messages: 1}};
    foreach int i in 1 ..< 4 {
        check validateWebSocketResponse(wsClient1, expectedPayload);
        check validateWebSocketResponse(wsClient2, expectedPayload);
    }
}

@test:Config {
    groups: ["interceptors", "subscriptions"]
}
isolated function testInterceptorsDestructiveModificationWithSubscription() returns error? {
    string document = string `subscription { messages }`;
    string url = "ws://localhost:9099/subscription_interceptor6";
    websocket:Client wsClient1 = check new(url);
    websocket:Client wsClient2 = check new(url);
    check writeWebSocketTextMessage(document, wsClient1);
    check writeWebSocketTextMessage(document, wsClient2);
    json expectedPayload = {
        errors:[
            {
                message: "Invalid return type in Interceptor \"DestructiveModification\". Expected type Int!",
                locations: [
                    {
                        line:1,
                        column:16
                    }
                ],
                path: ["messages"]
            }
        ],
        data:null
    };
    foreach int i in 1 ..< 4 {
        check validateWebSocketResponse(wsClient1, expectedPayload);
        check validateWebSocketResponse(wsClient2, expectedPayload);
    }
}

@test:Config {
    groups: ["interceptors", "subscriptions"]
}
isolated function testInterceptorsWithSubscribersRunSimultaniously1() returns error? {
    final string document = string `subscription { messages }`;
    string url = "ws://localhost:9099/subscription_interceptor1";
    final websocket:Client wsClient1 = check new(url);
    final websocket:Client wsClient2 = check new(url);
    final websocket:Client wsClient3 = check new(url);
    worker A returns error? {
        check writeWebSocketTextMessage(document, wsClient1);
        foreach int i in 1 ..< 4 {
            json expectedPayload = {data: {messages: i * 5 - 5}};
            check validateWebSocketResponse(wsClient1, expectedPayload);
        }
    }
    worker B returns error? {
        check writeWebSocketTextMessage(document, wsClient2);
        foreach int i in 1 ..< 4 {
            json expectedPayload = {data: {messages: i * 5 - 5}};
            check validateWebSocketResponse(wsClient2, expectedPayload);
        }
    }
    check writeWebSocketTextMessage(document, wsClient3);
    foreach int i in 1 ..< 4 {
        json expectedPayload = {data: {messages: i * 5 - 5}};
        check validateWebSocketResponse(wsClient3, expectedPayload);
    }
}

@test:Config {
    groups: ["interceptors", "union", "subscriptions"]
}
isolated function testInterceptorsWithSubscribersRunSimultaniously2() returns error? {
    final string document = check getGraphQLDocumentFromFile("subscriptions_with_union_type.graphql");
    string url = "ws://localhost:9099/subscription_interceptor4";
    final websocket:Client wsClient1 = check new(url);
    final websocket:Client wsClient2 = check new(url);
    worker A returns error? {
        check writeWebSocketTextMessage(document, wsClient1);
        json expectedPayload = {
            data: {
                multipleValues: {
                    id: 100,
                    name: "Jesse Pinkman"
                }
            }
        };
        check validateWebSocketResponse(wsClient1, expectedPayload);
        expectedPayload = {
            data: {
                multipleValues: {
                    name: "Walter White",
                    subject: "Physics"
                }
            }
        };
        check validateWebSocketResponse(wsClient1, expectedPayload);
    }
    worker B returns error? {
        check writeWebSocketTextMessage(document, wsClient2);
        json expectedPayload = {
            data: {
                multipleValues: {
                    id: 100,
                    name: "Jesse Pinkman"
                }
            }
        };
        check validateWebSocketResponse(wsClient2, expectedPayload);
        expectedPayload = {
            data: {
                multipleValues: {
                    name: "Walter White",
                    subject: "Physics"
                }
            }
        };
        check validateWebSocketResponse(wsClient2, expectedPayload);
    }
}
