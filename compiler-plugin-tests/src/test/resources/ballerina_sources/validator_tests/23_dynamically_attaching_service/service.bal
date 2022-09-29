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

import ballerina/lang.runtime;
import ballerina/graphql;

# Graphql service definition
graphql:Service backendService = service object {
    resource function get greeting() returns string {
        return "Hello, World";
    }

    resource function get bye() returns string {
        return "Bye! See you soon.";
    }

    remote function hi() returns string {
        return "hi";
    }
};

public function main() returns error? {
    graphql:Listener serverEP = check new(4000);
    check serverEP.attach(backendService, "graphql");
    check serverEP.'start();
    runtime:registerListener(serverEP);
}

