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
import ballerina/http;
import ballerina/url;

service /graphql on new Listener(9095) {
    resource function get profile(int id) returns Person {
        return people[id];
    }
}

@test:Config {
    groups: ["negative", "listener"]
}
isolated function testMissingArgumentValueQuery() returns error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ profile(id: ) { name age }";
    json actualPayload = check getJsonPayloadFromBadRequest(graphqlUrl, document);

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
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener"]
}
isolated function testEmptyQuery() returns error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ }";
    json actualPayload = check getJsonPayloadFromBadRequest(graphqlUrl, document);

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
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener"]
}
isolated function testObjectWithNoSelectionQuery() returns error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ profile(id: 4) }";
    json actualPayload = check getJsonPayloadFromBadRequest(graphqlUrl, document);

    string expectedMessage = "Field \"profile\" of type \"Person!\" must have a selection of subfields." +
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
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener"]
}
isolated function testObjectWithNoSelectionQueryWithArguments() returns error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ profile(id: 4) }";
    json actualPayload = check getJsonPayloadFromBadRequest(graphqlUrl, document);

    string expectedMessage = "Field \"profile\" of type \"Person!\" must have a selection of subfields." +
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
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener"]
}
isolated function testObjectWithInvalidSelectionQuery() returns error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ profile(id: 4) { status } }";
    json actualPayload = check getJsonPayloadFromBadRequest(graphqlUrl, document);

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
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener"]
}
isolated function testObjectWithMissingRequiredArgument() returns error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ profile { status } }";
    json actualPayload = check getJsonPayloadFromBadRequest(graphqlUrl, document);

    string expectedMessage1 =
        "Field \"profile\" argument \"id\" of type \"Int!\" is required, but it was not provided.";
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
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener"]
}
isolated function testRequestSubtypeFromPrimitiveType() returns error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ profile (id: 2) { age { name } } }";
    json actualPayload = check getJsonPayloadFromBadRequest(graphqlUrl, document);

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
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener"]
}
isolated function testInvalidArgument() returns error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ profile (name: \"name\", id: 3) { name } }";
    json actualPayload = check getJsonPayloadFromBadRequest(graphqlUrl, document);

    string expectedMessage = "Unknown argument \"name\" on field \"Query.profile\".";
    json expectedPayload = {
        errors: [
            {
                message: expectedMessage,
                locations: [
                    {
                        line: 1,
                        column: 12
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener"]
}
isolated function testRuntimeError() returns error? {
    string graphqlUrl = "http://localhost:9095/graphql";
    string document = "{ profile (id: 10) { name } }";
    http:Client httpClient = check new(graphqlUrl);
    http:Response response = check httpClient->post("/", { query: document });
    test:assertEquals(response.statusCode, 200);
    json actualPayload = check response.getJsonPayload();

    string expectedMessage = "{ballerina/lang.array}IndexOutOfRange";
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
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["negative", "listener"]
}
isolated function testRuntimeErrorWithGetRequest() returns error? {
    string graphqlUrl = "http://localhost:9095";
    string document = "{ profile (id: 10) { name } }";
    string encodedDocument = check url:encode(document, "UTF-8");
    http:Client httpClient = check new(graphqlUrl);
    string path = "/graphql?query=" + encodedDocument;
    http:Response response = check httpClient->get(path);
    test:assertEquals(response.statusCode, 200);
    json actualPayload = check response.getJsonPayload();

    string expectedMessage = "{ballerina/lang.array}IndexOutOfRange";
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
    test:assertEquals(actualPayload, expectedPayload);
}
