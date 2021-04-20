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
};

type Student record {
    int age;
};

service graphql:Service on new graphql:Listener(4000) {
    isolated resource function get greeting() returns string {
        return "Hello";
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get name() returns string {
        return "John";
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get name() returns string|error {
        return "John";
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get name() returns string|error? {
        return "John";
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get weight() returns float {
        return 80.5;
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get weight() returns float|error {
        return 80.5;
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get married() returns boolean {
        return true;
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get married() returns boolean|error {
        return true;
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get profile() returns Person {
        return {name: "John"};
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get profile() returns Person|Student {
        return {name: "John"};
    }
}

service graphql:Service on new graphql:Listener(4000) {
    isolated resource function get greet() returns GeneralGreeting {
        return new;
    }
}

service class GeneralGreeting {
    isolated resource function get generalGreeting() returns string {
        return "Hello, world";
    }
}
