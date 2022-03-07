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

service on new graphql:Listener(9000) {
    resource function get greeting() returns string? {
        return "Walter White";
    }

    resource function get profile() returns Teacher|Student {
        return new ("Walter White", "Chemistry");
    }

    resource function get profileUnion() returns Person {
        return new ("Jesse Pinkman", 1);
    }
}

# Represents a union of Student and Teacher
type Person Teacher|Student;

# Represents a Student as a class.
public isolated distinct service class Student {
    final string name;
    final int id;

    isolated function init(string name, int id) {
        self.name = name;
        self.id = id;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get id() returns int {
        return self.id;
    }
}

# Represents a Teacher as a class.
public isolated distinct service class Teacher {
    final string name;
    final string subject;

    isolated function init(string name, string subject) {
        self.name = name;
        self.subject = subject;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get subject() returns string {
        return self.subject;
    }
}
