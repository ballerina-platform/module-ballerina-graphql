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

type MultiService FirstName|CivilStatus;

service graphql:Service on new graphql:Listener(4000) {
    resource function get greet() returns CivilStatus? {
        return new CivilStatus();
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get details() returns FirstName|Age|CivilStatus|error {
        return new FirstName();
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get details() returns FirstName|Age? {
        return new FirstName();
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get details() returns FirstName|CivilStatus {
        return new FirstName();
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get greet() returns FirstName[]? {
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get greet() returns MultiService? {
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get greet() returns MultiService {
        return new FirstName();
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get greet() returns MultiService[] {
        return [];
    }
}

distinct service class CivilStatus {
    resource function get civilStatus() returns boolean {
        return false;
    }
}

distinct service class FirstName {
    resource function get firstName() returns string {
        return "Bugs";
    }
}

distinct service class Age {
    resource function get age() returns int {
        return 15;
    }
}
