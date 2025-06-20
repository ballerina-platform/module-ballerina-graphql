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
import ballerina/lang.runtime;
import ballerina/uuid;

graphql:Service graphiqlDefaultPathConfigService =
@graphql:ServiceConfig {
    graphiql: {
        enabled: true
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
        enabled: true,
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
        enabled: true
    }
}
service /graphiql/test on basicListener {
    isolated resource function get greet() returns string {
        return "Hello";
    }
}

@graphql:ServiceConfig {
    graphiql: {
        enabled: true,
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
        enabled: true
    }
}
service on serviceTypeListener {
    isolated resource function get greet() returns string {
        return "Hello";
    }
}

@graphql:ServiceConfig {
    graphiql: {
        enabled: true,
        path: "graphiql/interface"
    }
}
service /graphiqlClient on basicListener {
    isolated resource function get greet() returns string {
        return "Hello";
    }
}

const float CONVERSION_KG_TO_LBS = 2.205;

service /inputs on basicListener {
    isolated resource function get greet(string name) returns string {
        return "Hello, " + name;
    }

    isolated resource function get name(string name = "Walter") returns string {
        return name;
    }

    isolated resource function get isLegal(int age) returns boolean {
        if age < 21 {
            return false;
        }
        return true;
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

    isolated resource function get name(DefaultPerson person) returns string {
        return person.name;
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

@graphql:ServiceConfig {
    documentCacheConfig: {}
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

    resource function get profile(int id) returns Person|error {
        return trap people[id];
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

    isolated resource function get person(graphql:Field 'field) returns Person {
        string[] subfieldNames = 'field.getSubfieldNames();
        if subfieldNames == ["name"] {
            return {
                name: "Sherlock Holmes",
                address: {number: "221/B", street: "Baker Street", city: "London"}
            };
        } else if subfieldNames == ["name", "age"] {
            return {
                name: "Walter White",
                age: 50,
                address: {number: "309", street: "Negro Arroyo Lane", city: "Albuquerque"}
            };
        }
        return {
            name: "Jesse Pinkman",
            age: 25,
            address: {number: "208", street: "Margo Street", city: "Albuquerque"}
        };
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

    isolated resource function get student(string name, graphql:Context context, int id,
            graphql:Field 'field) returns StudentService {
        if context.get("scope") is error {
            // ignore
        }
        if 'field.getSubfieldNames().indexOf("id") is int {
            return new StudentService(id, name);
        }
        return new StudentService(10, "Jesse Pinkman");
    }
}

service /timeoutService on timeoutListener {
    isolated resource function get greet() returns string {
        runtime:sleep(3);
        return "Hello";
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

    resource function get tasks() returns TaskTable {
        return tasks;
    }
}

service /special_types on wrappedListener {
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

    resource function get month(Month month) returns string {
        return month;
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

    isolated resource function get project() returns Project {
        return {
            name: "Ballerina",
            manager: "Unknown",
            tasks: {
                sprint: 75,
                subTasks: ["GraphQL-task1", error("Undefined task!"), "HTTP-task2"]
            }
        };
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

    resource function get name(graphql:Context context, graphql:Field 'field, int? id) returns string? {
        if id == () {
            graphql:__addError(context, {
                                            message: "Data not found",
                                            locations: ['field.getLocation()],
                                            path: 'field.getPath()
                                        });
            return;
        }
        return "Walter White";
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

# GraphQL service with documentation.
service /documentation on basicListener {

    # Greets a person with provided name.
    #
    # + name - The name of the person
    # + return - The personalized greeting message
    isolated resource function get greeting(string name) returns string {
        return string `Hello ${name}`;
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

    # Retrieve information about the person.
    # + return - The person object
    isolated resource function get profile() returns DeprecatedProfile {
        return {name: "Alice", age: 30, address: {number: 1, street: "main", city: "NYC"}};
    }

    # Retrieve information about music school.
    # + return - The school object
    isolated resource function get school() returns School {
        return new ("The Juilliard School");
    }

    # Add a new person.
    # + return - The person object
    remote function addProfile(string name, int age) returns DeprecatedProfile {
        return {name: name, age: age, address: {number: 1, street: "main", city: "NYC"}};
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

service /maps on basicListener {
    private final Languages languages;

    function init() {
        self.languages = {
            name: {
                backend: "Ballerina",
                frontend: "JavaScript",
                data: "Python",
                native: "C++"
            }
        };
    }

    isolated resource function get languages() returns Languages {
        return self.languages;
    }
}

graphql:Service greetingService = service object {
    resource function get greeting() returns string {
        return "Hello, World";
    }
};

graphql:Service greetingService2 = @graphql:ServiceConfig {maxQueryDepth: 5} service object {
    resource function get greeting() returns string {
        return "Hello, World";
    }
};

service /covid19 on basicListener {
    resource function get all() returns table<CovidEntry> {
        table<CovidEntry> covidEntryTable = table [
            {isoCode: "AFG"},
            {isoCode: "SL"},
            {isoCode: "US"}
        ];
        return covidEntryTable;
    }
}

table<Review> reviews = table [
    {product: new ("1"), score: 20, description: "Product 01"},
    {product: new ("2"), score: 20, description: "Product 02"},
    {product: new ("3"), score: 20, description: "Product 03"},
    {product: new ("4"), score: 20, description: "Product 04"},
    {product: new ("5"), score: 20, description: "Product 05"}
];

service /reviews on wrappedListener {
    resource function get latest() returns Review {
        return reviews.toArray().pop();
    }

    resource function get all() returns table<Review> {
        return reviews;
    }

    resource function get top3() returns Review[] {
        return from var review in reviews
            limit 3
            select review;
    }

    resource function get account() returns AccountRecords {
        return {details: {acc1: new ("James", 2022), acc2: new ("Paul", 2015)}};
    }
}

isolated service /service_with_http2 on http2BasedListener {
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

isolated service /service_with_http1 on wrappedListener {
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

@display {
    label: "diplay",
    id: "display-1"
}
service /annotations on wrappedListener {
    resource function get greeting() returns string {
        return "Hello";
    }
}

service /id_annotation_1 on basicListener {
    resource function get student1(@graphql:ID int id1) returns Student1 {
        return new Student1(8);
    }

    resource function get student2(@graphql:ID float[] id2) returns Student2 {
        return new Student2([1.0, 2.0]);
    }

    resource function get student3(@graphql:ID uuid:Uuid?[] id3) returns Student3|error {
        return new Student3([check uuid:createType1AsRecord()]);
    }

    resource function get student4(@graphql:ID int?[]? id4) returns Student4 {
        return new Student4([1, 2, (), 4]);
    }
}

public distinct service class Student1 {
    final int id;

    function init(int id) {
        self.id = id;
    }

    resource function get id() returns @graphql:ID int {
        return self.id;
    }
}

public distinct service class Student2 {
    final float[] id;

    function init(float[] id) {
        self.id = id;
    }

    resource function get id() returns @graphql:ID float[] {
        return self.id;
    }
}

public distinct service class Student3 {
    final uuid:Uuid?[] id;

    function init(uuid:Uuid?[] id) {
        self.id = id;
    }

    resource function get id() returns @graphql:ID uuid:Uuid?[] {
        return self.id;
    }
}

public distinct service class Student4 {
    final int?[]? id;

    function init(int?[]? id) {
        self.id = id;
    }

    resource function get id() returns @graphql:ID int?[]? {
        return self.id;
    }
}

@graphql:ServiceConfig {
    validation: false
}
service /id_annotation_2 on basicListener {
    resource function get stringId(@graphql:ID string stringId) returns string {
        return "Hello, World";
    }

    resource function get intId(@graphql:ID int intId) returns string {
        return "Hello, World";
    }

    resource function get floatId(@graphql:ID float floatId) returns string {
        return "Hello, World";
    }

    resource function get decimalId(@graphql:ID decimal decimalId) returns string {
        return "Hello, World";
    }

    resource function get stringId1(@graphql:ID string? stringId) returns string {
        return "Hello, World";
    }

    resource function get intId1(@graphql:ID int? intId) returns string {
        return "Hello, World";
    }

    resource function get floatId1(@graphql:ID float? floatId) returns string {
        return "Hello, World";
    }

    resource function get decimalId1(@graphql:ID decimal? decimalId) returns string {
        return "Hello, World";
    }

    resource function get intIdReturnRecord(@graphql:ID int intId) returns Student5 {
        return new Student5(2, "Jennifer Flackett");
    }

    resource function get intArrayReturnRecord(@graphql:ID int[] intId) returns Student5 {
        return new Student5(333, "Antoni Porowski");
    }

    resource function get stringArrayReturnRecord(@graphql:ID string[] stringId) returns Student5 {
        return new Student5(212, "Andrew Glouberman");
    }

    resource function get floatArrayReturnRecord(@graphql:ID float[] floatId) returns Student5 {
        return new Student5(422, "Elliot Birch");
    }

    resource function get decimalArrayReturnRecord(@graphql:ID decimal[] decimalId) returns Student5 {
        return new Student5(452, "Edward MacDell");
    }

    resource function get uuidReturnRecord(@graphql:ID uuid:Uuid uuidId) returns Student5 {
        return new Student5(2678, "Abuela Alvarez");
    }

    resource function get uuidArrayReturnRecord(@graphql:ID uuid:Uuid[] uuidId) returns Student5 {
        return new Student5(678, "Andy Garcia");
    }

    resource function get uuidArrayReturnRecord1(@graphql:ID uuid:Uuid[]? uuidId) returns Student5 {
        return new Student5(563, "Aretha Franklin");
    }

    resource function get stringIdReturnRecord(@graphql:ID string stringId) returns PersonId {
        return {id: 543, name: "Marmee March", age: 12};
    }

    resource function get stringArrayReturnRecordArray(@graphql:ID string[] stringIds) returns PersonId[] {
        return [
            {id: 789, name: "Beth Match", age: 15},
            {id: 678, name: "Jo March", age: 16},
            {id: 543, name: "Amy March", age: 12}
        ];
    }

    resource function get floatArrayReturnRecordArray(@graphql:ID float[] floatIds) returns PersonId[] {
        return [
            {id: 789, name: "Beth Match", age: 15},
            {id: 678, name: "Jo March", age: 16},
            {id: 543, name: "Amy March", age: 12}
        ];
    }

    resource function get inputObjectWithIdType(PersonInput input) returns string {
        return input.name.toString();
    }

    resource function get inputObjectWithNestedIdType(NestedIdInput input) returns PersonDetail {
        return {name: input.person.name.toString(), id: input.id.toString()};
    }

    resource function get inputObjectWithNestedIdTypeInArray(NestedIdInput[] input) returns PersonDetail {
        return {name: input[0].person.name.toString(), id: input[0].id.toString()};
    }

    resource function get inputObjectWithNestedIdTypeArray(PersonArrInput input) returns PersonDetail {
        return {name: input.persons[0].name.toString(), id: input.ids[0].toString()};
    }
}

public type PersonInput record {|
    @graphql:ID
    string name;
|};

public type NestedIdInput record {|
    @graphql:ID
    int id;
    PersonInput person;
|};

public type PersonDetail record {|
    string name;
    string id;
|};

public type PersonId record {|
    @graphql:ID
    int id;
    string name;
    int age;
|};

public type PersonArrInput record {|
    @graphql:ID
    int[] ids;
    PersonInput[] persons;
|};

public distinct service class Student5 {
    final int id;
    final string name;

    function init(int id, string name) {
        self.id = id;
        self.name = name;
    }

    resource function get id() returns @graphql:ID int {
        return self.id;
    }

    resource function get name() returns string {
        return self.name;
    }
}

service /defaultParam on wrappedListener {
    resource function get intParam(int a = 1) returns string? => ();

    resource function get floatParam(float b = 2.0) returns string? => ();

    resource function get decimalParam(decimal c = 1e-10) returns string? => ();

    resource function get stringParam(string d = "value") returns string? => ();

    resource function get booleanParam(boolean e = true) returns string? => ();

    resource function get nullableParam(int? f = DEFAULT_INT_VALUE) returns string? => ();

    remote function enumParam(Sex g = MALE) returns string? => ();

    remote function inputObjectParam(InputObject h) returns string? => ();

    remote function inputObjectArrayParam(InputObject[] i = [
                {name: "name2", bmiHistory: [1.0, 2.0]},
                {name: "name3", bmiHistory: [1e-7, 2.0]}
            ]) returns string? => ();

    resource function subscribe idArrayParam(@graphql:ID string[] j = ["id1"]) returns stream<string>? => ();

    resource function get multipleParams(
            int a = 1,
            float b = 2.0,
            decimal c = 1e-10,
            string d = "value",
            boolean e = true,
            int? f = DEFAULT_INT_VALUE,
            Sex g = MALE,
            InputObject h = {name: "name2", bmiHistory: [30.0, 29.0, 20.0d]},
            InputObject[] i = [
                {name: "name3", bmiHistory: [30.0, 29.0]},
                {name: "name4", bmiHistory: [2.9e1, 31.0]}
            ],
            @graphql:ID string[] j = ["id1"]) returns string? => ();

    resource function get nestedField() returns NestedField => new;
}

class ServiceDeclarationOnObjectField {

    private graphql:Service objectFieldService = service object {
        resource function get greeting() returns string {
            return "Hello world";
        }
    };

    public function init() {
    }

    public function getService() returns graphql:Service {
        return self.objectFieldService;
    }

}

service /evict_server_cache on basicListener {
    private string name = "Walter White";

    isolated resource function get greet() returns string {
        return "Hello, " + self.name;
    }

    @graphql:ResourceConfig {
        cacheConfig: {
            enabled: true
        }
    }
    isolated resource function get name(int id) returns string {
        return self.name;
    }

    isolated remote function updateName(graphql:Context context, string name) returns string|error {
        check context.invalidate("name");
        self.name = name;
        return self.name;
    }
}
