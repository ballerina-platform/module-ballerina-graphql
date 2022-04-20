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

service graphql:Service on new graphql:Listener(4000) {
    resource function get greet() returns GeneralGreeting {
        return new;
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get greet() returns GeneralGreeting|Status {
        return new GeneralGreeting();
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get greet() returns FirstName|Status {
        return new Status();
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get greet() returns FirstName {
        return new;
    }
}

distinct service class GeneralGreeting {
    resource function post generalGreeting() returns string {
        return "Hello, world";
    }
}

distinct service class Status {
    resource function post status() returns boolean {
        return true;
    }
}

distinct service class FirstName {
    resource function get name() returns string {
        return "James";
    }
}
