// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/lang.runtime;
import ballerina/graphql;

service / on new graphql:Listener(9090) {
    resource function get greeting() returns string {
        return "Hello from global listener binding service";
    }
}

graphql:Service globalService = service object {
    resource function get greeting() returns string {
        return "Hello from global service";
    }
};

service /too on new graphql:Listener(9091) {
    resource function get greeting() returns string {
        return "Hello from global listener binding service too";
    }
}

public function main() returns error? {
    graphql:Service localService1 = service object {
        resource function get greeting() returns string {
            return "Hello from local service 1";
        }
    };

    graphql:Service localService2 = service object {
            resource function get greeting() returns string {
                return "Hello from local service 2";
            }
        };
    graphql:Listener localListener1 = check new(9092);
    graphql:Listener localListener2 = check new(9093);
    graphql:Listener globalListener = check new(9094);
    check localListener1.attach(localService1);
    check localListener2.attach(localService2);
    check globalListener.attach(globalService);
    check localListener1.'start();
    check localListener2.'start();
    check globalListener.'start();
    runtime:registerListener(localListener1);
    runtime:registerListener(localListener2);
    runtime:registerListener(globalListener);
}