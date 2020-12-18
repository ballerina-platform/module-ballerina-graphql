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

service /graphql on new Listener(9100) {
    resource function get people() returns Person[] {
        return people;
    }

    isolated resource function get ids() returns int[] {
        return [0, 1, 2];
    }
}

@test:Config {
    groups: ["test", "service", "unit"]
}
function testResourcesReturningScalarArrays() returns @tainted error? {
    Client graphqlClient = new("http://localhost:9100/graphql");
    string document = "{ ids }";
    json actualResult = check graphqlClient->query(document);
    json expectedResult = {
        data: {
            ids: [0, 1, 2]
        }
    };
    test:assertEquals(actualResult, expectedResult);
}

@test:Config {
    groups: ["test", "service", "unit"]
}
function testResourcesReturningArrays() returns @tainted error? {
    Client graphqlClient = new("http://localhost:9100/graphql");
    string document = "{ people { name address { city } } }";
    json actualResult = check graphqlClient->query(document);
    json expectedResult = {
        data: {
            people: [
                {
                    name: "Sherlock Holmes",
                    address: {
                        city: "London"
                    }
                },
                {
                    name: "Walter White",
                    address: {
                        city: "Albuquerque"
                    }
                },
                {
                    name: "Tom Marvolo Riddle",
                    address: {
                        city: "Hogwarts"
                    }
                }
            ]
        }
    };
    test:assertEquals(actualResult, expectedResult);
}

@test:Config {
    groups: ["service", "unit"]
}
function testResourcesReturningArraysMissingFields() returns @tainted error? {
    Client graphqlClient = new("http://localhost:9100/graphql");
    string document = "{ people }";
    json actualResult = check graphqlClient->query(document);
    string expectedMessage = "Field \"people\" of type \"[Person]\" must have a selection of subfields. Did you mean " +
                             "\"people { ... }\"?";
    json expectedResult = {
        errors: [
            {
                message: expectedMessage,
                locations: [
                    {
                        line: 1,
                        column: 3
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualResult, expectedResult);
}
