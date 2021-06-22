// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

listener Listener fragmentsTestListener = new(9106);

service /graphql on fragmentsTestListener {
    resource function get people() returns Person[] {
        return people;
    }

    resource function get students() returns Student[] {
        return students;
    }

    isolated resource function get profile() returns Profile {
        return new;
    }

    resource function get teacher() returns Person {
        return p2;
    }

    resource function get student() returns Person {
        return p4;
    }
}

service /fragments on fragmentsTestListener {
    resource function get teacher() returns TeacherService {
        return new TeacherService(737, "Walter White", "Chemistry");
    }
}

@test:Config {
    groups: ["fragments"]
}
isolated function testUnknownFragment() returns error? {
    string document = string
`query {
    ...friend
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);

    string message = string`Unknown fragment "friend".`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 2,
                        column: 8
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments"]
}
isolated function testUnknownNestedFragments() returns error? {
    string document = string
`query {
    ...data
}

fragment data on Query {
    students {
        ...details
    }
}

fragment details on Student {
    courses {
        name
        ...fail
    }
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);

    string message = string`Unknown fragment "fail".`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 14,
                        column: 12
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments"]
}
isolated function testFragmentOnInvalidType() returns error? {
    string document = string
`query {
    ...data
}

fragment data on Person {
    name
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);

    string message = string`Fragment "data" cannot be spread here as objects of type "Query" can never be of type "Person".`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 2,
                        column: 5
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments"]
}
isolated function testFragmentWithInvalidField() returns error? {
    string document = string
`query {
    ...data
}

fragment data on Query {
    people {
        invalid
    }
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);

    string message = string`Cannot query field "invalid" on type "Person".`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 7,
                        column: 9
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments"]
}
isolated function testFragments() returns error? {
    string document = string
`query {
    ...data
}

fragment data on Query {
    people {
        name
    }
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            people: [
                {
                    name: "Sherlock Holmes"
                },
                {
                    name: "Walter White"
                },
                {
                    name: "Tom Marvolo Riddle"
                }
            ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments"]
}
isolated function testNestedFragments() returns error? {
    string document = string
`query {
    ...data
}

fragment data on Query {
    people {
        ...address
    }
}

fragment address on Person {
    address {
        city
    }
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            people: [
                {
                    address: {
                        city: "London"
                    }
                },
                {
                    address: {
                        city: "Albuquerque"
                    }
                },
                {
                    address: {
                        city: "Hogwarts"
                    }
                }
            ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments"]
}
isolated function testFragmentsWithMultipleResourceInvocation() returns error? {
    string document = string
`query {
    ...data
}

fragment data on Query {
    people {
        ...people
    }

    students {
        ...student
    }
}

fragment people on Person {
    address {
        city
    }
}

fragment student on Student {
    name
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            people: [
                {
                    address: {
                        city: "London"
                    }
                },
                {
                    address: {
                        city: "Albuquerque"
                    }
                },
                {
                    address: {
                        city: "Hogwarts"
                    }
                }
            ],
            students: [
                {
                    name: "John Doe"
                },
                {
                    name: "Jane Doe"
                },
                {
                    name: "Jonny Doe"
                }
            ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "introspection"]
}
isolated function testFragmentsWithInvalidIntrospection() returns error? {
    string document = string
`query {
    ...data
}

fragment data on Query {
    ...schema
}

fragment schema on Query {
    __schema {
        ...types
    }
}

fragment types on __Schema {
    types {
        invalid
    }
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);

    json expectedPayload = {
        errors: [
            {
                message: string`Cannot query field "invalid" on type "__Type".`,
                locations: [
                    {
                        line: 17,
                        column: 9
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "introspection"]
}
isolated function testFragmentsWithIntrospection() returns error? {
    string document = string
`query {
    ...data
}

fragment data on Query {
    ...schema
}

fragment schema on Query {
    __schema {
        ...types
    }
}

fragment types on __Schema {
    types {
        name
    }
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = check getJsonContentFromFile("fragment_with_introspection.json");
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments"]
}
isolated function testFragmentsWithResourcesReturningServices() returns error? {
    string document = string
`query {
    ...greetingFragment
}

fragment greetingFragment on Query {
    profile {
        ...nameFragment
    }
}

fragment nameFragment on Profile {
    name {
        ...fullNameFragment
    }
}

fragment fullNameFragment on Name {
    first
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            profile: {
                name: {
                    first: "Sherlock"
                }
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments"]
}
isolated function testUnusedFragmentError() returns error? {
    string document = string
`query {
    people {
        name
    }
}

fragment fullNameFragment on Name {
    first
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);

    json expectedPayload = {
        errors: [
            {
                message: string`Fragment "fullNameFragment" is never used.`,
                locations: [
                    {
                        line: 7,
                        column: 1
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "inline"]
}
isolated function testInlineFragment() returns error? {
    string document = string
`query {
   ...on Query {
       people {
           ... on Person {
               address {
                   city
               }
           }
       }
   }

   ... on Query {
       students {
           name
       }
   }
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
             people: [
                 {
                     address: {
                         city: "London"
                     }
                 },
                 {
                     address: {
                         city: "Albuquerque"
                     }
                 },
                 {
                     address: {
                         city: "Hogwarts"
                     }
                 }
             ],
             students: [
                 {
                     name: "John Doe"
                 },
                 {
                     name: "Jane Doe"
                 },
                 {
                     name: "Jonny Doe"
                 }
             ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "inline"]
}
isolated function testUnknownInlineFragments() returns error? {
    string document = string
`query {
    ...on on {
        name
    }
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Unknown type "on".`,
                locations: [
                    {
                        "line": 2,
                        "column": 11
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "inline"]
}
isolated function testInvalidSpreadInlineFragments() returns error? {
    string document = string
`query {
    __schema {
        types {
            ...on Student {
                name
            }
            ...on Person {
                name
            }
        }
    }
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "Fragment cannot be spread here as objects of type \"__Type\" can never be of type \"Student\".",
                locations: [
                    {
                        "line": 4,
                        "column": 13
                    }
                ]
            },
            {
                message: "Fragment cannot be spread here as objects of type \"__Type\" can never be of type \"Person\".",
                locations: [
                    {
                        "line": 7,
                        "column": 13
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "inline"]
}
isolated function testInlineFragmentsOnSameTypeInDifferentPlaces() returns error? {
    string document = string
`query {
    teacher {
        ... on Person {
            name
        }
    }
    student {
        ... on Person {
            age
        }
    }
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            teacher: {
                name: "Walter White"
            },
            student: {
                age: 25
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments"]
}
isolated function testFragmentsInsideFragmentsWhenReturningServices() returns error? {
    string document = string
    `query {
        ... QueryFragment
    }

    fragment QueryFragment on Query {
        teacher {
            ...TeacherFragment
        }
    }

    fragment TeacherFragment on TeacherService {
        ...NameFragment
    }

    fragment NameFragment on TeacherService {
        name
    }`;
    string url = "http://localhost:9106/fragments";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            teacher: {
                name: "Walter White"
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments"]
}
isolated function testFragmentsInsideFragmentsWhenReturningServicesMultipleFields() returns error? {
    string document = string
    `query {
        ... QueryFragment
    }

    fragment QueryFragment on Query {
        teacher {
            ...TeacherFragment
        }
    }

    fragment TeacherFragment on TeacherService {
        ...NameFragment
    }

    fragment NameFragment on TeacherService {
        name,
        subject
    }`;
    string url = "http://localhost:9106/fragments";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            teacher: {
                name: "Walter White",
                subject: "Chemistry"
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}
