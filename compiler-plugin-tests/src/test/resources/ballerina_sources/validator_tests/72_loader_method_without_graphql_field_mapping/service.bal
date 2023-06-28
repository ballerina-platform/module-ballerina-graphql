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
    resource function get authors(int[] ids) returns Author[]|error {
        return [];
    }

    @dataloader:Loader {
        batchFunctions: {"bookLoader": bookLoaderFunction}
    }
    remote function loadAuthors(map<dataloader:DataLoader> loaders) {
    }

    @dataloader:Loader {
        batchFunctions: {"bookLoader": bookLoaderFunction}
    }
    isolated resource function get loadBooks(map<dataloader:DataLoader> loaders) {
    }
}

isolated distinct service class Author {
    resource function get name() returns string {
        return "Author";
    }

    @dataloader:Loader {
        batchFunctions: {"bookLoader": bookLoaderFunction}
    }
    isolated resource function get loadBooks(map<dataloader:DataLoader> loaders) {
    }
}

isolated function bookLoaderFunction(readonly & anydata[] ids) returns anydata[]|error {
    return [];
};
