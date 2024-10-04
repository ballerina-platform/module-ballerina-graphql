// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

readonly service class Multiplication {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is int {
            return result * 5;
        }
        return result;
    }
}

readonly service class Subtraction {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is int {
            return result - 5;
        }
        return result;
    }
}

readonly service class InterceptAuthor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if 'field.getName() == "author" {
            return "Athur Conan Doyle";
        }
        return result;
    }
}

readonly service class InterceptBook {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        _ = context.resolve('field);
        Book b = {name: "A Game of Thrones", author: "George R.R. Martin"};
        return b;
    }
}

readonly service class InterceptStudentName {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if 'field.getName() == "name" {
            return "Harry Potter";
        }
        return result;
    }
}

readonly service class InterceptStudent {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        _ = context.resolve('field);
        return {id: 4, name: "Ron Weasley"};
    }
}

readonly service class InterceptUnionType1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if 'field.getName() == "subject" {
            return "Physics";
        }
        if 'field.getName() == "id" {
            return 100;
        }
        return result;
    }
}

readonly service class InterceptUnionType2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        _ = context.resolve('field);
        return {id: 0, name: "Walter White", subject: "Chemistry"};
    }
}

readonly service class ReturnBeforeResolver {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        return 1;
    }
}

@graphql:InterceptorConfig {
    global: false
}
readonly service class DestructiveModification {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        _ = context.resolve('field);
        return "Ballerina";
    }
}

@graphql:InterceptorConfig {
    global: false
}
readonly service class ServiceLevelInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        if self.grantAccess('field.getName()) {
            return context.resolve('field);
        }
        return error("Access denied!");
    }

    isolated function grantAccess(string fieldName) returns boolean {
        string[] grantedFields = ["profile", "books", "setName", "person", "setAge", "customer", "newBooks", "updatePerson", "person"];
        if grantedFields.indexOf(fieldName) is int {
            return true;
        }
        return false;
    }
}
