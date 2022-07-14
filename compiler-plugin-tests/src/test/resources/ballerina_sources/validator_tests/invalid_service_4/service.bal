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
    resource function get greeting() returns map<int>  {
        return {sam: 50, jon: 60};
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get greeting() returns json {
        json j1 = "Apple";
        return j1;
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get greeting() returns byte {
         byte a = 12;
         return a;
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get greeting() returns byte[] {
        byte[] arr1 = [5, 24, 56, 243];
        return arr1;
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get marks() returns float|decimal { // Union of two scalars
        return 80.5;
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get id() returns Person|string {  // Union of two types
        return "1234";
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get profile() returns Person|Student { // union of two records
        return {name: "John"};
    }
}

service graphql:Service on new graphql:Listener(4000) {
    // Invalid - Returning dynamic service object
    resource function get foo() returns service object {} {
        return service object {
            resource function get name() returns string {
                return "name";
            }
        };
    }
}

readonly service class ServiceInterceptor {
    *graphql:Interceptor;

    isolated remote function execute(graphql:Context ctx, graphql:Field 'field) returns anydata|error {
        anydata|error result = ctx.resolve('field);
        return result;
    }
}

service graphql:Service on new graphql:Listener(4000) {
    resource function get foo() returns graphql:Interceptor {
        return new ServiceInterceptor();
    }
}
