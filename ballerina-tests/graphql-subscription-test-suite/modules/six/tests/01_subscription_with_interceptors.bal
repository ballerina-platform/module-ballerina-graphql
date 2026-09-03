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

import ballerina/graphql;
import ballerina/graphql_test_common as common;
import ballerina/test;

type MessagesResponse record {|
    record {| int messages; |} data;
|};

// The destructive interceptor makes every `messages` event carry a `{data: null, errors: [...]}`
// execution result, so `data` is always nil here rather than being bound to `json`.
type MessagesErrorResponse record {|
    () data;
    graphql:ErrorDetail[] errors;
|};

type BooksResponse record {|
    record {| Book books; |} data;
|};

type NewBooksResponse record {|
    record {| Book newBooks; |} data;
|};

type Student record {|
    int id;
    string name;
|};

type StudentsResponse record {|
    record {| Student students; |} data;
|};

type NewStudentsResponse record {|
    record {| Student newStudents; |} data;
|};

type PersonData record {|
    int id?;
    string name;
    string subject?;
|};

type MultipleValues1Response record {|
    record {| PersonData multipleValues1; |} data;
|};

type MultipleValues2Response record {|
    record {| PersonData multipleValues2; |} data;
|};

@test:Config {
    groups: ["interceptors", "subscriptions"]
}
isolated function testInterceptorsWithSubscriptionReturningScalar() returns error? {
    string document = string `subscription { messages }`;
    string url = "http://localhost:9091/subscription_interceptor1";
    graphql:Client graphqlClient = check new (url);
    stream<MessagesResponse, graphql:ClientError?> messages = check graphqlClient->subscribe(document);
    foreach int i in 1 ..< 4 {
        record {|MessagesResponse value;|}|graphql:ClientError? event = messages.next();
        test:assertTrue(event is record {|MessagesResponse value;|}, "Expected a messages event");
        if event is record {|MessagesResponse value;|} {
            test:assertEquals(event.value.data.messages, (i * 5 - 5) * 5 - 5);
        }
    }
    check graphqlClient->close();
}

@test:Config {
    groups: ["interceptors", "subscriptions", "records"]
}
isolated function testInterceptorsWithSubscriptionReturningRecord() returns error? {
    string document = check common:getGraphqlDocumentFromFile("interceptors_with_subscription_return_records");
    string url = "http://localhost:9091/subscription_interceptor2";
    graphql:Client graphqlClient = check new (url);

    stream<BooksResponse, graphql:ClientError?> books =
        check graphqlClient->subscribe(document, operationName = "A");
    record {|BooksResponse value;|}|graphql:ClientError? bookEvent = books.next();
    test:assertTrue(bookEvent is record {|BooksResponse value;|}, "Expected a books event");
    if bookEvent is record {|BooksResponse value;|} {
        test:assertEquals(bookEvent.value.data.books, <Book>{name: "Crime and Punishment", author: "Athur Conan Doyle"});
    }
    bookEvent = books.next();
    test:assertTrue(bookEvent is record {|BooksResponse value;|}, "Expected a books event");
    if bookEvent is record {|BooksResponse value;|} {
        test:assertEquals(bookEvent.value.data.books, <Book>{name: "A Game of Thrones", author: "Athur Conan Doyle"});
    }

    stream<NewBooksResponse, graphql:ClientError?> newBooks =
        check graphqlClient->subscribe(document, operationName = "B");
    record {|NewBooksResponse value;|}|graphql:ClientError? newBookEvent = newBooks.next();
    test:assertTrue(newBookEvent is record {|NewBooksResponse value;|}, "Expected a newBooks event");
    if newBookEvent is record {|NewBooksResponse value;|} {
        test:assertEquals(newBookEvent.value.data.newBooks, <Book>{name: "A Game of Thrones", author: "George R.R. Martin"});
    }
    check graphqlClient->close();
}

@test:Config {
    groups: ["interceptors", "fragments", "subscriptions"]
}
isolated function testInterceptorsWithSubscriptionAndFragments() returns error? {
    string document = check common:getGraphqlDocumentFromFile("interceptors_with_fragments_and_subscription");
    string url = "http://localhost:9091/subscription_interceptor3";
    graphql:Client graphqlClient = check new (url);

    stream<StudentsResponse, graphql:ClientError?> students =
        check graphqlClient->subscribe(document, operationName = "getStudents");
    record {|StudentsResponse value;|}|graphql:ClientError? studentEvent = students.next();
    test:assertTrue(studentEvent is record {|StudentsResponse value;|}, "Expected a students event");
    if studentEvent is record {|StudentsResponse value;|} {
        test:assertEquals(studentEvent.value.data.students, <Student>{id: 1, name: "Harry Potter"});
    }
    studentEvent = students.next();
    test:assertTrue(studentEvent is record {|StudentsResponse value;|}, "Expected a students event");
    if studentEvent is record {|StudentsResponse value;|} {
        test:assertEquals(studentEvent.value.data.students, <Student>{id: 2, name: "Harry Potter"});
    }

    stream<NewStudentsResponse, graphql:ClientError?> newStudents =
        check graphqlClient->subscribe(document, operationName = "getNewStudents");
    record {|NewStudentsResponse value;|}|graphql:ClientError? newStudentEvent = newStudents.next();
    test:assertTrue(newStudentEvent is record {|NewStudentsResponse value;|}, "Expected a newStudents event");
    if newStudentEvent is record {|NewStudentsResponse value;|} {
        test:assertEquals(newStudentEvent.value.data.newStudents, <Student>{id: 4, name: "Ron Weasley"});
    }
    check graphqlClient->close();
}

@test:Config {
    groups: ["interceptors", "union", "subscriptions"]
}
isolated function testInterceptorsWithUnionTypeSubscription() returns error? {
    string document = check common:getGraphqlDocumentFromFile("interceptors_with_subscription_return_union_type");
    string url = "http://localhost:9091/subscription_interceptor4";
    graphql:Client graphqlClient = check new (url);

    stream<MultipleValues1Response, graphql:ClientError?> unionTypes1 =
        check graphqlClient->subscribe(document, operationName = "unionTypes1");
    record {|MultipleValues1Response value;|}|graphql:ClientError? event1 = unionTypes1.next();
    test:assertTrue(event1 is record {|MultipleValues1Response value;|}, "Expected a multipleValues1 event");
    if event1 is record {|MultipleValues1Response value;|} {
        test:assertEquals(event1.value.data.multipleValues1, <PersonData>{id: 100, name: "Jesse Pinkman"});
    }
    event1 = unionTypes1.next();
    test:assertTrue(event1 is record {|MultipleValues1Response value;|}, "Expected a multipleValues1 event");
    if event1 is record {|MultipleValues1Response value;|} {
        test:assertEquals(event1.value.data.multipleValues1, <PersonData>{name: "Walter White", subject: "Physics"});
    }

    stream<MultipleValues2Response, graphql:ClientError?> unionTypes2 =
        check graphqlClient->subscribe(document, operationName = "unionTypes2");
    record {|MultipleValues2Response value;|}|graphql:ClientError? event2 = unionTypes2.next();
    test:assertTrue(event2 is record {|MultipleValues2Response value;|}, "Expected a multipleValues2 event");
    if event2 is record {|MultipleValues2Response value;|} {
        test:assertEquals(event2.value.data.multipleValues2, <PersonData>{name: "Walter White", subject: "Chemistry"});
    }
    check graphqlClient->close();
}

@test:Config {
    groups: ["interceptors", "subscriptions"]
}
isolated function testInterceptorsReturnBeforeResolverWithSubscription() returns error? {
    string document = string `subscription { messages }`;
    string url = "http://localhost:9091/subscription_interceptor5";
    graphql:Client graphqlClient = check new (url);
    stream<MessagesResponse, graphql:ClientError?> messages = check graphqlClient->subscribe(document);
    foreach int i in 1 ..< 4 {
        record {|MessagesResponse value;|}|graphql:ClientError? event = messages.next();
        test:assertTrue(event is record {|MessagesResponse value;|}, "Expected a messages event");
        if event is record {|MessagesResponse value;|} {
            test:assertEquals(event.value.data.messages, 1);
        }
    }
    check graphqlClient->close();
}

@test:Config {
    groups: ["interceptors", "subscriptions"]
}
isolated function testInterceptorsDestructiveModificationWithSubscription() returns error? {
    string document = string `subscription { messages }`;
    string url = "http://localhost:9091/subscription_interceptor6";
    graphql:Client graphqlClient = check new (url);
    // The interceptor returns an invalid type for the resolver, so the server emits `next` messages
    // carrying a `{data: null, errors: [...]}` execution result.
    stream<MessagesErrorResponse, graphql:ClientError?> messages = check graphqlClient->subscribe(document);
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
        record {|MessagesErrorResponse value;|}|graphql:ClientError? event = messages.next();
        test:assertTrue(event is record {|MessagesErrorResponse value;|}, "Expected a messages event");
        if event is record {|MessagesErrorResponse value;|} {
            test:assertEquals(event.value.toJson(), expectedMsgPayload);
        }
    }
    check graphqlClient->close();
}

@test:Config {
    groups: ["interceptors", "subscriptions"]
}
isolated function testInterceptorsWithSubscribersRunSimultaniously1() returns error? {
    final string document = string `subscription { messages }`;
    final string url = "http://localhost:9091/subscription_interceptor1";

    worker A returns error? {
        graphql:Client graphqlClient = check new (url);
        stream<MessagesResponse, graphql:ClientError?> messages = check graphqlClient->subscribe(document);
        foreach int i in 1 ..< 4 {
            record {|MessagesResponse value;|}|graphql:ClientError? event = messages.next();
            test:assertTrue(event is record {|MessagesResponse value;|}, "Expected a messages event");
            if event is record {|MessagesResponse value;|} {
                test:assertEquals(event.value.data.messages, (i * 5 - 5) * 5 - 5);
            }
        }
        check graphqlClient->close();
    }
    worker B returns error? {
        graphql:Client graphqlClient = check new (url);
        stream<MessagesResponse, graphql:ClientError?> messages = check graphqlClient->subscribe(document);
        foreach int i in 1 ..< 4 {
            record {|MessagesResponse value;|}|graphql:ClientError? event = messages.next();
            test:assertTrue(event is record {|MessagesResponse value;|}, "Expected a messages event");
            if event is record {|MessagesResponse value;|} {
                test:assertEquals(event.value.data.messages, (i * 5 - 5) * 5 - 5);
            }
        }
        check graphqlClient->close();
    }
    graphql:Client graphqlClient = check new (url);
    stream<MessagesResponse, graphql:ClientError?> messages = check graphqlClient->subscribe(document);
    foreach int i in 1 ..< 4 {
        record {|MessagesResponse value;|}|graphql:ClientError? event = messages.next();
        test:assertTrue(event is record {|MessagesResponse value;|}, "Expected a messages event");
        if event is record {|MessagesResponse value;|} {
            test:assertEquals(event.value.data.messages, (i * 5 - 5) * 5 - 5);
        }
    }
    check graphqlClient->close();
    check wait A;
    check wait B;
}

@test:Config {
    groups: ["interceptors", "union", "subscriptions"]
}
isolated function testInterceptorsWithSubscribersRunSimultaniously2() returns error? {
    final string document = check common:getGraphqlDocumentFromFile("interceptors_with_subscription_return_union_type");
    final string url = "http://localhost:9091/subscription_interceptor4";

    worker A returns error? {
        graphql:Client graphqlClient = check new (url);
        stream<MultipleValues1Response, graphql:ClientError?> unionTypes1 =
            check graphqlClient->subscribe(document, operationName = "unionTypes1");
        record {|MultipleValues1Response value;|}|graphql:ClientError? event = unionTypes1.next();
        test:assertTrue(event is record {|MultipleValues1Response value;|}, "Expected a multipleValues1 event");
        if event is record {|MultipleValues1Response value;|} {
            test:assertEquals(event.value.data.multipleValues1, <PersonData>{id: 100, name: "Jesse Pinkman"});
        }
        event = unionTypes1.next();
        test:assertTrue(event is record {|MultipleValues1Response value;|}, "Expected a multipleValues1 event");
        if event is record {|MultipleValues1Response value;|} {
            test:assertEquals(event.value.data.multipleValues1, <PersonData>{name: "Walter White", subject: "Physics"});
        }
        check graphqlClient->close();
    }
    worker B returns error? {
        graphql:Client graphqlClient = check new (url);
        stream<MultipleValues1Response, graphql:ClientError?> unionTypes1 =
            check graphqlClient->subscribe(document, operationName = "unionTypes1");
        record {|MultipleValues1Response value;|}|graphql:ClientError? event = unionTypes1.next();
        test:assertTrue(event is record {|MultipleValues1Response value;|}, "Expected a multipleValues1 event");
        if event is record {|MultipleValues1Response value;|} {
            test:assertEquals(event.value.data.multipleValues1, <PersonData>{id: 100, name: "Jesse Pinkman"});
        }
        event = unionTypes1.next();
        test:assertTrue(event is record {|MultipleValues1Response value;|}, "Expected a multipleValues1 event");
        if event is record {|MultipleValues1Response value;|} {
            test:assertEquals(event.value.data.multipleValues1, <PersonData>{name: "Walter White", subject: "Physics"});
        }
        check graphqlClient->close();
    }
    check wait A;
    check wait B;
}
