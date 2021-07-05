// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/lang.runtime;

Service simpleService = service object {
    isolated resource function get name() returns string {
        return "Walter White";
    }

    isolated resource function get id() returns int {
        return 1;
    }
};

service /validation on basicListener {
    isolated resource function get name() returns string {
        return "James Moriarty";
    }

    isolated resource function get birthdate() returns string {
        return "15-05-1848";
    }

    isolated resource function get ids() returns int[] {
        return [0, 1, 2];
    }
}

service /inputs on basicListener {
    isolated resource function get greet(string name) returns string {
        return "Hello, " + name;
    }

    isolated resource function get isLegal(int age) returns boolean {
        if (age < 21) {
            return false;
        }
        return true;
    }

    isolated resource function get quote() returns string {
        return quote2;
    }

    isolated resource function get quoteById(int id = 0) returns string? {
        if (id == 0) {
            return quote1;
        } else if (id == 1) {
            return quote2;
        } else if (id == 2) {
            return quote3;
        }
    }

    isolated resource function get weightInPounds(float weightInKg) returns float {
        return weightInKg * CONVERSION_KG_TO_LBS;
    }

    isolated resource function get isHoliday(Weekday? weekday) returns boolean {
        if (weekday == SUNDAY || weekday == SATURDAY) {
            return true;
        }
        return false;
    }
}

service /records on basicListener {
    isolated resource function get detective() returns Person {
        return {
            name: "Sherlock Holmes", age: 40, address: { number: "221/B", street: "Baker Street", city: "London" }
        };
    }

    isolated resource function get teacher() returns Person {
        return {
            name: "Walter White", age: 50, address: { number: "308", street: "Negra Arroyo Lane", city: "Albuquerque" }
        };
    }

    isolated resource function get student() returns Person {
        return {
            name: "Jesse Pinkman", age: 25, address: { number: "9809", street: "Margo Street", city: "Albuquerque" }
        };
    }

    resource function get profile(int id) returns Person {
        return people[id];
    }

    resource function get people() returns Person[] {
        return people;
    }

    resource function get students() returns Student[] {
        return students;
    }
}

service /service_types on serviceTypeListener {
    isolated resource function get greet() returns GeneralGreeting {
        return new;
    }

    isolated resource function get profile() returns Profile {
        return new;
    }
}

service /service_objects on serviceTypeListener {
    isolated resource function get ids() returns int[] {
        return [0, 1, 2];
    }

    isolated resource function get allVehicles() returns Vehicle[] {
        Vehicle v1 = new("V1", "Benz", 2005);
        Vehicle v2 = new("V2", "BMW", 2010);
        Vehicle v3 = new("V3", "Ford");
        return [v1, v2, v3];
    }

    isolated resource function get searchVehicles(string keyword) returns Vehicle[]? {
        Vehicle v1 = new("V1", "Benz");
        Vehicle v2 = new("V2", "BMW");
        Vehicle v3 = new("V3", "Ford");
        return [v1, v2, v3];
    }

    isolated resource function get teacher() returns TeacherService {
        return new TeacherService(737, "Walter White", "Chemistry");
    }
}

service /records_union on basicListener {
    resource function get profile(int id) returns Person|error? {
        if (id < people.length()) {
            return people[id];
        } else if (id < 5) {
            return;
        } else {
            return error("Invalid ID provided");
        }
    }

    resource function get information(int id) returns Information {
        if (id < 5) {
            return p1;
        } else {
            return a1;
        }
    }

    resource function get details(int id) returns Details {
        if (id < 5) {
            return { information: p1 };
        } else {
            return { information: a1 };
        }
    }

    resource function get learningSources() returns (Book|Course)[] {
        return [b1, b2, b3, b4, c1, c2, c3];
    }
}

service /timeoutService on timeoutListener {
    isolated resource function get greet() returns string {
        runtime:sleep(3);
        return "Hello";
    }
}

@ServiceConfig {
    maxQueryDepth: 2
}
service /depthLimitService on basicListener {
    isolated resource function get greet() returns string {
        return "Hello";
    }

    resource function get people() returns Person[] {
        return people;
    }

    resource function get students() returns Student[] {
        return students;
    }
}

service /profiles on hierarchicalPathListener {
    isolated resource function get profile/name/first() returns string {
        return "Sherlock";
    }

    isolated resource function get profile/name/last() returns string {
        return "Holmes";
    }

    isolated resource function get profile/age() returns int {
        return 40;
    }

    isolated resource function get profile/address/city() returns string {
        return "London";
    }

    isolated resource function get profile/address/street() returns string {
        return "Baker Street";
    }

    isolated resource function get profile/name/address/number() returns string {
        return "221/B";
    }
}

service /snowtooth on hierarchicalPathListener {
    isolated resource function get lift/name() returns string {
        return "Lift1";
    }

    isolated resource function get mountain/trail/getLift/name() returns string {
        return "Lift2";
    }
}

service /hierarchical on hierarchicalPathListener {
    isolated resource function get profile/personal() returns HierarchicalName {
        return new();
    }
}

service /tables on basicListener {
    resource function get employees() returns EmployeeTable? {
        return employees;
    }
}

service /special_types on specialTypesTestListener {
    isolated resource function get weekday(int number) returns Weekday {
        match number {
            1 => {
                return MONDAY;
            }
            2 => {
                return TUESDAY;
            }
            3 => {
                return WEDNESDAY;
            }
            4 => {
                return THURSDAY;
            }
            5 => {
                return FRIDAY;
            }
            6 => {
                return SATURDAY;
            }
        }
        return SUNDAY;
    }

    isolated resource function get day(int number) returns Weekday|error {
        if (number < 1 || number > 7) {
            return error("Invalid number");
        } else if (number == 1) {
            return MONDAY;
        } else if (number == 2) {
            return TUESDAY;
        } else if (number == 3) {
            return WEDNESDAY;
        } else if (number == 4) {
            return THURSDAY;
        } else if (number == 5) {
            return FRIDAY;
        } else if (number == 6) {
            return SATURDAY;
        } else {
            return SUNDAY;
        }
    }

    isolated resource function get time() returns Time {
        return {
            weekday: MONDAY,
            time: "22:10:33"
        };
    }

    isolated resource function get isHoliday(Weekday weekday) returns boolean {
        if (weekday == SATURDAY || weekday == SUNDAY) {
            return true;
        }
        return false;
    }

    isolated resource function get holidays() returns Weekday[] {
        return [SATURDAY, SUNDAY];
    }

    resource function get company() returns Company {
        return company;
    }
}

service /snowtooth on serviceTypeListener {
    isolated resource function get allLifts(Status? status) returns Lift[] {
        LiftRecord[] lifts;
        if status is Status {
            return from var lift in liftTable where lift.status == status select new(lift);
        } else {
            return from var lift in liftTable select new(lift);
        }
    }

    isolated resource function get allTrails(Status? status) returns Trail[] {
        TrailRecord[] trails;
        if status is Status {
            return from var trail in trailTable where trail.status == status select new(trail);
        } else {
            return from var trail in trailTable select new(trail);
        }
    }

    isolated resource function get lift(string id) returns Lift? {
        LiftRecord[] lifts = from var lift in liftTable where lift.id == id select lift;
        if lifts.length() > 0 {
            return new Lift(lifts[0]);
        }
    }

    isolated resource function get trail(string id) returns Trail? {
        TrailRecord[] trails = from var trail in trailTable where trail.id == id select trail;
        if trails.length() > 0 {
            return new Trail(trails[0]);
        }
    }

    isolated resource function get liftCount(Status status) returns int {
        LiftRecord[] lifts = from var lift in liftTable where lift.status == status select lift;
        return lifts.length();
    }

    isolated resource function get trailCount(Status status) returns int {
        TrailRecord[] trails = from var trail in trailTable where trail.status == status select trail;
        return trails.length();
    }

    isolated resource function get search(Status status) returns SearchResult[] {
        SearchResult[] searchResults = from var trail in trailTable where trail.status == status select new(trail);
        Lift[] lifts = from var lift in liftTable where lift.status == status select new(lift);
        foreach Lift lift in lifts {
            searchResults.push(lift);
        }
        return searchResults;
    }
}

service /unions on serviceTypeListener {
    isolated resource function get profile(int id) returns StudentService|TeacherService {
        if (id < 100) {
            return new StudentService(1, "Jesse Pinkman");
        } else {
            return new TeacherService(737, "Walter White", "Chemistry");
        }
    }

    isolated resource function get search() returns (StudentService|TeacherService)[] {
        StudentService s = new StudentService(1, "Jesse Pinkman");
        TeacherService t = new TeacherService(737, "Walter White", "Chemistry");
        return [s, t];
    }
}

service /duplicates on basicListener {
    isolated resource function get profile() returns Person {
        return {
            name: "Sherlock Holmes", age: 40, address: { number: "221/B", street: "Baker Street", city: "London" }
        };
    }

    resource function get people() returns Person[] {
        return people;
    }

    resource function get students() returns Student[] {
        return students;
    }

    resource function get teacher() returns Person {
        return p2;
    }

    resource function get student() returns Person {
        return p4;
    }
}
