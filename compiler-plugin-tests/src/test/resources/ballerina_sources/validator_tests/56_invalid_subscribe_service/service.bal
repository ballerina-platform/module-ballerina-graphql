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
    isolated resource function subscribe events() returns stream<string> {
        string[] messages = ["Walter", "Jesse", "Mike", "Gus", "Skyler"];
        return messages.toStream();
    }
}

service /graphql on new graphql:Listener(4000) {
    isolated resource function get greeting() returns string {
        return "Hello, world";
    }

    isolated resource function subscribe profiles() returns stream<Person> {
        Person[] people = [{name: "Walter", age: 52, bytes: []},{name: "Jesse", age: 25, bytes: []}];
        return people.toStream();
    }

    isolated resource function subscribe animals() returns stream<Animal> {
        Animal[] animals = [new ("Kitty", 6), new ("Kiddy", 2)];
        return animals.toStream();
    }
}

type Person record {
    string name;
    int age;
    byte[] bytes;
};

isolated service class Animal {
    private final string name;
    private final int age;

    isolated function init(string name, int age) {
        self.name = name;
        self.age = age;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function subscribe age() returns int {
        return self.age;
    }
}
