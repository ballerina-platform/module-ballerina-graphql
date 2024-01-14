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

class TestService {
    private graphql:Service fieldService1 = service object {
        resource function get greeting() returns string {
            return "Hello from object field service object 1";
        }
    };
    private graphql:Service fieldService2 = service object {
        resource function get greeting() returns string {
            return "Hello from object field service object 2";
        }
    };

    public function init() {}

    public function startService() returns error? {
        graphql:Listener localListener1 = check new(9090);
        graphql:Listener localListener2 = check new(9091);
        check localListener1.attach(self.fieldService1);
        check localListener2.attach(self.fieldService2);
        check localListener1.'start();
        check localListener2.'start();
        runtime:registerListener(localListener1);
        runtime:registerListener(localListener2);
    }
}

public function main() returns error? {
    TestService serviceClass = new ();
    check serviceClass.startService();
}