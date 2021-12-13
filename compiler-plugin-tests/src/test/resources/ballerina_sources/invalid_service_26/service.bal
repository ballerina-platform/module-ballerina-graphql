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

type Book record {
    string name;
    Person author;
};

type Location record {
    float latitude;
    float longitude;
};

service /graphql on new graphql:Listener(4000) {
    resource function get profile(Person[] p) returns Person {
        return {
           name: "Walter",
           age: 57
        };
    }
}

service /graphql on new graphql:Listener(4000) {
    resource function get profile(Person[] p) returns Person[] {
        return [
            {
               name: "Walter",
               age: 57
            },
            {
               name: "Jessie",
               age: 27
            }
        ];
    }
}

service /graphql on new graphql:Listener(4000) {
    resource function get book(Book[] b) returns Person {
        return {
           name: "Walter",
           age: 57
        };
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get locationArray(Location[] location) returns float[] {
        return [7.8, 56.8];
    }

    resource function get location() returns Location {
        return {
            latitude: 8.7,
            longitude:56.7
        };
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get location() returns Location {
        return {
            latitude: 8.7,
            longitude:56.7
        };
    }

    resource function get locationArray(Location[] location) returns float[] {
        return [8.7, 56.7];
    }
}
