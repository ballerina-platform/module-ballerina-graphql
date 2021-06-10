// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

type Person record {
    string name;
    int age;
};

service graphql:Service on new graphql:Listener(4000) {
    string name = "Sherlock Holmes";
    int age = 54;
    Person person = {
        name : "Walter White",
        age : 60
    };

    isolated resource function get name(string name) returns string {
        return name;
    }

    isolated resource function get age() returns int {
        return self.age;
    }

    isolated resource function get person() returns Person {
        return self.person;
    }
}