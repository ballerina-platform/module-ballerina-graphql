// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

// NamedEntity and SomeNamedEntity are not being used in the graphql service, not validated as graphql interfaces
service class NamedEntity {
    string name;

    function init(string name) {
        self.name = name;
    }

    isolated resource function get name() returns string {
        return self.name;
    }
}

service class SomeNamedEntity {
    string name;

    function init(string name) {
        self.name = name;
    }

    isolated resource function get name() returns string {
        return self.name;
    }
}

distinct service class ContactDetail {
    string email;

    function init(string email) {
        self.email = email;
    }

    isolated resource function get email() returns string {
        return self.email;
    }
}

distinct service class Person {
    *ContactDetail;

    function init(string email) {
        self.email = email;
    }
}

distinct service class Student {
    *Person;

    string email = "Shelock@gmail.com";
    int studentId = 3;

    isolated resource function get studentId() returns int {
        return self.studentId;
    }
}

distinct service class Teacher {
    *Person;

    string email = "Walter@gmail.com";
    string subject = "chemistry";

    isolated resource function get subject() returns string {
        return self.subject;
    }
}

service /graphql on new graphql:Listener(9000) {

    isolated resource function get profile(int id) returns Person {
        if (id < 10) {
            return new Student();
        } else {
            return new Teacher();
        }
    }
}
