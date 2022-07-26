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

public type Person record {
    string name;
    int age;
    Person[] friends;
};

public type Book readonly & record {|
    string name;
    string author;
|};

service /graphql on new graphql:Listener(4000) {
    isolated resource function get name(Person & readonly person) returns string {
        return person.name;
    }

    isolated resource function get name(readonly & Person[] person) returns string {
        return person.name;
    }
}

service /graphql on new graphql:Listener(4000) {
    isolated resource function get profile() returns Person {
        return {name: "Walter White", age: 52, friends: []};
    }
}

service on new graphql:Listener(4000) {
    isolated resource function get profile() returns Person & readonly {
        return {name: "Walter White", age: 52, friends: []}.cloneReadOnly();
    }

    isolated resource function get profiles() returns readonly & Person[] {
        return [{name: "Walter White", age: 52, friends: []}].cloneReadOnly();
    }
}

service on new graphql:Listener(4000) {
    resource function get book() returns Book {
        return {
            name: "The Fabric of the Cosmos",
            author: "Brian Green"
        };
    }

    resource function get books() returns Book[] {
        return [{name: "Magic of Reality", author: "Richard Dawkins"}];
    }
}
