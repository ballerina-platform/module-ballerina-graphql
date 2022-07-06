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

    isolated remote function execute(graphql:Context ctx, graphql:RequestInfo reqInfo) returns any|error {
        any|error result = ctx.resolve();
        if result is string {
            return string `Tom ${result}`;
        }
        return result;
    }
}

readonly service class StringInterceptor2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context ctx, graphql:RequestInfo reqInfo) returns any|error {
        any|error result = ctx.resolve();
        if result is string {
            return string `Marvolo ${result}`;
        }
        return result;
    }
}
 
readonly service class StringInterceptor3 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context ctx, graphql:RequestInfo reqInfo) returns any|error {
        any|error result = ctx.resolve();
        if result is string {
            return string `Riddle - ${result}`;
        }
        return result;
    }
}

readonly service class ErrorInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context ctx, graphql:RequestInfo reqInfo) returns any|error {
        error interceptorError = error("This field is not accessible!");
        return interceptorError;
    }
}

readonly service class ArrayInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context ctx, graphql:RequestInfo reqInfo) returns any|error {
        any|error result = ctx.resolve();
        if result is string[] {
            result.push("Slytherin(Water)");
        }
        return result;
    }
}

readonly service class ServiceObjectInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context ctx, graphql:RequestInfo reqInfo) returns any|error {
        any|error result = ctx.resolve();
        if result is TeacherService {
            return new TeacherService(3, "Minerva McGonagall", "Transfiguration");
        }
        return result;
    }
}

readonly service class RecordInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context ctx, graphql:RequestInfo reqInfo) returns any|error {
        any|error result = ctx.resolve();
        if result is Person {
            return {
                name: "Rubeus Hagrid",
                age: 70,
                address: {number: "103", street: "Mould-on-the-Wold", city: "London"}
            };
        }
        return result;
    }
}

readonly service class Counter {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context ctx, graphql:RequestInfo reqInfo) returns any|error {
        any|error result = ctx.resolve();
        if result is int {
            return result + 1;
        }
        return result;
    }
}

readonly service class Destruct {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context ctx, graphql:RequestInfo reqInfo) returns any|error {
        any|error result = ctx.resolve();
        if result is StudentService[] {
            return [new TeacherService(3, "Minerva McGonagall", "Transfiguration")];
        }
        return result;
    }
}

readonly service class InterceptMutation {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context ctx, graphql:RequestInfo reqInfo) returns any|error {
        any|error result = ctx.resolve();
        if result is Person {
            return {
                name: "Albus Percival Wulfric Brian Dumbledore",
                age: result.age,
                address:result.address
            };
        }
        return result;
    }
}
