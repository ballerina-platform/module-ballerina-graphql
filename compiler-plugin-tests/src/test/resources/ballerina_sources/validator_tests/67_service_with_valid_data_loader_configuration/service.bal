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
        ctx.registerDataLoader("bookLoader", new dataloader:DefaultDataLoader(bookLoaderFunction));
        return ctx;
    }
}
service on new graphql:Listener(9090) {
    resource function get authors(int[] ids) returns Author[] {
        return [];
    }

    function preUpdateAuthor(graphql:Context ctx, int id) {
        dataloader:DataLoader authorLoader = ctx.getDataLoader("authorLoader");
        authorLoader.add(id);
    }
    
    remote function updateAuthor(graphql:Context ctx, int id, string name) returns Author|error {
        return error("No implementation provided for updateAuthor");
    }
}

isolated distinct service class Author {
    isolated function preBooks(graphql:Context ctx) {
        dataloader:DataLoader bookLoader = ctx.getDataLoader("bookLoader");
        bookLoader.add(1);
    }

    isolated resource function get books(graphql:Context ctx) returns Book[] {
        return [];
    }
}

isolated function bookLoaderFunction(readonly & anydata[] ids) returns Book[][] {
    return [];
};

isolated function authorLoaderFunction(readonly & anydata[] ids) returns AuthorData[] {
    return [];
};

public type Book record {|
    string title;
|};

type AuthorData record {|
    string name;
|};
