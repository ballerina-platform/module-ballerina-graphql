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

// tests for invalid return types in return type service class definitions - 2 errors expected
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
    // invalid json - 1
    resource function get greeting() returns json {
        json j1 = "Apple";
        return j1;
    }
}

distinct service class Status {
    // invalid byte - 2
    resource function get greeting() returns byte {
         byte a = 12;
         return a;
    }
}

distinct service class FirstName {
    // valid
    resource function get name() returns string {
        return "James";
    }
}
