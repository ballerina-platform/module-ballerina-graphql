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

# Contains profile information.
service /graphql on new graphql:Listener(4000) {

    # Returns the first name of the profile
    #
    # + return - First name
    isolated resource function get profile/name/first() returns string {
        return "Walter";
    }

    # Returns the last name of the profile
    #
    # + return - Last name
    isolated resource function get profile/name/last() returns string {
        return "White";
    }

    # Returns the age of the profile
    #
    # + return - Age
    isolated resource function get profile/age() returns int {
        return 52;
    }

    # Returns the number of the address
    #
    # + return - number
    isolated resource function get profile/address/number() returns int {
        return 308;
    }

    # Returns the street of the address
    #
    # + return - street
    isolated resource function get profile/address/street() returns string {
        return "Negra Arroyo Lane";
    }

    # Returns the city of the address
    #
    # + return - city
    isolated resource function get profile/address/city() returns string {
        return "Albuquerque";
    }
}
