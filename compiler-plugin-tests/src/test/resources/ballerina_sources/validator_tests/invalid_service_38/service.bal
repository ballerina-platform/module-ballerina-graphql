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

type Person record {|
    string name;
    int age;
    record {| int number; string street; string city; |} address;
|};

service on new graphql:Listener(4000) {
    resource function get profile() returns Person {
        return {
            name: "Walter White",
            age: 52,
            address: {
                number: 308,
                street: "Negra Arroyo Lane",
                city: "Albequerque"
            }
        };
    }

    resource function get address() returns record {| int number; string street; string city; |} {
        return {
            number: 308,
            street: "Negra Arroyo Lane",
            city: "Albequerque"
        };
    }

    resource function get 'class() returns Class {
        return new;
    }
}

service class Class {
    resource function get profile() returns record {| string name; int age; |} {
        return {name: "Walter White", age: 52};
    }
}

service on new graphql:Listener(4000) {
    resource function get name(record {| string name; int age; |} profile) returns string {
        return profile.name;
    }

    resource function get school() returns School {
        return new;
    }
}

service class School {
    resource function get name(record {| string name; int age; |} profile) returns string {
        return profile.name;
    }
}
