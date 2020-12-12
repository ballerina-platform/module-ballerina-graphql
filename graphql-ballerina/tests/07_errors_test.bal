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

service /graphql on new Listener(port = 9096) {
    resource function get profile(int id) returns Person {
        return people[id];
    }
}

@test:Config {
    groups: ["client", "unit"]
}
public function testInvalidQuery() returns @tainted error? {
    Client graphqlClient = new("http://localhost:9096/graphql");
    string document = "{ profile(id: ) { name age }";

    json expectedPayload = {
        errors: [
            {
                message:"Syntax Error: Unexpected \")\".",
                locations:[
                    {
                        line:1,
                        column:15
                    }
                ]
            }
        ]
    };
    json result = check graphqlClient->query(document);
    test:assertEquals(result, expectedPayload);
}

