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

readonly service class ServiceInterceptor1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context ctx, graphql:Field 'field) returns anydata|error {
        anydata|error result = ctx.resolve('field');
        if result is string {
            return "Hello, Ballerina";
        }
        return result;
    }
}

readonly service class ServiceInterceptor2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context ctx, graphql:Field 'field) returns anydata|error {
        anydata|error result = ctx.resolve('field');
        if result is string {
            return "Hello, GraphQL";
        }
        return result;
    }
}

@graphql:ServiceConfig {
    interceptors: [new ServiceInterceptor1(), new ServiceInterceptor2()]
}
service /graphql on new graphql:Listener(4000) {
    isolated resource function get greeting() returns string {
        return "Hello, world";
    }
}
