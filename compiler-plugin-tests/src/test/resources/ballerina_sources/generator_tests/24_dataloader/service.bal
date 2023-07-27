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
import ballerina/graphql.dataloader;
import ballerina/http;

@graphql:ServiceConfig {
    contextInit: isolated function (http:RequestContext requestContext, http:Request request) returns graphql:Context|error {
        graphql:Context ctx = new;
        ctx.registerDataLoader("authorLoader", new dataloader:DefaultDataLoader(authorLoaderFunction));
        ctx.registerDataLoader("authorUpdateLoader", new dataloader:DefaultDataLoader(authorUpdateLoaderFunction));
        ctx.registerDataLoader("bookLoader", new dataloader:DefaultDataLoader(bookLoaderFunction));
        return ctx;
    }
}
service on new graphql:Listener(9090) {
    resource function get authors(graphql:Context ctx, int[] ids) returns Author[]|error {
        return error("No implementation provided for authors");
    }

    function preAuthors(graphql:Context ctx, int[] ids) {
    }

    remote function updateAuthorName(graphql:Context ctx, int id, string name) returns Author|error {
        return error("No implementation provided for updateAuthorName");
    }

    function preUpdateAuthorName(graphql:Context ctx, int id, string name) {
    }
}

isolated distinct service class Author {
    private final readonly & AuthorRow author;

    isolated function init(AuthorRow author) {
        self.author = author.cloneReadOnly();
    }

    isolated resource function get name() returns string {
        return self.author.name;
    }

    isolated resource function get books(graphql:Context ctx) returns Book[]|error {
        return error("No implementation provided for books");
    }

    isolated function preBooks(graphql:Context ctx) {
    }
}

isolated distinct service class Book {
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

isolated function authorLoaderFunction(readonly & anydata[] ids) returns AuthorRow[]|error {
    return [];
};

isolated function bookLoaderFunction(readonly & anydata[] ids) returns BookRow[][]|error {
    return [];
};

isolated function authorUpdateLoaderFunction(readonly & anydata[] idNames) returns AuthorRow[]|error {
    return [];
};

public type BookRow record {
    readonly int id;
    string title;
    int author;
};

public type AuthorRow record {
    readonly int id;
    string name;
};
