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

@graphql:Subgraph
service on new graphql:Listener(4001) {
    resource function get greet() returns string {
        return "welcome";
    }
}

@graphql:Entity {
    key: "email",
    resolveReference: isolated function(graphql:Representation representation) returns User? {
        return new;
    }
}
distinct service class User {
    resource function get email() returns string {
        return "sabthar@wso2.com";
    }

    resource function get name() returns string {
        return "sabthar";
    }
}

@graphql:Entity {
    key: "id",
    resolveReference: isolated function(graphql:Representation representation) returns App? {
        return {id: 1, name: "Demo"};
    }
}
type App record {
    int id;
    string name;
};
