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

service /inputs on graphqlListener {
    isolated resource function get greet(string name) returns string {
        return "Hello, " + name;
    }
}

service /records on graphqlListener {
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

service /special_types on graphqlListener {
    isolated resource function get time() returns Time {
        return {
            weekday: MONDAY,
            time: "22:10:33"
        };
    }

    isolated resource function get specialHolidays() returns (Weekday|error)?[] {
        return [TUESDAY, error("Holiday!"), THURSDAY];
    }
}

isolated service /mutations on graphqlListener {
    private Person p;

    isolated function init() {
        self.p = p2.clone();
    }

    isolated resource function get greet(string name) returns string {
        return "Hello, " + name;
    }

    isolated remote function setName(string name) returns Person {
        lock {
            Person p = {name: name, age: self.p.age, address: self.p.address};
            self.p = p;
            return self.p;
        }
    }
}

service /profiles on graphqlListener {
    isolated resource function get profile/name/first() returns string {
        return "Sherlock";
    }

    isolated resource function get profile/address/city() returns string {
        return "London";
    }
}
