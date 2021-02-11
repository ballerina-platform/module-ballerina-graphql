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

service /graphql on new Listener(9095) {
    resource function get profile(int id) returns Person {
        return people[id];
    }
}

@test:Config {
    groups: ["negative", "listener", "unit"]
}
public function testMissingArgumentValueQuery() returns @tainted error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ profile(id: ) { name age }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

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
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener", "unit"]
}
public function testEmptyQuery() returns @tainted error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

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
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener", "unit"]
}
public function testObjectWithNoSelectionQuery() returns @tainted error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ profile(id: 4) }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

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
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener", "unit"]
}
public function testObjectWithNoSelectionQueryWithArguments() returns @tainted error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ profile(id: 4) }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

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
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener", "unit"]
}
public function testObjectWithInvalidSelectionQuery() returns @tainted error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ profile(id: 4) { status } }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

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
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener", "unit"]
}
public function testObjectWithMissingRequiredArgument() returns @tainted error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ profile { status } }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

    string expectedMessage1 = "Field \"profile\" argument \"id\" of type \"Int\" is required, but it was not provided.";
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
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener", "unit"]
}
public function testRequestSubtypeFromPrimitiveType() returns @tainted error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ profile (id: 2) { age { name } } }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

    string expectedMessage = "Field \"age\" must not have a selection since type \"Int\" has no subfields.";
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
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener", "unit"]
}
public function testInvalidArgument() returns @tainted error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ profile (name: \"name\", id: 3) { name } }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

    string expectedMessage = "Unknown argument \"name\" on field \"Query.profile\".";
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
    test:assertEquals(result, expectedPayload);
}
