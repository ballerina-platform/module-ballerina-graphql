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

service on new graphql:Listener(9090) {
    resource function get authors(map<dataloader:DataLoader> loaders, int[] ids) returns Author[]|error {
        return error("No implementation provided for authors");
    }

    @dataloader:Loader {
        batchFunctions: {"authorLoader": authorLoaderFunction}
    }
    resource function get loadAuthors(map<dataloader:DataLoader> loaders, int[] ids) {
    }

    remote function updateAuthorName(map<dataloader:DataLoader> loaders, int id, string name) returns Author|error {
        return error("No implementation provided for updateAuthorName");
    }

    @dataloader:Loader {
        batchFunctions: {"authorUpdateLoader": authorUpdateLoaderFunction}
    }
    remote function loadUpdateAuthorName(map<dataloader:DataLoader> loaders, int id, string name) {
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

    isolated resource function get books(map<dataloader:DataLoader> loaders) returns Book[]|error {
        return error("No implementation provided for books");
    }

    @dataloader:Loader {
        batchFunctions: {"bookLoader": bookLoaderFunction}
    }
    isolated resource function get loadBooks(map<dataloader:DataLoader> loaders) {
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
