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

import ballerina/http;
import ballerina/lang.runtime;

Service simpleService1 = service object {
    isolated resource function get name() returns string {
        return "Walter White";
    }

    isolated resource function get id() returns int {
        return 1;
    }
};

Service simpleService2 = service object {
    isolated resource function get name() returns string {
        return "Walter White";
    }

    isolated resource function get id() returns int {
        return 1;
    }
};

Service invalidMaxQueryDepthService =
@ServiceConfig {
    maxQueryDepth: 0
}
service object {
    isolated resource function get greet() returns string {
        return "Hello";
    }
};

service /input_type_introspection on basicListener {
    isolated resource function get name(string name = "Walter") returns string {
        return name;
    }

    isolated resource function get subject(string? subject = "Chemistry") returns string {
        return subject.toString();
    }

    isolated resource function get city(string city) returns string {
        return city;
    }

    isolated resource function get street(string? street) returns string {
        return street.toString();
    }
}

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
        return;
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

    isolated resource function get getDay(boolean isHoliday) returns Weekday[]{
        if (isHoliday) {
            return [SUNDAY, SATURDAY];
        }
        return [MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY];
    }

    isolated resource function get sendEmail(string message) returns string {
        return message;
    }
}

service /input_objects on basicListener {
    isolated resource function get searchProfile(ProfileDetail profileDetail) returns Person {
        if profileDetail?.age == 28 && profileDetail.name == "Jessie" {
            return {
                name: "Jessie Pinkman", age: 26, address: { number: "23B", street: "Negra Arroyo Lane", city: "Albuquerque" }
            };
        } else if profileDetail?.age == 30 || profileDetail.name == "Walter" {
            return {
                name: "Walter White", age: 50, address: { number: "9809", street: "Margo Street", city: "Albuquerque" }
            };
        } else {
            return {
                name: "Sherlock Holmes", age: 40, address: { number: "221/B", street: "Baker Street", city: "London" }
            };
        }
    }

    isolated resource function get book(Info info) returns Book[] {
        if info.author.name == "Conan Doyle" {
            return [b7, b8];
        } else if info.bookName == "Harry Potter" {
            return [b9, b10];
        } else if info.author.name == "J.K Rowling" {
           return [b9, b10];
        } else if info?.movie?.movieName == "Harry Potter" {
            return [b9, b10];
        } else if info?.movie?.director == "Chris Columbus" || info?.movie?.director == "Dexter Fletcher"{
            return [b7, b8, b9, b10];
        } else {
            return [b7, b8, b9, b10];
        }
    }

    isolated resource function get isHoliday(Date date) returns boolean {
        if date.day == SUNDAY || date.day == SATURDAY {
            return true;
        }
        return false;
    }

    isolated resource function get weightInPounds(Weight weight) returns float {
        return weight.weightInKg * CONVERSION_KG_TO_LBS;
    }

    isolated resource function get convertKgToGram(WeightInKg weight) returns float {
        return <float>weight.weight * 1000.00;
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
        if status is Status {
            return from var lift in liftTable where lift.status == status select new(lift);
        } else {
            return from var lift in liftTable select new(lift);
        }
    }

    isolated resource function get allTrails(Status? status) returns Trail[] {
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
        return;
    }

    isolated resource function get trail(string id) returns Trail? {
        TrailRecord[] trails = from var trail in trailTable where trail.id == id select trail;
        if trails.length() > 0 {
            return new Trail(trails[0]);
        }
        return;
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
        SearchResult[] searchResults = [];
        Trail[] trails = from var trail in trailTable where trail.status == status select new(trail);
        Lift[] lifts = from var lift in liftTable where lift.status == status select new(lift);
        foreach Trail trail in trails {
            searchResults.push(trail);
        }
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

// **************** Security-Related Services ****************
// Unsecured service
service /noAuth on secureListener {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

// Basic auth secured service
@ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["write", "update"]
        }
    ]
}
service /basicAuth on secureListener {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

// JWT auth secured service
@ServiceConfig {
    auth: [
        {
            jwtValidatorConfig: {
                issuer: "wso2",
                audience: "ballerina",
                signatureConfig: {
                    trustStoreConfig: {
                        trustStore: {
                            path: TRUSTSTORE_PATH,
                            password: "ballerina"
                        },
                        certAlias: "ballerina"
                    }
                },
                scopeKey: "scp"
            },
            scopes: ["write", "update"]
        }
    ]
}
service /jwtAuth on secureListener {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

// OAuth2 auth secured service
@ServiceConfig {
    auth: [
        {
            oauth2IntrospectionConfig: {
                url: "https://localhost:9445/oauth2/introspect",
                tokenTypeHint: "access_token",
                scopeKey: "scp",
                clientConfig: {
                    secureSocket: {
                       cert: {
                           path: TRUSTSTORE_PATH,
                           password: "ballerina"
                       }
                    }
                }
            },
            scopes: ["write", "update"]
        }
    ]
}
service /oauth2 on secureListener {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

// Testing multiple auth configurations support.
// OAuth2, Basic auth & JWT auth secured service
@ServiceConfig {
    auth: [
        {
            oauth2IntrospectionConfig: {
                url: "https://localhost:9445/oauth2/introspect",
                tokenTypeHint: "access_token",
                scopeKey: "scp",
                clientConfig: {
                    secureSocket: {
                       cert: {
                           path: TRUSTSTORE_PATH,
                           password: "ballerina"
                       }
                    }
                }
            },
            scopes: ["write", "update"]
        },
        {
            fileUserStoreConfig: {},
            scopes: ["write", "update"]
        },
        {
            jwtValidatorConfig: {
                issuer: "wso2",
                audience: "ballerina",
                signatureConfig: {
                    trustStoreConfig: {
                        trustStore: {
                            path: TRUSTSTORE_PATH,
                            password: "ballerina"
                        },
                        certAlias: "ballerina"
                    }
                },
                scopeKey: "scp"
            },
            scopes: ["write", "update"]
        }
    ]
}
service /multipleAuth on secureListener {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

// JWT auth secured service (without scopes)
@ServiceConfig {
    auth: [
        {
            jwtValidatorConfig: {
                issuer: "wso2",
                audience: "ballerina",
                signatureConfig: {
                    trustStoreConfig: {
                        trustStore: {
                            path: TRUSTSTORE_PATH,
                            password: "ballerina"
                        },
                        certAlias: "ballerina"
                    }
                }
            }
        }
    ]
}
service /noScopes on secureListener {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}
// **************** Security-Related Services ****************

isolated service /mutations on basicListener {
    private Person p;
    private TeacherService t;

    isolated function init() {
        self.p = p2.clone();
        self.t = new(1, "Walter Bishop", "Physics");
    }

    isolated resource function get person() returns Person {
        lock {
            return self.p;
        }
    }

    isolated remote function setName(string name) returns Person {
        lock {
            Person p = { name: name, age: self.p.age, address: self.p.address };
            self.p = p;
            return self.p;
        }
    }

    isolated remote function setCity(string city) returns Person {
        lock {
            Person p = {
                name: self.p.name,
                age: self.p.age,
                address: {
                    number: self.p.address.number,
                    street: self.p.address.street,
                    city: city
                }
            };
            self.p = p;
            return self.p;
        }
    }

    isolated remote function setTeacherName(string name) returns TeacherService {
        lock {
            self.t.setName(name);
            return self.t;
        }
    }

    isolated remote function setTeacherSubject(string subject) returns TeacherService {
        lock {
            self.t.setSubject(subject);
            return self.t;
        }
    }
}

service /null_values on basicListener {
    resource function get profile(int? id) returns Person {
        if id == () {
            return p1;
        }
        return p2;
    }

    remote function profile(string? name = ()) returns Person {
        if name == () {
            return p1;
        }
        return p2;
    }

    resource function get book(Author author) returns Book {
        if author == { name: (), id: 1 } {
            return b1;
        } else if author == { name: "J. K. Rowling", id: 2 } {
            return {
                name: "Harry Potter and the Prisnor of the Azkaban",
                author: "J. K. Rowling"
            };
        }
        return b3;
    }

    resource function get 'null(int? value) returns string? {
        if value != () {
            return "Hello";
        }
        return;
    }
}

@ServiceConfig {
    contextInit: isolated function (http:RequestContext requestContext, http:Request request) returns Context|error {
        Context context = new;
        check context.add("scope", check request.getHeader("scope"));
        return context;
    }
}
service /context on serviceTypeListener {
    isolated resource function get profile(Context context) returns Person|error {
        var scope = check context.get("scope");
        if scope is string && scope == "admin" {
            return {
                name: "Walter White",
                age: 51,
                address: {
                    number: "308",
                    street: "Negra Arroyo Lane",
                    city: "Albuquerque"
                }
            };
        } else {
            return error("You don't have permission to retrieve data");
        }
    }

    isolated resource function get name(Context context, string name) returns string|error {
        var scope = check context.get("scope");
        if scope is string && scope == "admin" {
            return name;
        } else {
            return error("You don't have permission to retrieve data");
        }
    }

    isolated resource function get animal() returns Animal {
        return new;
    }

    remote function update(Context context) returns (Person|error)[]|error {
        var scope = check context.get("scope");
        if scope is string && scope == "admin" {
            return people;
        } else {
            return [p1, error("You don't have permission to retrieve data"), p3];
        }
    }

    remote function updateNullable(Context context) returns (Person|error?)[]|error {
        var scope = check context.get("scope");
        if scope is string && scope == "admin" {
            return people;
        } else {
            return [p1, error("You don't have permission to retrieve data"), p3];
        }
    }
}

public isolated distinct service class Animal {
    isolated resource function get call(Context context, string sound, int count) returns string {
        var scope = context.get("scope");
        if scope is string && scope == "admin" {
            string call = "";
            int i = 0;
            while i < count {
                call += string`${sound} `;
                i += 1;
            }
            return call;
        } else {
            return sound;
        }
    }
}
