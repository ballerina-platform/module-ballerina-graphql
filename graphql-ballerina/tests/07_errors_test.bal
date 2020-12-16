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

service /graphql on new Listener(9096) {
    resource function get profile(int id) returns Person {
        return people[id];
    }
}

@test:Config {
    groups: ["negative", "listener", "unit"]
}
public function testMissingArgumentValueQuery() returns @tainted error? {
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

@test:Config {
    groups: ["negative", "listener", "unit"]
}
public function testEmptyQuery() returns @tainted error? {
    Client graphqlClient = new("http://localhost:9096/graphql");
    string document = "{ }";

    json expectedPayload = {
        errors: [
            {
                message: "Syntax Error: Expected Name, found \"}\".",
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

@test:Config {
    groups: ["negative", "listener", "unit"]
}
public function testObjectWithNoSelectionQuery() returns @tainted error? {
    Client graphqlClient = new("http://localhost:9096/graphql");
    string document = "{ profile(id: 4) }";

    string expectedMessage = "Field \"profile\" of type \"Person\" must have a selection of subfields." +
                             " Did you mean \"profile { ... }\"?";
    json expectedPayload = {
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
    json result = check graphqlClient->query(document);
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener", "unit"]
}
public function testObjectWithNoSelectionQueryWithArguments() returns @tainted error? {
    Client graphqlClient = new("http://localhost:9096/graphql");
    string document = "{ profile(id: 4) }";

    string expectedMessage = "Field \"profile\" of type \"Person\" must have a selection of subfields." +
                             " Did you mean \"profile { ... }\"?";
    json expectedPayload = {
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
    json result = check graphqlClient->query(document);
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener", "unit"]
}
public function testObjectWithInvalidSelectionQuery() returns @tainted error? {
    Client graphqlClient = new("http://localhost:9096/graphql");
    string document = "{ profile(id: 4) { status } }";

    string expectedMessage = "Cannot query field \"status\" on type \"Person\".";
    json expectedPayload = {
        errors: [
            {
                message: expectedMessage,
                locations: [
                    {
                        line: 1,
                        column: 20
                    }
                ]
            }
        ]
    };
    json result = check graphqlClient->query(document);
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener", "unit"]
}
public function testObjectWithMissingRequiredArgument() returns @tainted error? {
    Client graphqlClient = new("http://localhost:9096/graphql");
    string document = "{ profile { status } }";

    string expectedMessage1 = "Field \"profile\" argument \"id\" of type \"int\" is required, but it was not provided.";
    string expectedMessage2 = "Cannot query field \"status\" on type \"Person\".";
    json expectedPayload = {
        errors: [
            {
                message: expectedMessage1,
                locations: [
                    {
                        line: 1,
                        column: 3
                    }
                ]
            },
            {
                message: expectedMessage2,
                locations: [
                    {
                        line: 1,
                        column: 13
                    }
                ]
            }
        ]
    };
    json result = check graphqlClient->query(document);
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener", "unit"]
}
public function testRequestSubtypeFromPrimitiveType() returns @tainted error? {
    Client graphqlClient = new("http://localhost:9096/graphql");
    string document = "{ profile (id: 2) { age { name } } }";

    string expectedMessage = "Field \"age\" must not have a selection since type \"int\" has no subfields.";
    json expectedPayload = {
        errors: [
            {
                message: expectedMessage,
                locations: [
                    {
                        line: 1,
                        column: 27
                    }
                ]
            }
        ]
    };
    json result = check graphqlClient->query(document);
    test:assertEquals(result, expectedPayload);
}
