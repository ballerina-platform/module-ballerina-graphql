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
import ballerina/io;

type Information Address|Person;

service /graphql on new Listener(9098) {
    resource function get profile(int id) returns Person|error? {
        if (id < people.length()) {
            return people[id];
        } else if (id < 5) {
            return;
        } else {
            return error("Invalid ID provided");
        }
    }

    resource function get information(int id) returns Information {
        if (id < 5) {
            return p1;
        } else {
            return a1;
        }
    }
}

@test:Config {
    groups: ["union", "unit"]
}
isolated function testResourceReturningUnionTypes() returns error? {
    string graphqlUrl = "http://localhost:9098/graphql";
    string document = "{ profile (id: 5) { name } }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

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
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["union", "unit"]
}
isolated function testResourceReturningUnionWithNull() returns error? {
    string graphqlUrl = "http://localhost:9098/graphql";
    string document = "{ profile (id: 4) { name } }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

    json expectedPayload = {
        data: {
            profile: null
        }
    };
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["union", "unit"]
}
isolated function testQueryUnionType() returns error? {
    string graphqlUrl = "http://localhost:9098/graphql";
    string document = string`
query {
    information(id: 3) {
        ...addressFragment
        ...personFragment
    }
}

fragment addressFragment on Address {
    city
}

fragment personFragment on Person {
    name
}
`;
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = {
        data: {
            information: {
                name: "Sherlock Holmes"
            }
        }
    };
    io:println(result);
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["union", "unit"]
}
isolated function testQueryUnionTypeWithoutSelection() returns error? {
    string graphqlUrl = "http://localhost:9098/graphql";
    string document = "{ information(id: 2) }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    string message = string`Field "information" of type "Information" must have a selection of subfields. Did you mean "information { ... }"?`;
    json expectedPayload = {
        errors: [
            {
                message: message,
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
    groups: ["union", "unit"]
}
isolated function testQueryUnionTypeWithSelection() returns error? {
    string graphqlUrl = "http://localhost:9098/graphql";
    string document = "{ information(id: 2) { name } }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    string message = string`Cannot query field "name" on type "Information". Did you mean to use a fragment on "Address" or "Person"?`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 1,
                        column: 24
                    }
                ]
            }
        ]
    };
    test:assertEquals(result, expectedPayload);
}
