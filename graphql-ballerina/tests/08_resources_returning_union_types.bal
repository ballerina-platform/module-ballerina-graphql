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

type Information Address|Person;

type Details record {
    Information information;
};

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

    resource function get details(int id) returns Details {
        if (id < 5) {
            return { information: p1 };
        } else {
            return { information: a1 };
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
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["union", "unit"]
}
isolated function testQueryUnionTypeWithIncorrectFragment() returns error? {
    string graphqlUrl = "http://localhost:9098/graphql";
    string document = string`query {
    information(id: 3) {
        ...invalidFragment
        ...personFragment
    }
}

fragment invalidFragment on Student {
    name
}

fragment personFragment on Person {
    name
}
`;
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Fragment "invalidFragment" cannot be spread here as objects of type "Information" can never be of type "Student".`,
                locations: [
                    {
                        line: 3,
                        column: 12
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
isolated function testQueryUnionTypeWithFieldAndFragment() returns error? {
    string graphqlUrl = "http://localhost:9098/graphql";
    string document = string`query {
    information(id: 3) {
        name
        ...personFragment
    }
}

fragment personFragment on Person {
    name
}
`;
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Cannot query field "name" on type "Information". Did you mean to use a fragment on "Address" or "Person"?`,
                locations: [
                    {
                        line: 3,
                        column: 9
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
isolated function testQueryUnionTypeWithFragmentAndField() returns error? {
    string graphqlUrl = "http://localhost:9098/graphql";
    string document = string`query {
    information(id: 3) {
        ...personFragment
        name
    }
}

fragment personFragment on Person {
    name
}
`;
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Cannot query field "name" on type "Information". Did you mean to use a fragment on "Address" or "Person"?`,
                locations: [
                    {
                        line: 4,
                        column: 9
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
isolated function testQueryUnionTypeWithoutSelection() returns error? {
    string graphqlUrl = "http://localhost:9098/graphql";
    string document = "{ information(id: 2) }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    string message = string`Field "information" of type "Information!" must have a selection of subfields. Did you mean "information { ... }"?`;
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

@test:Config {
    groups: ["union", "unit"]
}
isolated function testUnionTypeAsRecordFieldWithoutFragment() returns error? {
    string graphqlUrl = "http://localhost:9098/graphql";
    string document = string`
query {
    details(id: 3) {
        information {
            name
        }
    }
}
`;
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Cannot query field "name" on type "Information". Did you mean to use a fragment on "Address" or "Person"?`,
                locations: [
                    {
                        line: 5,
                        column: 13
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
isolated function testUnionTypeAsRecordField() returns error? {
    string graphqlUrl = "http://localhost:9098/graphql";
    string document = string`
query {
    details(id: 10) {
        information {
            ...addressFragment
            ...personFragment
        }
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
            details: {
                information: {
                    city: "London"
                }
            }
        }
    };
    test:assertEquals(result, expectedPayload);
}
