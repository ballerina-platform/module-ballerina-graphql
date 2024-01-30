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
import ballerina/log;

@graphql:InterceptorConfig {
    global: false
}
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

@graphql:InterceptorConfig {
    global: false
}
readonly service class StringInterceptor4 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string {
            return string `Harry Potter ${result}`;
        }
        return result;
    }
}

@graphql:InterceptorConfig {
    global: true
}
readonly service class StringInterceptor5 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string {
            return string `and the ${result}`;
        }
        return result;
    }
}

readonly service class StringInterceptor6 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string {
            return string `Chamber of Secrets --> ${result}`;
        }
        return result;
    }
}

@graphql:InterceptorConfig {
    global: false
}
readonly service class RecordInterceptor1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is record {} && 'field.getName() != "contact" {
            return {
                name: "Rubeus Hagrid",
                age: 70,
                address: {number: "103", street: "Mould-on-the-Wold", city: "London"}
            };
        }
        return result;
    }
}

readonly service class RecordInterceptor2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is record {} {
            return {
                number: "+87654321"
            };
        }
        return result;
    }
}

readonly service class ArrayInterceptor1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string[] {
            result.push("Slytherin(Water)");
        }
        return result;
    }
}

readonly service class ArrayInterceptor2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string[] {
            result.push("Ravenclaw(Air)");
        }
        return result;
    }
}

readonly service class EnumInterceptor1 {
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

readonly service class EnumInterceptor2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string[] {
            result.push(SATURDAY);
            result.push(SUNDAY);
            return result;
        }
        return result;
    }
}

readonly service class UnionInterceptor1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        if 'field.getName() == "profile1" {
            return {id: 3, name: "Minerva McGonagall", subject: "Transfiguration"};
        }
        return context.resolve('field);
    }
}

readonly service class UnionInterceptor2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is record {} {
            return {id: 4, name: "Minerva McGonagall", subject: "Black Magic"};
        }
        return result;
    }
}

readonly service class ServiceObjectInterceptor1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        if 'field.getName() == "teacher" {
            return {id: 3, name: "Minerva McGonagall", subject: "Transfiguration"};
        }
        return context.resolve('field);
    }
}

readonly service class ServiceObjectInterceptor2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        if 'field.getName() == "students" {
            return ["Ballerina", "GraphQL"];
        }
        return context.resolve('field);
    }
}

readonly service class ServiceObjectInterceptor3 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if 'field.getName() == "student" {
            return {id: 45, name: "Ron Weasley"};
        }
        return result;
    }
}

readonly service class ServiceObjectInterceptor4 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if 'field.getName() == "teachers" {
            return ["Hello", "World!"];
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

readonly service class Destruct1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is anydata[] && 'field.getName() == "students" {
            return [{id: 3, name: "Minerva McGonagall", subject: "Transfiguration"}];
        }
        return result;
    }
}

readonly service class Destruct2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is anydata[] && 'field.getName() == "teachers" {
            return [{id: 46, name: "Sybill Trelawney", subject: "Divination"}];
        }
        return result;
    }
}

readonly service class HierarchicalPath1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string && 'field.getName().equalsIgnoreCaseAscii("last") {
            return "Potter";
        }
        return result;
    }
}

readonly service class HierarchicalPath2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string {
            return "Harry";
        }
        return result;
    }
}


@graphql:InterceptorConfig {
    global: false
}
readonly service class HierarchicalPath3 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string && 'field.getName().equalsIgnoreCaseAscii("last") {
            return "Potter";
        }
        return result;
    }
}

readonly service class InterceptMutation1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if 'field.getName() == "setName" {
            return {
                name: "Albus Percival Wulfric Brian Dumbledore"
            };
        }
        return result;
    }
}

readonly service class InterceptMutation2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        _ = context.resolve('field);
        Person p = {name: "Albert", age: 53, address: {number: "103", street: "Mould-on-the-Wold", city: "London"}};
        return p;
    }
}

// readonly service class InterceptMutation3 {
//     *graphql:Interceptor;

//     isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
//         _ = context.resolve('field);
//         Person p = {name: "ASAC Schrader", age: 43, address: {number: "4901", street: "Cumbre Del Sur Court NE", city: "New Mexico"}};
//         return p;
//     }
// }

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
        if result is graphql:ErrorDetail {
            return ["Ballerina", "GraphQL"];
        }
        return result;
    }
}

readonly service class InvalidInterceptor3 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is record {} {
            return "Harry Potter";
        }
        return result;
    }
}

readonly service class InvalidInterceptor4 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is record {} {
            return {
                name: "Albus Percival Wulfric Brian Dumbledore",
                age: 80,
                address: {number: "103", street: "Mould-on-the-Wold", city: "London"}
            };
        }
        return result;
    }
}

@graphql:InterceptorConfig {
    global: false
}
readonly service class InvalidInterceptor5 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is record {} {
            return "Harry Potter";
        }
        return result;
    }
}

readonly service class InvalidInterceptor6 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is record {} {
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

readonly service class InvalidInterceptor8 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        _ = context.resolve('field);
        return {id: 5, name: "Jessie"};
    }
}

readonly service class InvalidInterceptor9 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        _ = context.resolve('field);
        return "Ballerina";
    }
}

@graphql:InterceptorConfig {
    global: false
}
readonly service class ErrorInterceptor1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        error interceptorError = error("This field is not accessible!");
        return interceptorError;
    }
}

readonly service class ErrorInterceptor2 {
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

readonly service class Execution3 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if result is string {
            return string `a powerful ${result}`;
        }
        return result;
    }
}

readonly service class Execution4 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var obj = check context.get("object");
        var result = context.resolve('field);
        if obj is string && result is string {
            return string `${result}-${obj}`;
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

readonly service class NullReturn1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        if 'field.getName() == "name" {
            return;
        }
        return context.resolve('field);
    }
}

readonly service class NullReturn2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        _ = context.resolve('field);
        return;
    }
}

readonly service class RecordFieldInterceptor1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        match 'field.getName() {
            "name" => {
                if result is string {
                    return result + " Dumbledore";
                }
                return result;
            }
            "age" => {
                if result is int {
                    return result + 10;
                }
                return result;
            }
            "number" => {
                return "100";
            }
            "street" => {
                return "Margo Street";
            }
            _ => {
                return result;
            }
        }
    }
}

readonly service class RecordFieldInterceptor2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if 'field.getName() == "name" {
            if result is string {
                return result + " Wulfric Brian";
            }
        }
        return result;
    }
}

readonly service class RecordFieldInterceptor3 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if 'field.getName() == "name" {
            if result is string {
                return "Albus Percival";
            }
        }
        return result;
    }
}

readonly service class MapInterceptor1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        match result {
            "Ballerina" => {
                return "Java";
            }
            "JavaScript" => {
                return "Flutter";
            }
            "Python" => {
                return "Ballerina";
            }
            "C++" => {
                return "C#";
            }
            _ => {
                return result;
            }
        }
    }
}

readonly service class MapInterceptor2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        Languages ls = {
            name: {
                backend: "PHP",
                frontend: "JavaScript",
                data: "Python",
                native: "C#"
            }
        };
        _ = context.resolve('field);
        return ls;
    }
}

readonly service class TableInterceptor1 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        var result = context.resolve('field);
        if 'field.getName() == "name" {
            if result is string {
                return string `Eng. ${result}`;
            }
        }
        return result;
    }
}

readonly service class TableInterceptor2 {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        _ = context.resolve('field);
        return [
            {id: 4, name: "John", salary: 5000.00},
            {id: 5, name: "Jane", salary: 7000.00},
            {id: 6, name: "Johnny", salary: 1000.00}
        ];
    }
}

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

readonly service class Street {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        _ = context.resolve('field);
        return "Street 3";
    }
}

readonly service class City {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        _ = context.resolve('field);
        return "New York";
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

readonly service class LogSubfields {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
        graphql:Field[]? subFields = 'field.getSubfields();
        if subFields is graphql:Field[] {
            foreach graphql:Field f in subFields {
                log:printInfo("Subfield: " + f.getName());
            }
        }
        return context.resolve('field);
    }
}

readonly service class AuthorInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata {
        var data = context.resolve('field);
        // Return only the first author
        return ('field.getName() == "authors" && data is anydata[]) ? [data[0]] : data;
    }
}

readonly service class BookInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata {
        var books = context.resolve('field);
        // Return only the first book
        return (books is anydata[]) ? [books[0]] : books;
    }
}
