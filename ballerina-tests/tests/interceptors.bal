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

readonly service class StringInterceptor1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string {
            return string `Tom ${result}`;
        }
        return result;
    }
}

readonly service class StringInterceptor2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string && 'field.getAlias().equalsIgnoreCaseAscii("enemy") {
            return string `Marvolo ${result}`;
        }
        return result;
    }
}
 
readonly service class StringInterceptor3 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string {
            return string `Riddle - ${result}`;
        }
        return result;
    }
}

readonly service class RecordInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is record{} {
            return {
                name: "Rubeus Hagrid",
                age: 70,
                address: {number: "103", street: "Mould-on-the-Wold", city: "London"}
            };
        }
        return result;
    }
}

readonly service class ArrayInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string[] {
            result.push("Slytherin(Water)");
        }
        return result;
    }
}

readonly service class EnumInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string[] {
            result.push(MONDAY);
            result.push(TUESDAY);
            return result;
        }
        return result;
    }
}

readonly service class UnionInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is record {} {
            return {id: 3, name: "Minerva McGonagall", subject: "Transfiguration"};
        }
        return result;
    }
}

readonly service class ServiceObjectInterceptor1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is record{} {
            return {id: 3, name: "Minerva McGonagall", subject: "Transfiguration"};
        }
        return result;
    }
}

readonly service class ServiceObjectInterceptor2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is anydata[] {
            return ["Ballerina", "GraphQL"];
        }
        return result;
    }
}

readonly service class Counter {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is int {
            return result + 1;
        }
        return result;
    }
}

readonly service class Destruct {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is anydata[] {
            return [{id: 3, name: "Minerva McGonagall", subject: "Transfiguration"}];
        }
        return result;
    }
}

readonly service class HierarchycalPath {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string && 'field.getName().equalsIgnoreCaseAscii("first") {
            return "Harry";
        } else if result is string && 'field.getName().equalsIgnoreCaseAscii("last") {
            return "Potter";
        }
        return result;
    }
}

readonly service class InterceptMutation {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is record{} {
            return {
                name: "Albus Percival Wulfric Brian Dumbledore"
            };
        }
        return result;
    }
}

readonly service class InvalidInterceptor1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is graphql:ErrorDetail {
            return {
                name: "Albus Percival Wulfric Brian Dumbledore",
                age: 80,
                address: {number: "103", street: "Mould-on-the-Wold", city: "London"}
            };
        }
        return result;
    }
}

readonly service class InvalidInterceptor2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is int {
            return ["Ballerina", "GraphQL"];
        }
        return result;
    }
}

readonly service class InvalidInterceptor3 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is record{} {
            return "Harry Potter";
        }
        return result;
    }
}

readonly service class InvalidInterceptor4 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is anydata[] {
            return {
                name: "Albus Percival Wulfric Brian Dumbledore",
                age: 80,
                address: {number: "103", street: "Mould-on-the-Wold", city: "London"}
            };
        }
        return result;
    }
}

readonly service class InvalidInterceptor5 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is record{} {
            return "Harry Potter";
        }
        return result;
    }
}

readonly service class InvalidInterceptor6 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is record{} {
            return ["Ballerina", "GraphQL"];
        }
        return result;
    }
}

readonly service class InvalidInterceptor7 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is record {}|string {
            return {id: 5, name: "Jessie"};
        }
        return result;
    }
}

readonly service class ErrorInterceptor1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        error interceptorError = error("This field is not accessible!");
        return interceptorError;
    }
}

readonly service class Execution1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var subject = check context.get("subject");
        var result = context.resolve('field);
        if subject is string && result is string {
            return string `${subject} ${result} language.`;
        }
        return result;
    }
}

readonly service class Execution2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var beVerb = check context.get("beVerb");
        var result = context.resolve('field);
        if result is string && beVerb is string {
            return string `${beVerb} ${result} programming`;
        }
        return result;
    }
}

readonly service class AccessGrant {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        if self.grantAccess('field.getName()) {
            return context.resolve('field);
        }
        return error("Access denied!");
    }

    isolated function grantAccess(string fieldName) returns boolean {
        string[] restrictedFields = ["age", "number", "street"];
        if restrictedFields.indexOf(fieldName) is int {
            return false;
        }
        return true;
    }
}

readonly service class NullReturn {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        _ = context.resolve('field);
        return;
    }
}
