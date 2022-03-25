// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

isolated service on new graphql:Listener(9000) {

    # Greets the user.
    #
    # + context - The GraphQL context object
    # + return - The greeting message
    isolated resource function get greeting(graphql:Context context) returns string {
        var auth = context.get("auth");
        if auth == "admin" {
            return "Hello, admin";
        }
        return "Hello";
    }

    # Uploads a file to the GraphQL server.
    #
    # + upload - The uploaded file information
    # + return - Just a message
    remote function upload(graphql:Upload upload) returns string {
        return "Uploaded";
    }
}
