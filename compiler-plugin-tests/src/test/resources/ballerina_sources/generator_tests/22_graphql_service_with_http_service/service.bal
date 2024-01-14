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

import ballerina/http;
import ballerina/graphql;
import ballerina/lang.runtime;

service /greeting on new http:Listener(9090) {
    resource function get greeting() returns string {
        return "Hello, World!";
    }
}

service / on new graphql:Listener(9091) {
    resource function get greeting() returns string {
        return "Hello from global listener binding service";
    }
}

service /greeting on new http:Listener(9092) {
    resource function get greeting() returns string {
        return "Hello, World!";
    }
}

graphql:Service globalService = service object {
    resource function get greeting() returns string {
        return "Hello from global service";
    }
};

service /too on new graphql:Listener(9093) {
    resource function get greeting() returns string {
        return "Hello from global listener binding service too";
    }
}

class TestService {
    private graphql:Service fieldService = service object {
        resource function get greeting() returns string {
            return "Hello from object field service object";
        }
    };

    public function init() {}

    public function startService() returns error? {
        graphql:Listener localListener = check new(9094);
        check localListener.attach(self.fieldService);
        check localListener.'start();
        runtime:registerListener(localListener);
    }
}

public function main() returns error? {
    graphql:Service localService = service object {
        resource function get greeting() returns string {
            return "Hello from local service 2";
        }
    };

    TestService serviceClass = new ();
    check serviceClass.startService();

    graphql:Listener localListener = check new(9095);
    graphql:Listener globalListener = check new(9096);
    check localListener.attach(localService);
    check globalListener.attach(globalService);
    check localListener.'start();
    check globalListener.'start();
    runtime:registerListener(localListener);
    runtime:registerListener(globalListener);
}
