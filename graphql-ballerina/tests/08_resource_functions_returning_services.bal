// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/test;

service /graphql on new Listener(9097) {
    isolated resource function get greet() returns service object {} {
        return service object {
            isolated resource function get generalGreeting() returns string {
                return "Hello, world";
            }
        };
    }
}

@test:Config {
    groups: ["service", "unit"]
}
public function testResourceReturningServiceObject() returns @tainted error? {
    Client graphqlClient = new("http://localhost:9097/graphql");
    string document = "{ greet { generalGreeting } }";

    json expectedPayload = {
        data: {
            greet: {
                generalGreeting: "Hello, world"
            }
        }
    };
    json result = check graphqlClient->query(document);
    test:assertEquals(result, expectedPayload);
}
