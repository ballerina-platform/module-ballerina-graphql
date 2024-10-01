// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com).
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

public type PeopleService StudentService|TeacherService;

public distinct isolated service class StudentService {
    private final int id;
    private final string name;

    public isolated function init(int id, string name) {
        self.id = id;
        self.name = name;
    }

    isolated resource function get id() returns int {
        return self.id;
    }

    isolated resource function get name() returns string {
        return self.name;
    }
}

public distinct isolated service class TeacherService {
    private final int id;
    private string name;
    private string subject;

    public isolated function init(int id, string name, string subject) {
        self.id = id;
        self.name = name;
        self.subject = subject;
    }

    isolated resource function get id() returns int {
        return self.id;
    }

    isolated resource function get name() returns string {
        lock {
            return self.name;
        }
    }

    isolated function setName(string name) {
        lock {
            self.name = name;
        }
    }

    isolated resource function get subject() returns string {
        lock {
            return self.subject;
        }
    }

    isolated function setSubject(string subject) {
        lock {
            self.subject = subject;
        }
    }

    isolated resource function get holidays() returns Weekday[] {
        return [SATURDAY, SUNDAY];
    }

    isolated resource function get school() returns School {
        return new School("CHEM");
    }
}

public distinct isolated service class School {
    private string name;

    public isolated function init(string name) {
        self.name = name;
    }

    isolated resource function get name() returns string {
        lock {
            return self.name;
        }
    }

    # Get the opening days of the school.
    # + return - The set of the weekdays the school is open
    # # Deprecated
    # School is now online.
    @deprecated
    isolated resource function get openingDays() returns Weekday[] {
        return [MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY];
    }
}

public distinct isolated service class Customer {
    private final int id;
    private final string name;

    public isolated function init(int id, string name) {
        self.id = id;
        self.name = name;
    }

    @graphql:ResourceConfig {
        interceptors: [new Counter(), new Counter(), new Counter()]
    }
    isolated resource function get id() returns int {
        return self.id;
    }

    @graphql:ResourceConfig {
        interceptors: new NullReturn1()
    }
    isolated resource function get name() returns string? {
        lock {
            return self.name;
        }
    }

    isolated resource function get address() returns CustomerAddress {
        return new (225, "Bakers street", "London");
    }
}

public distinct isolated service class CustomerAddress {
    private final int number;
    private final string street;
    private final string city;

    public isolated function init(int number, string street, string city) {
        self.number = number;
        self.street = street;
        self.city = city;
    }

    @graphql:ResourceConfig {
        interceptors: [new Counter(), new Counter()]
    }
    isolated resource function get number() returns int {
        return self.number;
    }

    @graphql:ResourceConfig {
        interceptors: new Street()
    }
    isolated resource function get street() returns string {
        return self.street;
    }

    @graphql:ResourceConfig {
        interceptors: new City()
    }
    isolated resource function get city() returns string {
        return self.city;
    }
}
