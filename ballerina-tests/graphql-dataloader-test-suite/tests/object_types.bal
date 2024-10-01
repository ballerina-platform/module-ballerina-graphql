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
import ballerina/graphql.dataloader;

public isolated distinct service class AuthorData {
    private final readonly & AuthorRow author;

    isolated function init(AuthorRow author) {
        self.author = author.cloneReadOnly();
    }

    isolated resource function get name() returns string {
        return self.author.name;
    }

    isolated function preBooks(graphql:Context ctx) {
        dataloader:DataLoader bookLoader = ctx.getDataLoader(BOOK_LOADER);
        bookLoader.add(self.author.id);
    }

    isolated resource function get books(graphql:Context ctx) returns BookData[]|error {
        dataloader:DataLoader bookLoader = ctx.getDataLoader(BOOK_LOADER);
        BookRow[] bookrows = check bookLoader.get(self.author.id);
        return from BookRow bookRow in bookrows
            select new BookData(bookRow);
    }
}

public isolated distinct service class AuthorDetail {
    private final readonly & AuthorRow author;

    isolated function init(AuthorRow author) {
        self.author = author.cloneReadOnly();
    }

    isolated resource function get name() returns string {
        return self.author.name;
    }

    isolated function prefetchBooks(graphql:Context ctx) {
        dataloader:DataLoader bookLoader = ctx.getDataLoader(BOOK_LOADER);
        bookLoader.add(self.author.id);
    }

    @graphql:ResourceConfig {
        interceptors: new BookInterceptor(),
        prefetchMethodName: "prefetchBooks"
    }
    isolated resource function get books(graphql:Context ctx) returns BookData[]|error {
        dataloader:DataLoader bookLoader = ctx.getDataLoader(BOOK_LOADER);
        BookRow[] bookrows = check bookLoader.get(self.author.id);
        return from BookRow bookRow in bookrows
            select new BookData(bookRow);
    }
}

public isolated distinct service class BookData {
    private final readonly & BookRow book;

    isolated function init(BookRow book) {
        self.book = book.cloneReadOnly();
    }

    isolated resource function get id() returns int {
        return self.book.id;
    }

    isolated resource function get title() returns string {
        return self.book.title;
    }
}

public isolated distinct service class AuthorData2 {
    private final readonly & AuthorRow author;

    isolated function init(AuthorRow author) {
        self.author = author.cloneReadOnly();
    }

    isolated resource function get name() returns string {
        return self.author.name;
    }

    isolated function preBooks(graphql:Context ctx) {
        dataloader:DataLoader bookLoader = ctx.getDataLoader(BOOK_LOADER_2);
        bookLoader.add(self.author.id);
    }

    isolated resource function get books(graphql:Context ctx) returns BookData[]|error {
        dataloader:DataLoader bookLoader = ctx.getDataLoader(BOOK_LOADER_2);
        BookRow[] bookrows = check bookLoader.get(self.author.id);
        return from BookRow bookRow in bookrows
            select new BookData(bookRow);
    }
}
