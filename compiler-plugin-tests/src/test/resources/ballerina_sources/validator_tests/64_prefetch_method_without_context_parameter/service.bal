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

service on new graphql:Listener(9090) {
    resource function get authors(int[] ids) returns Author[] {
        return [];
    }
}

isolated distinct service class Author {
    isolated resource function get books() returns Book[] {
        return [];
    }

    isolated function preBooks() {
    }
}

isolated function bookLoaderFunction(readonly & anydata[] ids) returns anydata[] {
    return [];
};

public type Book record {|
    string title;
|};
