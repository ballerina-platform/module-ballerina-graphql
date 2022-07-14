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

readonly service class ServiceInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context ctx, graphql:Field 'field) returns anydata|error {
        anydata|error result = ctx.resolve('field);
        return result;
    }

    isolated resource function get name(int id) returns string {
        if id < 10 {
            return "Ballerina";
        }
        return "GraphQL";
    }

    isolated remote function updateName(string name) returns string {
        if name == "gql" {
            return "GraphQL";
        }
        return "Ballerina";
    }
}

@graphql:ServiceConfig {
    interceptors: [new ServiceInterceptor()]
}
service /graphql on new graphql:Listener(4000) {
    isolated resource function get greeting() returns string {
        return "Hello, world";
    }
}
