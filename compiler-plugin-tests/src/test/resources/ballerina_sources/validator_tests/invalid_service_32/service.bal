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

service /graphql on new graphql:Listener(4000) {
    isolated resource function get name(int id) returns Person {
        if id < 10 {
        return new Student("Jesse Pinkman", 25, "student-1");
        }
        return new Teacher("Walter White", 52, "teacher-1", "Chemistry");
    }
}

public type Person distinct service object {
    isolated resource function get name() returns string;
    isolated resource function get age() returns int;
};

public isolated distinct service class Student {
    *Person;

    final string name;
    final string id;
    final int age;

    isolated function init(string name, int age, string id) {
        self.name = name;
        self.age = age;
        self.id = id;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get age() returns int {
        return self.age;
    }

    isolated resource function read id() returns string {
        return self.id;
    }
}

public isolated distinct service class Teacher {
    *Person;

    final string name;
    final string id;
    final int age;
    final string subject;

    isolated function init(string name, int age, string id, string subject) {
        self.name = name;
        self.age = age;
        self.id = id;
        self.subject = subject;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get age() returns int {
        return self.age;
    }

    isolated resource function get id() returns string {
        return self.id;
    }

    isolated resource function post subject() returns string {
        return self.subject;
    }
}
