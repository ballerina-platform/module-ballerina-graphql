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
import ballerina/http;

# Represents a Person
#
# + name - Name of the person
# + age - age of the person
type Person record {
    string name;
    int age;
};

# Represents an address.
#
# + number - The number of the address
# + street - The street of the address
# + city - The city of the address
type Address record {
    int number;
    string street;
    string city;
};

@graphql:ServiceConfig {
    contextInit:
    isolated function(http:RequestContext requestContext, http:Request request) returns graphql:Context|error {
        graphql:Context context = new;
        context.set("scope", check request.getHeader("scope"));
        return context;
    }
}
isolated service on new graphql:Listener(9000) {

    isolated resource function get profile() returns Person {
        return {
            name: "Walter White",
            age: 52
        };
    }
}
