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

import ballerina/graphql;
import ballerina/http;
import ballerina/lang.runtime;

isolated int subscriptionConnectionCount = 0;

isolated function getSubscriptionConnectionCount() returns int {
    lock {
        return subscriptionConnectionCount;
    }
}

isolated function initClientSubscriptionContext(http:RequestContext requestContext, http:Request request)
        returns graphql:Context|error {
    lock {
        subscriptionConnectionCount += 1;
    }
    return new;
}

// A dedicated listener is used for the subscription services: a `graphql:Listener` initializes
// its underlying HTTP listener upon the first service attachment, and subscriptions require
// HTTP/1.1, while the shared listener is initialized with the default HTTP/2.
listener graphql:Listener clientSubscriptionListener = new (9094);

@graphql:ServiceConfig {
    contextInit: initClientSubscriptionContext
}
service /client_subscriptions on clientSubscriptionListener {
    isolated resource function get greet() returns string {
        return "Hello";
    }

    isolated resource function subscribe messages() returns stream<int, error?> {
        return [1, 2, 3, 4, 5].toStream();
    }

    isolated resource function subscribe books() returns stream<Book, error?> {
        Book[] books = [
            {name: "Crime and Punishment", author: "Fyodor Dostoevsky"},
            {name: "A Game of Thrones", author: "George R.R. Martin"}
        ];
        return books.toStream();
    }

    isolated resource function subscribe evergreen() returns stream<int, error?> {
        return new stream<int, error?>(new EvergreenGenerator());
    }

    isolated resource function subscribe slowMessages() returns stream<int, error?> {
        return new stream<int, error?>(new SlowMessageGenerator());
    }
}

// Emits an infinite stream of increasing integers, starting from 1.
isolated class EvergreenGenerator {
    private int index = 0;

    public isolated function next() returns record {|int value;|}|error? {
        runtime:sleep(0.2);
        lock {
            self.index += 1;
            return {value: self.index};
        }
    }
}

// Emits two events with a gap longer than the ping message cadence of the listener (15 seconds)
// to verify that the client keep-alive handling keeps the connection open.
isolated class SlowMessageGenerator {
    private int index = 0;

    public isolated function next() returns record {|int value;|}|error? {
        int currentIndex;
        lock {
            self.index += 1;
            currentIndex = self.index;
        }
        if currentIndex == 1 {
            return {value: 1};
        }
        if currentIndex == 2 {
            runtime:sleep(20);
            return {value: 2};
        }
        return;
    }
}

type MessagesResponse record {|
    map<json?> extensions?;
    record {|int messages;|} data;
|};

type MessagesResponseWithErrors record {|
    map<json?> extensions?;
    record {|int messages;|} data;
    graphql:ErrorDetail[] errors?;
|};

type StringMessagesResponse record {|
    map<json?> extensions?;
    record {|string messages;|} data;
|};

type EvergreenResponse record {|
    map<json?> extensions?;
    record {|int evergreen;|} data;
|};

type BooksResponse record {|
    map<json?> extensions?;
    record {|Book books;|} data;
|};
