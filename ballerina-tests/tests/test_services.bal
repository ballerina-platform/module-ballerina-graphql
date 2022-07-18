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

import ballerina/graphql;
import ballerina/http;
import ballerina/lang.runtime;

graphql:Service invalidMaxQueryDepthService =
@graphql:ServiceConfig {
    maxQueryDepth: 0
}
service object {
    isolated resource function get greet() returns string {
        return "Hello";
    }
};

graphql:Service invalidGraphiqlPathConfigService1 =
@graphql:ServiceConfig {
    graphiql: {
        enable: true,
        path: "/ballerina graphql"
    }
}
isolated service object {
    isolated resource function get greet() returns string {
        return "Hello";
    }
};

graphql:Service invalidGraphiqlPathConfigService2 =
@graphql:ServiceConfig {
    graphiql: {
        enable: true,
        path: "/ballerina_+#@#$!"
    }
}
service object {
    isolated resource function get greet() returns string {
        return "Hello";
    }
};

graphql:Service graphiqlDefaultPathConfigService =
@graphql:ServiceConfig {
    graphiql: {
        enable: true
    }
}
service object {
    isolated resource function get greet() returns string {
        return "Hello";
    }
};

graphql:Service graphiqlConfigService =
@graphql:ServiceConfig {
    graphiql: {
        enable: true,
        path: "ballerina/graphiql"
    }
}
service object {
    isolated resource function get greet() returns string {
        return "Hello";
    }
};

@graphql:ServiceConfig {
    graphiql: {
        enable: false,
        path: "/ballerina graphql"
    }
}
service /invalid_graphiql on basicListener {
    isolated resource function get greet() returns string {
        return "Hello";
    }
}

@graphql:ServiceConfig {
    graphiql: {
        enable: true
    }
}
service /graphiql/test on basicListener {
    isolated resource function get greet() returns string {
        return "Hello";
    }
}

@graphql:ServiceConfig {
    graphiql: {
        enable: true,
        path: "ballerina/graphiql"
    }
}
service on basicListener {
    isolated resource function get greet() returns string {
        return "Hello";
    }
}

@graphql:ServiceConfig {
    graphiql: {
        enable: true
    }
}
service on serviceTypeListener {
    isolated resource function get greet() returns string {
        return "Hello";
    }
}

@graphql:ServiceConfig {
    graphiql: {
        enable: true,
        path: "graphiql/interface"
    }
}
service /graphiqlClient on basicListener {
    isolated resource function get greet() returns string {
        return "Hello";
    }
}

service /fileUpload on basicListener {
    resource function get name() returns string {
        return "/fileUpload";
    }

    remote function singleFileUpload(graphql:Upload file) returns FileInfo|error {
        string contentFromByteStream = check getContentFromByteStream(file.byteStream);
        return {
            fileName: file.fileName,
            mimeType: file.mimeType,
            encoding: file.encoding,
            content: contentFromByteStream
        };
    }

    remote function multipleFileUpload(graphql:Upload[] files) returns FileInfo[]|error {
        FileInfo[] fileInfo = [];
        foreach int i in 0 ..< files.length() {
            graphql:Upload file = files[i];
            string contentFromByteStream = check getContentFromByteStream(file.byteStream);
            fileInfo.push({
                fileName: file.fileName,
                mimeType: file.mimeType,
                encoding: file.encoding,
                content: contentFromByteStream
            });
        }
        return fileInfo;
    }
}

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

    isolated resource function get idsWithErrors() returns (int|error)[] {
        return [0, 1, 2, error("Not Found!")];
    }

    isolated resource function get friends() returns (string|error)?[] {
        return ["walter", "jessie", error("Not Found!")];
    }
}

const float CONVERSION_KG_TO_LBS = 2.205;

service /inputs on basicListener {
    isolated resource function get greet(string name) returns string {
        return "Hello, " + name;
    }

    isolated resource function get isLegal(int age) returns boolean {
        if age < 21 {
            return false;
        }
        return true;
    }

    isolated resource function get quote() returns string {
        return quote2;
    }

    isolated resource function get quoteById(int id = 0) returns string? {
        match id {
            0 => {
                return quote1;
            }
            1 => {
                return quote2;
            }
            2 => {
                return quote3;
            }
        }
        return;
    }

    isolated resource function get weightInPounds(float weightInKg) returns float {
        return weightInKg * CONVERSION_KG_TO_LBS;
    }

    isolated resource function get isHoliday(Weekday? weekday) returns boolean {
        if weekday == SUNDAY || weekday == SATURDAY {
            return true;
        }
        return false;
    }

    isolated resource function get getDay(boolean isHoliday) returns Weekday[] {
        if isHoliday {
            return [SUNDAY, SATURDAY];
        }
        return [MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY];
    }

    isolated resource function get sendEmail(string message) returns string {
        return message;
    }

    isolated resource function get 'type(string 'version) returns string {
        return 'version;
    }

    isolated resource function get \u{0076}ersion(string name) returns string {
        return name;
    }
}

service /decimal_inputs on basicListener {
    isolated resource function get convertDecimalToFloat(decimal value) returns float|error {
        return float:fromString(value.toString());
    }

    isolated resource function get getTotalInDecimal(decimal[][] prices) returns decimal[] {
        decimal[] total = [];
        decimal sumOfNestedList = 0;
        foreach decimal[] nested in prices {
            sumOfNestedList = 0;
            foreach decimal price in nested {
                sumOfNestedList += price;
            }
            total.push(sumOfNestedList);
        }
        return total;
    }

    isolated resource function get getSubTotal(Item[] items) returns decimal {
        decimal subTotal = 0.0;
        foreach Item item in items {
            subTotal += item.price;
        }
        return subTotal;
    }
}

service /input_objects on basicListener {
    isolated resource function get searchProfile(ProfileDetail profileDetail) returns Person {
        if profileDetail?.age == 28 && profileDetail.name == "Jessie" {
            return {
                name: "Jessie Pinkman",
                age: 26,
                address: {number: "23B", street: "Negra Arroyo Lane", city: "Albuquerque"}
            };
        } else if profileDetail?.age == 30 || profileDetail.name == "Walter" {
            return {
                name: "Walter White",
                age: 50,
                address: {number: "9809", street: "Margo Street", city: "Albuquerque"}
            };
        } else {
            return {
                name: "Sherlock Holmes",
                age: 40,
                address: {number: "221/B", street: "Baker Street", city: "London"}
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
        } else if info?.movie?.director == "Chris Columbus" || info?.movie?.director == "Dexter Fletcher" {
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

service /list_inputs on basicListener {
    isolated resource function get concat(string?[]? words) returns string {
        string result = "";
        if words is string?[] && words.length() > 0 {
            foreach string? word in words {
                if word is string {
                    result += word;
                    result += " ";
                }
            }
            return result.trim();
        }
        return "Word list is empty";
    }

    isolated resource function get getTotal(float[][] prices) returns float[] {
        float[] total = [];
        float sumOfNestedList = 0;
        foreach float[] nested in prices {
            sumOfNestedList = 0;
            foreach float price in nested {
                sumOfNestedList += price;
            }
            total.push(sumOfNestedList);
        }
        return total;
    }

    isolated resource function get searchProfile(ProfileDetail[] profileDetail) returns Person[] {
        Person[] results = [];
        foreach ProfileDetail profile in profileDetail {
            if profile?.age == 28 && profile.name == "Jessie" {
                results.push({
                    name: "Jessie Pinkman",
                    age: 26,
                    address: {number: "23B", street: "Negra Arroyo Lane", city: "Albuquerque"}
                });
            } else if profile?.age == 30 || profile.name == "Walter" {
                results.push({
                    name: "Walter White",
                    age: 50,
                    address: {number: "9809", street: "Margo Street", city: "Albuquerque"}
                });
            } else {
                results.push({
                    name: "Sherlock Holmes",
                    age: 40,
                    address: {number: "221/B", street: "Baker Street", city: "London"}
                });
            }
        }
        return results;
    }

    resource function get getSuggestions(TvSeries[] tvSeries) returns Movie[] {
        Movie[] results = [m1, m2, m3, m4, m5, m6];
        foreach TvSeries item in tvSeries {
            if item.name == "Breaking Bad" {
                results = [m3];
            } else if item.name == "Prison Break" {
                results = [m4, m5, m6];
            } else if item?.episodes is Episode[] {
                Episode[] episodes = <Episode[]>item?.episodes;
                foreach Episode epi in episodes {
                    if epi?.newCharacters is string[] {
                        string[] characters = <string[]>epi?.newCharacters;
                        foreach string name in characters {
                            if name == "Sara" || name == "Michael" || name == "Lincoln" {
                                results = [m4, m5, m6];
                            }
                        }
                    }
                }
            }
        }
        return results;
    }

    resource function get getMovie(TvSeries tvSeries) returns Movie[] {
        Movie[] results = [m1, m2, m3, m4, m5, m6];
        if tvSeries?.episodes is Episode[] {
            Episode[] episodes = <Episode[]>tvSeries?.episodes;
            foreach Episode episode in episodes {
                if episode?.newCharacters is string[] {
                    string[] characters = <string[]>episode?.newCharacters;
                    foreach string name in characters {
                        if name == "Sara" || name == "Michael" || name == "Lincoln" {
                            results = [m4, m5, m6];
                        } else if name == "Harry" || name == "Hagrid" {
                            results = [m1];
                        } else if name == "Sherlock" {
                            results = [m2];
                        }
                    }
                } else {
                    if episode.title == "The Key" || episode.title == "Flight" {
                        results = [m4, m5];
                    } else if episode.title == "Cancer Man" {
                        results = [m3];
                    }
                }
            }
        }
        return results;
    }

    isolated resource function get isIncludeHoliday(Weekday[] days = [MONDAY, FRIDAY]) returns boolean {
        if days.indexOf(<Weekday>SUNDAY) != () || days.indexOf(<Weekday>SATURDAY) != () {
            return true;
        }
        return false;
    }
}

service /records on basicListener {
    isolated resource function get detective() returns Person {
        return {
            name: "Sherlock Holmes",
            age: 40,
            address: {number: "221/B", street: "Baker Street", city: "London"}
        };
    }

    isolated resource function get teacher() returns Person {
        return {
            name: "Walter White",
            age: 50,
            address: {number: "308", street: "Negra Arroyo Lane", city: "Albuquerque"}
        };
    }

    isolated resource function get student() returns Person {
        return {
            name: "Jesse Pinkman",
            age: 25,
            address: {number: "9809", street: "Margo Street", city: "Albuquerque"}
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
        Vehicle v1 = new ("V1", "Benz", 2005);
        Vehicle v2 = new ("V2", "BMW", 2010);
        Vehicle v3 = new ("V3", "Ford");
        return [v1, v2, v3];
    }

    isolated resource function get searchVehicles(string keyword) returns Vehicle[]? {
        Vehicle v1 = new ("V1", "Benz");
        Vehicle v2 = new ("V2", "BMW");
        Vehicle v3 = new ("V3", "Ford");
        return [v1, v2, v3];
    }

    isolated resource function get teacher() returns TeacherService {
        return new TeacherService(737, "Walter White", "Chemistry");
    }
}

service /timeoutService on timeoutListener {
    isolated resource function get greet() returns string {
        runtime:sleep(3);
        return "Hello";
    }
}

@graphql:ServiceConfig {
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

@graphql:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: true,
        allowHeaders: ["X-Content-Type-Options"],
        exposeHeaders: ["X-CUSTOM-HEADER"],
        allowMethods: ["*"],
        maxAge: 84900
    }
}
service /corsConfigService1 on basicListener {
    isolated resource function get greet() returns string {
        return "Hello";
    }
}

@graphql:ServiceConfig {
    cors: {
        allowOrigins: ["http://www.wso2.com"],
        allowCredentials: true,
        allowHeaders: ["X-Content-Type-Options", "X-PINGOTHER"],
        exposeHeaders: ["X-HEADER"],
        allowMethods: ["POST"]
    }
}
service /corsConfigService2 on basicListener {
    isolated resource function get greet() returns string {
        return "Hello";
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
        return new ();
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
        if number < 1 || number > 7 {
            return error("Invalid number");
        } else if number == 1 {
            return MONDAY;
        } else if number == 2 {
            return TUESDAY;
        } else if number == 3 {
            return WEDNESDAY;
        } else if number == 4 {
            return THURSDAY;
        } else if number == 5 {
            return FRIDAY;
        } else if number == 6 {
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
        if weekday == SATURDAY || weekday == SUNDAY {
            return true;
        }
        return false;
    }

    isolated resource function get holidays() returns Weekday[] {
        return [SATURDAY, SUNDAY];
    }

    isolated resource function get openingDays() returns (Weekday|error)[] {
        return [MONDAY, TUESDAY, error("Holiday!"), THURSDAY, FRIDAY];
    }

    isolated resource function get specialHolidays() returns (Weekday|error)?[] {
        return [TUESDAY, error("Holiday!"), THURSDAY];
    }

    resource function get company() returns Company {
        return company;
    }
}

service /snowtooth on serviceTypeListener {
    isolated resource function get allLifts(Status? status) returns Lift[] {
        if status is Status {
            return from var lift in liftTable
                where lift.status == status
                select new (lift);
        } else {
            return from var lift in liftTable
                select new (lift);
        }
    }

    isolated resource function get allTrails(Status? status) returns Trail[] {
        if status is Status {
            return from var trail in trailTable
                where trail.status == status
                select new (trail);
        } else {
            return from var trail in trailTable
                select new (trail);
        }
    }

    isolated resource function get lift(string id) returns Lift? {
        LiftRecord[] lifts = from var lift in liftTable
            where lift.id == id
            select lift;
        if lifts.length() > 0 {
            return new Lift(lifts[0]);
        }
        return;
    }

    isolated resource function get trail(string id) returns Trail? {
        TrailRecord[] trails = from var trail in trailTable
            where trail.id == id
            select trail;
        if trails.length() > 0 {
            return new Trail(trails[0]);
        }
        return;
    }

    isolated resource function get liftCount(Status status) returns int {
        LiftRecord[] lifts = from var lift in liftTable
            where lift.status == status
            select lift;
        return lifts.length();
    }

    isolated resource function get trailCount(Status status) returns int {
        TrailRecord[] trails = from var trail in trailTable
            where trail.status == status
            select trail;
        return trails.length();
    }

    isolated resource function get search(Status status) returns SearchResult[] {
        SearchResult[] searchResults = [];
        Trail[] trails = from var trail in trailTable
            where trail.status == status
            select new (trail);
        Lift[] lifts = from var lift in liftTable
            where lift.status == status
            select new (lift);
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
        if id < 100 {
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

    isolated resource function get services() returns PeopleService?[] {
        StudentService s = new StudentService(1, "Jesse Pinkman");
        TeacherService t = new TeacherService(737, "Walter White", "Chemistry");
        return [s, t, ()];
    }
}

service /union_type_names on serviceTypeListener {
    private final StudentService s = new StudentService(1, "Jesse Pinkman");
    private final TeacherService t = new TeacherService(0, "Walter White", "Chemistry");

    isolated resource function get nonNullSingleObject() returns PeopleService {
        return self.s;
    }

    isolated resource function get nullableSingleObject() returns PeopleService? {
        return self.s;
    }

    isolated resource function get nonNullArray() returns PeopleService[] {
        return [self.s, self.t];
    }

    isolated resource function get nullableArray() returns PeopleService?[] {
        return [self.s, ()];
    }

    isolated resource function get nonNullUndefinedUnionType() returns StudentService|TeacherService {
        return self.s;
    }

    isolated resource function get nonNullUndefinedUnionTypeArray() returns (StudentService|TeacherService)[] {
        return [self.s];
    }

    isolated resource function get nullableUndefinedUnionType() returns StudentService|TeacherService? {
        return self.s;
    }

    isolated resource function get nullableUndefinedUnionTypeArray() returns (StudentService|TeacherService)?[] {
        return [self.s, ()];
    }
}

service /duplicates on basicListener {
    isolated resource function get profile() returns Person {
        return {
            name: "Sherlock Holmes",
            age: 40,
            address: {number: "221/B", street: "Baker Street", city: "London"}
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
@graphql:ServiceConfig {
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
@graphql:ServiceConfig {
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
@graphql:ServiceConfig {
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
@graphql:ServiceConfig {
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
@graphql:ServiceConfig {
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
        self.t = new (1, "Walter Bishop", "Physics");
    }

    isolated resource function get person() returns Person {
        lock {
            return self.p;
        }
    }

    isolated remote function setName(string name) returns Person {
        lock {
            Person p = {name: name, age: self.p.age, address: self.p.address};
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

    resource function get book(Author? author) returns Book {
        if author == {name: (), id: 1} {
            return b1;
        } else if author == {name: "J. K. Rowling", id: 2} {
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

@graphql:ServiceConfig {
    contextInit:
    isolated function(http:RequestContext requestContext, http:Request request) returns graphql:Context|error {
        graphql:Context context = new;
        context.set("scope", check request.getHeader("scope"));
        return context;
    }
}
service /context on serviceTypeListener {
    isolated resource function get profile(graphql:Context context) returns Person|error {
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

    isolated resource function get name(graphql:Context context, string name) returns string|error {
        var scope = check context.get("scope");
        if scope is string && scope == "admin" {
            return name;
        } else {
            return error("You don't have permission to retrieve data");
        }
    }

    isolated resource function get animal() returns AnimalClass {
        return new;
    }

    remote function update(graphql:Context context) returns (Person|error)[]|error {
        var scope = check context.get("scope");
        if scope is string && scope == "admin" {
            return people;
        } else {
            return [p1, error("You don't have permission to retrieve data"), p3];
        }
    }

    remote function updateNullable(graphql:Context context) returns (Person|error?)[]|error {
        var scope = check context.get("scope");
        if scope is string && scope == "admin" {
            return people;
        } else {
            return [p1, error("You don't have permission to retrieve data"), p3];
        }
    }
}

service /intersection_types on basicListener {
    isolated resource function get name(Species & readonly species) returns string {
        return species.specificName;
    }

    isolated resource function get city(Address address) returns string {
        return address.city;
    }

    isolated resource function get profile() returns ProfileDetail & readonly {
        ProfileDetail profile = {name: "Walter White", age: 52};
        return profile.cloneReadOnly();
    }

    isolated resource function get book() returns Book {
        return {name: "Nineteen Eighty-Four", author: "George Orwell"};
    }

    isolated resource function get names(Species[] & readonly species) returns string[] {
        return species.map(sp => sp.specificName);
    }

    isolated resource function get cities(Address[] addresses) returns string[] {
        return addresses.map(address => address.city);
    }

    isolated resource function get profiles() returns ProfileDetail[] & readonly {
        ProfileDetail[] profiles = [
            {name: "Walter White", age: 52},
            {name: "Jesse Pinkman", age: 25}
        ];
        return profiles.cloneReadOnly();
    }

    isolated resource function get books() returns Book[] {
        return [
            {name: "Nineteen Eighty-Four", author: "George Orwell"},
            {name: "The Magic of Reality", author: "Richard Dawkins"}
        ];
    }

    isolated resource function get commonName(Animal animal) returns string {
        return animal.commonName;
    }

    isolated resource function get ownerName(Pet pet) returns string {
        return pet.ownerName;
    }
}

service /nullable_inputs on basicListener {
    resource function get city(Address? address) returns string? {
        if address is Address {
            return address.city;
        }
        return;
    }

    resource function get cities(Address[]? addresses) returns string[]? {
        if addresses is Address[] {
            return addresses.map(address => address.city);
        }
        return;
    }

    resource function get accountNumber(Account account) returns int {
        return account.number;
    }
}

public string[] namesArray = ["Walter", "Skyler"];

service /subscriptions on basicListener {
    isolated resource function get name() returns string {
        return "Walter White";
    }

    resource function subscribe name() returns stream<string, error?> {
        return namesArray.toStream();
    }

    isolated resource function subscribe messages() returns stream<int, error?> {
        int[] intArray = [1, 2, 3, 4, 5];
        return intArray.toStream();
    }

    isolated resource function subscribe stringMessages() returns stream<string?, error?> {
        string?[] stringArray = [(), "1", "2", "3", "4", "5"];
        return stringArray.toStream();
    }

    isolated resource function subscribe books() returns stream<Book, error?> {
        Book[] books = [
            {name: "Crime and Punishment", author: "Fyodor Dostoevsky"},
            {name: "A Game of Thrones", author: "George R.R. Martin"}
        ];
        return books.toStream();
    }

    isolated resource function subscribe students() returns stream<StudentService, error?> {
        StudentService[] students = [new StudentService(1, "Eren Yeager"), new StudentService(2, "Mikasa Ackerman")];
        return students.toStream();
    }

    isolated resource function subscribe filterValues(int value) returns stream<int, error?> {
        int[] intArray = [1, 2, 3, 4, 5];
        int[] filteredArray = [];
        foreach int i in intArray {
            if i < value {
                filteredArray.push(i);
            }
        }
        return filteredArray.toStream();
    }

    isolated resource function subscribe values() returns stream<int> {
        int[] array = [];
        int _ = array.remove(0);
        return array.toStream();
    }

    isolated resource function subscribe multipleValues() returns stream<(PeopleService)>|error {
        StudentService s = new StudentService(1, "Jesse Pinkman");
        TeacherService t = new TeacherService(0, "Walter White", "Chemistry");
        return [s, t].toStream();
    }
}

# GraphQL service with documentation.
service /documentation on basicListener {

    # Greets a person with provided name.
    #
    # + name - The name of the person
    # + return - The personalized greeting message
    isolated resource function get greeting(string name) returns string {
        return string`Hello ${name}`;
    }

    # Returns a predefined instrument.
    #
    # + return - Details of the Guitar
    isolated resource function get instrument() returns Instrument {
        return {
            name: "Guitar",
            'type: STRINGS
        };
    }

    # Updates a shape in the database.
    #
    # + name - Name of the new shape
    # + edges - Number of edges of the new shape
    # + return - The newly created shape
    remote function addShape(string name, int edges) returns Shape {
        return {name: name, edges: edges};
    }
}

# GraphQL service with deprecated fields and enum values.
service /deprecation on wrappedListener {

    # Hello world field.
    # + name - The name of the person
    # + return - The personalized greeting message
    # # Deprecated
    # Use the `greeting` field instead of this field.
    @deprecated
    isolated resource function get hello(string name) returns string {
        return string `Hello ${name}`;
    }

    # Greets a person with provided name.
    #
    # + name - The name of the person
    # + return - The personalized greeting message
    isolated resource function get greeting(string name) returns string {
        return string `Hello ${name}`;
    }

    # Retrieve information about music school.
    # + return - The school object
    isolated resource function get school() returns School {
        return new ("The Juilliard School");
    }

    # Creates a new instrument.
    #
    # + name - Name of the instrument
    # + 'type - Type of the instrument
    # + return - The newly created instrument
    # # Deprecated
    # Use the `addInstrument` field instead of this.
    @deprecated
    remote function newInstrument(string name, InstrumentType 'type) returns Instrument {
        return {name: name, 'type: 'type};
    }

    # Adds a new instrument to the database.
    #
    # + name - Name of the instrument
    # + 'type - Type of the instrument
    # + return - The newly added instrument
    remote function addInstrument(string name, InstrumentType 'type) returns Instrument {
        return {name: name, 'type: 'type};
    }

    # Subscribes to the new instruments.
    #
    # + return - The instrument name list
    # # Deprecated
    # Use the `instruments` field instead of this.
    @deprecated
    resource function subscribe newInstruments() returns stream<string> {
        return ["Guitar", "Violin", "Drums"].toStream();
    }

    # Subscribes to the new instruments.
    #
    # + return - The instrument name list
    resource function subscribe instruments() returns stream<string> {
        return ["Guitar", "Violin", "Drums"].toStream();
    }
}

// **************** Interceptor-Related Services ****************

@graphql:ServiceConfig {
    interceptors: [new StringInterceptor1(), new StringInterceptor2(), new StringInterceptor3()]
}
service /intercept_string on basicListener {
    resource function get enemy() returns string {
        return "voldemort";
    }
}

@graphql:ServiceConfig {
    interceptors: [new Counter(), new Counter(), new Counter()]
}
service /intercept_int on basicListener {
    isolated resource function get age() returns int {
        return 23;
    }
}

@graphql:ServiceConfig {
    interceptors: [new RecordInterceptor()]
}
service /intercept_records on basicListener {
    isolated resource function get profile() returns Person {
        return {
            name: "Albus Percival Wulfric Brian Dumbledore",
            age: 80,
            address: {number: "101", street: "Mould-on-the-Wold", city: "London"}
        };
    }
}

@graphql:ServiceConfig {
    interceptors: [new HierarchycalPath()]
}
service /intercept_hierachical on basicListener {
    isolated resource function get name/first() returns string {
        return "Sherlock";
    }

    isolated resource function get name/last() returns string {
        return "Holmes";
    }
}

@graphql:ServiceConfig {
    interceptors: [new Destruct()]
}
service /intercept_service_obj_arrays on basicListener {
    resource function get students() returns StudentService[] {
        return [new StudentService(45, "Ron Weasly"), new StudentService(46, "Hermione Granger")];
    }
}

@graphql:ServiceConfig {
    interceptors: [new ServiceObjectInterceptor1()]
}
service /intercept_service_obj on basicListener {
    resource function get teacher() returns TeacherService {
        return new TeacherService(2, "Severus Snape", "Defence Against the Dark Arts");
    }
}

@graphql:ServiceConfig {
    interceptors: [new ServiceObjectInterceptor2()]
}
service /intercept_service_obj_array on basicListener {
    resource function get students() returns StudentService[] {
        return [new StudentService(45, "Ron Weasly"), new StudentService(46, "Hermione Granger")];
    }
}

@graphql:ServiceConfig {
    interceptors: [new ArrayInterceptor()]
}
service /intercept_arrays on basicListener {
    resource function get houses() returns string[] {
        return ["Gryffindor(Fire)", "Hufflepuff(Earth)", "Ravenclaw(Air)"];
    }
}

@graphql:ServiceConfig {
    interceptors: [new EnumInterceptor()]
}
service /intercept_enum on basicListener {
    isolated resource function get holidays() returns Weekday[] {
        return [SATURDAY, SUNDAY];
    }
}

@graphql:ServiceConfig {
    interceptors: [new UnionInterceptor()]
}
service /intercept_unions on serviceTypeListener {
    isolated resource function get profile(int id) returns StudentService|TeacherService {
        if id < 100 {
            return new StudentService(1, "Jesse Pinkman");
        } else {
            return new TeacherService(737, "Walter White", "Chemistry");
        }
    }
}

@graphql:ServiceConfig {
    interceptors: [new InterceptMutation()]
}
isolated service /mutation_interceptor on basicListener {
    private Person p;

    isolated function init() {
        self.p = p2.clone();
    }

    isolated resource function get person() returns Person {
        lock {
            return self.p;
        }
    }

    isolated remote function setName(string name) returns Person {
        lock {
            Person p = {name: name, age: self.p.age, address: self.p.address};
            self.p = p;
            return self.p;
        }
    }
}

@graphql:ServiceConfig {
    interceptors: [new InvalidInterceptor1(), new InvalidInterceptor2()]
}
service /invalid_interceptor1 on basicListener {
    isolated resource function get age() returns int {
        return 23;
    }
}

@graphql:ServiceConfig {
    interceptors: [new InvalidInterceptor3(), new InvalidInterceptor4()]
}
service /invalid_interceptor2 on basicListener {
    isolated resource function get friends() returns string[] {
        return ["Harry", "Ron", "Hermione"];
    }
}

@graphql:ServiceConfig {
    interceptors: [new InvalidInterceptor5(), new InvalidInterceptor6()]
}
service /invalid_interceptor3 on basicListener {
    isolated resource function get person() returns Person {
        return  {
            name: "Albus Percival Wulfric Brian Dumbledore",
            age: 80,
            address: {number: "101", street: "Mould-on-the-Wold", city: "London"}
        };
    }
}

@graphql:ServiceConfig {
    interceptors: [new InvalidInterceptor7()]
}
service /invalid_interceptor4 on basicListener {
    resource function get student() returns StudentService {
        return new StudentService(45, "Ron Weasly");
    }
}

@graphql:ServiceConfig {
    interceptors: [new ErrorInterceptor1()]
}
service /intercept_errors1 on basicListener {
    isolated resource function get greet() returns string|error {
        return error("This is an invalid field!");
    }
}

@graphql:ServiceConfig {
    interceptors: [new ErrorInterceptor1()]
}
service /intercept_errors2 on basicListener {
    isolated resource function get friends() returns string[] {
        return ["Harry", "Ron", "Hermione"];
    }
}

@graphql:ServiceConfig {
    interceptors: [new ErrorInterceptor1()]
}
service /intercept_errors3 on basicListener {
    isolated resource function get person() returns Person {
        return  {
            name: "Albus Percival Wulfric Brian Dumbledore",
            age: 80,
            address: {number: "101", street: "Mould-on-the-Wold", city: "London"}
        };
    }
}

@graphql:ServiceConfig {
    interceptors: [new Execution1(), new Execution2()],
    contextInit:
    isolated function(http:RequestContext requestContext, http:Request request) returns graphql:Context|error {
        graphql:Context context = new;
        context.set("subject", "Ballerina");
        context.set("beVerb", "is");
        return context;
    }
}
service /intercept_order on basicListener {
    isolated resource function get quote() returns string {
        return "an open-source";
    }
}
