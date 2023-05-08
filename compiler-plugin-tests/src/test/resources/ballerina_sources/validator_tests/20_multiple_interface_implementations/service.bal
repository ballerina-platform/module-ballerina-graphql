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
    isolated resource function get name(@graphql:ID int id) returns Animal {
        return new Dog("Lassie", "Sam");
    }
}

public type Animal distinct service object {
    isolated resource function get 'class() returns string;
};

public type Mammal distinct service object {
    *Animal;
    isolated resource function get legs() returns int;
};

public type Pet distinct service object {
    isolated resource function get owner() returns string;
};

public isolated distinct service class Dog {
    *Mammal;
    *Pet;
    final string 'class = "Mammalia";
    final int numberOfLegs = 4;
    final string name;
    final string owner;

    isolated function init(string name, string owner) {
        self.name = name;
        self.owner = owner;
    }

    isolated resource function get 'class() returns string {
        return self.'class;
    }

    isolated resource function get legs() returns int {
        return self.numberOfLegs;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get owner() returns string {
        return self.owner;
    }
}
