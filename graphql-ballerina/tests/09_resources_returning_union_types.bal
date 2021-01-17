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

@test:Config {
    groups: ["service", "unit"]
}
public function testResourcesReturningInvalidUnionType() returns error? {
    Listener graphqlListener = check new (9099);
    var result = trap graphqlListener.attach(serviceWithInvalidUnionTypes);
    test:assertTrue(result is error);
    error err = <error> result;
    string expectedErrorMessage = "Unsupported union: Ballerina GraphQL does not allow unions other that <T>|error";
    test:assertEquals(err.message(), expectedErrorMessage);
}

Service serviceWithInvalidUnionTypes = service object {
    isolated resource function get name() returns int|string {
        return "John Doe";
    }
};

service /graphql on new Listener(9098) {
    resource function get profile(int id) returns Person|error {
        if (id < people.length()) {
            return people[id];
        } else {
            return error("Invalid ID provided");
        }
    }
}

@test:Config {
    groups: ["service", "unit"]
}
public function testResourceReturningUnionTypes() returns @tainted error? {
    Client graphqlClient = check new("http://localhost:9098/graphql");
    string document = "{ profile (id: 5) { name } }";

    json expectedPayload = {
        errors: [
            {
                message: "Invalid ID provided",
                locations: [
                    {
                        line: 1,
                        column: 3
                    }
                ]
            }
        ]
    };
    json result = check graphqlClient->query(document);
    test:assertEquals(result, expectedPayload);
}

