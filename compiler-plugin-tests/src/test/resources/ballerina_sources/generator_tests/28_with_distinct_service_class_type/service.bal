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

public distinct service isolated class Person {
    private final string name;

    isolated function init(string name) {
        self.name = name;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

}

class TestService {
    private graphql:Service fieldService = service object {
        resource function get greeting() returns Person {
            return new Person("Rick");
        }
    };

    public function init() {}

    public function startService() returns error? {
        graphql:Listener localListener = check new(9090);
        check localListener.attach(self.fieldService);
        check localListener.'start();
        runtime:registerListener(localListener);
    }
}

public function main() returns error? {
    TestService serviceClass = new ();
    check serviceClass.startService();
}