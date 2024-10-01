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

public distinct isolated service class HierarchicalName {
    isolated resource function get name/first() returns string {
        return "Sherlock";
    }

    isolated resource function get name/last() returns string {
        return "Holmes";
    }
}

public isolated distinct service class AnimalClass {
    isolated resource function get call(graphql:Context context, string sound, int count) returns string {
        var scope = context.get("scope");
        if scope is string && scope == "admin" {
            string call = "";
            int i = 0;
            while i < count {
                call += string `${sound} `;
                i += 1;
            }
            return call;
        } else {
            return sound;
        }
    }
}

public isolated service class GeneralGreeting {
    isolated resource function get generalGreeting() returns string {
        return "Hello, world";
    }
}

public isolated service class Profile {
    isolated resource function get name() returns Name {
        return new;
    }
}

public isolated service class Vehicle {
    private final string id;
    private final string name;
    private final int? registeredYear;

    isolated function init(string id, string name, int? registeredYear = ()) {
        self.id = id;
        self.name = name;
        self.registeredYear = registeredYear;
    }

    isolated resource function get id() returns string {
        return self.id;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get registeredYear() returns int|error {
        int? registeredYear = self.registeredYear;
        if registeredYear == () {
            return error("Registered Year is Not Found");
        } else {
            return registeredYear;
        }
    }
}

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

public type HumanService FriendService|EnemyService;

public isolated distinct service class FriendService {
    private final string name;
    private final int age;
    private final boolean isMarried;

    public isolated function init(string name, int age, boolean isMarried) {
        self.name = name;
        self.age = age;
        self.isMarried = isMarried;
    }

    @graphql:ResourceConfig {
        cacheConfig: {
            maxAge: 180
        }
    }
    isolated resource function get name() returns string {
        return self.name;
    }

    @graphql:ResourceConfig {
        cacheConfig: {
            maxAge: 180
        }
    }
    isolated resource function get age() returns int {
        return self.age;
    }

    @graphql:ResourceConfig {
        cacheConfig: {
            maxAge: 180
        }
    }
    isolated resource function get isMarried() returns boolean {
        return self.isMarried;
    }
}

public isolated distinct service class EnemyService {
    private final string name;
    private final int age;
    private final boolean isMarried;

    public isolated function init(string name, int age, boolean isMarried) {
        self.name = name;
        self.age = age;
        self.isMarried = isMarried;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get age() returns int {
        return self.age;
    }

    isolated resource function get isMarried() returns boolean {
        return self.isMarried;
    }
}

public isolated distinct service class AssociateService {
    private final string name;
    private final string status;

    public isolated function init(string name, string status) {
        self.name = name;
        self.status = status;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get status() returns string {
        return self.status;
    }
}

public type Relationship FriendService|AssociateService;

public isolated service class Name {
    isolated resource function get first() returns string {
        return "Sherlock";
    }

    isolated resource function get last() returns string {
        return "Holmes";
    }

    isolated resource function get surname() returns string|error {
        return error("No surname found");
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
