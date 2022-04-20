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

@graphql:ServiceConfig {
    maxQueryDepth: 5
}
isolated service on new graphql:Listener(9000) {

    # Greets the user.
    #
    # + return - The greeting message
    isolated resource function get greeting() returns string {
        return "Hello";
    }

    # Updates the name and returns a profile
    #
    # + name - New name
    # + return - Updated profile
    remote function setName(string name) returns Person {
        return {name: name};
    }
}

isolated service on new graphql:Listener(9001) {
    isolated resource function get greeting() returns string {
        return "Hello";
    }
}

public type Person record {
    string name;
};
