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
    isolated resource function get name(int id) returns Animal {
        return new Dog("Lassie");
    }
}

public type Animal distinct service object {
    isolated resource function get 'class() returns string;
};

public type Mammal distinct service object {
    *Animal;
    isolated resource function get legs() returns int;
};

public isolated distinct service class Dog {
    *Mammal;
    final string 'class;
    final int numberOfLegs;
    final string name;

    isolated function init(string name) {
        self.numberOfLegs = 4;
        self.'class = "Mammalia";
        self.name = name;
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
}
