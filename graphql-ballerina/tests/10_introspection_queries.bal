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

@test:Config {
    groups: ["introspection", "unit"]
}
isolated function testSimpleIntrospectionQuery() returns error? {
    string graphqlUrl = "http://localhost:9101/graphql";
    string document = "{ __schema { types { name kind } } }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedResult = {
        data: {
            __schema: {
                types: [
                    {
                        name: "__TypeKind",
                        kind: "ENUM"
                    },
                    {
                        name: "__Field",
                        kind: "OBJECT"
                    },
                    {
                        name: "Query",
                        kind: "OBJECT"
                    },
                    {
                        name: "__Type",
                        kind: "OBJECT"
                    },
                    {
                        name: "String",
                        kind: "SCALAR"
                    },
                    {
                        name: "__InputValue",
                        kind: "OBJECT"
                    },
                    {
                        name: "__Schema",
                        kind: "OBJECT"
                    }
                ]
            }
        }
    };
    test:assertEquals(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection", "unit"]
}
isolated function testComplexIntrospectionQuery() returns error? {
    // Using 9100 endpoint since it has more complex schema
    string graphqlUrl = "http://localhost:9100/graphql";
    string document = "{ __schema { types { name kind } } }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedResult = {
        data: {
            __schema: {
                types: [
                    {
                        name: "__TypeKind",
                        kind: "ENUM"
                    },
                    {
                        name: "__Field",
                        kind: "OBJECT"
                    },
                    {
                        name: "Query",
                        kind: "OBJECT"
                    },
                    {
                        name: "Address",
                        kind: "OBJECT"
                    },
                    {
                        name: "__Type",
                        kind: "OBJECT"
                    },
                    {
                        name: "Book",
                        kind: "OBJECT"
                    },
                    {
                        name: "String",
                        kind: "SCALAR"
                    },
                    {
                        name: "__InputValue",
                        kind: "OBJECT"
                    },
                    {
                        name: "Course",
                        kind: "OBJECT"
                    },
                    {
                        name: "Student",
                        kind: "OBJECT"
                    },
                    {
                        name: "Person",
                        kind: "OBJECT"
                    },
                    {
                        name: "Int",
                        kind: "SCALAR"
                    },
                    {
                        name: "__Schema",
                        kind: "OBJECT"
                    }
                ]
            }
        }
    };
    test:assertEquals(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection", "unit"]
}
isolated function testInvalidIntrospectionQuery() returns error? {
    string graphqlUrl = "http://localhost:9101/graphql";
    string document = "{ __schema { greet } }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    string expectedMessage = "Cannot query field \"greet\" on type \"__Schema\".";
    json expectedResult = {
        errors: [
            {
                message: expectedMessage,
                locations: [
                    {
                        line: 1,
                        column: 14
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection", "unit"]
}
isolated function testIntrospectionQueryWithMissingSelection() returns error? {
    string graphqlUrl = "http://localhost:9101/graphql";
    string document = "{ __schema }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    string expectedMessage = "Field \"__schema\" of type \"__Schema\" must have a selection of subfields." +
                             " Did you mean \"__schema { ... }\"?";
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

@test:Config {
    groups: ["introspection", "unit"]
}
isolated function testQueryTypeIntrospection() returns error? {
    string graphqlUrl ="http://localhost:9101/graphql";
    string document = "{ __schema { queryType { kind fields { name } } } }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedResult = {
        data: {
            __schema: {
                queryType: {
                    kind: "OBJECT",
                    fields: [
                        {
                            name: "greet"
                        }
                    ]
                }
            }
        }
    };
    test:assertEquals(actualResult, expectedResult);
}

service /graphql on new Listener(9101) {
    isolated resource function get greet() returns string {
        return "Hello";
    }
}
