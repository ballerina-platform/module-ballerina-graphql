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
    resource function get profile() returns Person {
        return new("Waler White", 52);
    }
}

# Represents a Person as a class.
public isolated service class Person {
    final string name;
    final int age;

    isolated function init(string name, int age) {
        self.name = name;
        self.age = age;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get age() returns int {
        return self.age;
    }

    isolated resource function get address() returns Address {
        return new(308, "Negra Arroyo Lane", "Albequerque");
    }
}

public isolated service class Address {
    final int number;
    final string street;
    final string city;

    isolated function init(int number, string street, string city) {
        self.number = number;
        self.street = street;
        self.city = city;
    }

    isolated resource function get number() returns int {
        return self.number;
    }

    isolated resource function get street() returns string {
        return self.street;
    }

    isolated resource function get city() returns string {
        return self.city;
    }
}
