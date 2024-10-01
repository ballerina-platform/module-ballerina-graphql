// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/graphql;
import ballerina/graphql_test_common as common;
import ballerina/test;

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithJson() returns error? {
    string url = "http://localhost:9090/inputs";
    string document = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->executeWithType(document, variables);
    json expectedPayload = {
        "data": {
            "greet": "Hello, Roland"
        }
    };
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithOpenRecord() returns error? {
    string url = "http://localhost:9090/inputs";
    string document = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    graphql:Client graphqlClient = check new (url);
    record {} actualPayload = check graphqlClient->executeWithType(document, variables);
    record {} expectedPayload = {
        "data": {
            "greet": "Hello, Roland"
        }
    };
    common:assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithKnownRecord() returns error? {
    string url = "http://localhost:9090/inputs";
    string document = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    graphql:Client graphqlClient = check new (url);
    GreetingResponse actualPayload = check graphqlClient->executeWithType(document, variables);
    GreetingResponse expectedPayload = {
        data: {
            greet: "Hello, Roland"
        }
    };
    common:assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithGenericRecord() returns error? {
    string url = "http://localhost:9090/inputs";
    string document = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    graphql:Client graphqlClient = check new (url);
    GenericGreetingResponse actualPayload = check graphqlClient->executeWithType(document, variables);
    GenericGreetingResponse expectedPayload = {
        data: {
            greet: "Hello, Roland"
        }
    };
    common:assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithJson() returns error? {
    string url = "http://localhost:9090/inputs";
    string document = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->execute(document, variables);
    json expectedPayload = {
        "data": {
            "greet": "Hello, Roland"
        }
    };
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithOpenRecord() returns error? {
    string url = "http://localhost:9090/inputs";
    string document = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    graphql:Client graphqlClient = check new (url);
    record {} actualPayload = check graphqlClient->execute(document, variables);
    record {} expectedPayload = {
        "data": {
            "greet": "Hello, Roland"
        }
    };
    common:assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithKnownRecord() returns error? {
    string url = "http://localhost:9090/inputs";
    string document = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    graphql:Client graphqlClient = check new (url);
    GreetingResponseWithErrors actualPayload = check graphqlClient->execute(document, variables);
    GreetingResponseWithErrors expectedPayload = {
        data: {
            greet: "Hello, Roland"
        }
    };
    common:assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithGenericRecord() returns error? {
    string url = "http://localhost:9090/inputs";
    string document = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    graphql:Client graphqlClient = check new (url);
    GenericGreetingResponseWithErrors actualPayload = check graphqlClient->execute(document, variables);
    GenericGreetingResponseWithErrors expectedPayload = {
        data: {
            greet: "Hello, Roland"
        }
    };
    common:assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithInvalidRequest() returns error? {
    string url = "http://localhost:9090/inputs";
    string document = string `query Greeting ($userName:String!){ gree (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    graphql:Client graphqlClient = check new (url);
    json|graphql:ClientError payload = graphqlClient->executeWithType(document, variables);
    test:assertTrue(payload is graphql:InvalidDocumentError);
    graphql:InvalidDocumentError err = <graphql:InvalidDocumentError>payload;
    graphql:ErrorDetail[]? actualErrorDetails = err.detail().errors;
    graphql:ErrorDetail[] expectedErrorDetails = [
        {
            message: "Cannot query field \"gree\" on type \"Query\".",
            locations: [{"line": 1, "column": 37}]
        }
    ];
    test:assertEquals(actualErrorDetails, expectedErrorDetails);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithInvalidRequest() returns error? {
    string url = "http://localhost:9090/inputs";
    string document = string `query Greeting ($userName:String!){ gree (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    graphql:Client graphqlClient = check new (url);
    json|graphql:ClientError payload = graphqlClient->execute(document, variables);
    test:assertTrue(payload is graphql:InvalidDocumentError);
    graphql:InvalidDocumentError err = <graphql:InvalidDocumentError>payload;
    graphql:ErrorDetail[]? actualErrorDetails = err.detail().errors;
    graphql:ErrorDetail[] expectedErrorDetails = [
        {
            message: "Cannot query field \"gree\" on type \"Query\".",
            locations: [{"line": 1, "column": 37}]
        }
    ];
    test:assertEquals(actualErrorDetails, expectedErrorDetails);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithInvalidBindingType() returns error? {
    string url = "http://localhost:9090/inputs";
    string document = string `query Greeting ($userName:String!){ greet (name: $userName) }`;
    string userName = "Roland";
    map<anydata> variables = {"userName": userName};

    graphql:Client graphqlClient = check new (url);
    string|graphql:ClientError payload = graphqlClient->executeWithType(document, variables);
    test:assertTrue(payload is graphql:RequestError);
    graphql:RequestError actualPayload = <graphql:RequestError>payload;
    test:assertEquals(actualPayload.message(), "GraphQL Client Error");
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithPartialDataRequest() returns error? {
    string url = "http://localhost:9090/special_types";
    string document = string `query { specialHolidays }`;

    graphql:Client graphqlClient = check new (url);
    json|graphql:ClientError payload = graphqlClient->executeWithType(document);
    test:assertTrue(payload is graphql:ServerError);
    graphql:ServerError err = <graphql:ServerError>payload;
    json actualPayload = err.detail().toJson();
    json expectedPayload = {
        data: {
            specialHolidays: ["TUESDAY", null, "THURSDAY"]
        },
        errors: [
            {
                message: "Holiday!",
                locations: [
                    {
                        line: 1,
                        column: 9
                    }
                ],
                path: ["specialHolidays", 1]
            }
        ],
        extensions: null
    };
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithPartialDataRequest() returns error? {
    string url = "http://localhost:9090/special_types";
    string document = string `query { specialHolidays }`;

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->execute(document);
    json expectedPayload = {
        errors: [
            {
                message: "Holiday!",
                locations: [
                    {
                        line: 1,
                        column: 9
                    }
                ],
                path: ["specialHolidays", 1]
            }
        ],
        data: {
            specialHolidays: ["TUESDAY", null, "THURSDAY"]
        }
    };
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithMultipleOperationsWithoutOperationNameInRequest() returns error? {
    string url = "http://localhost:9090/records";
    string document = check common:getGraphqlDocumentFromFile("multiple_operations_without_operation_name_in_request");

    graphql:Client graphqlClient = check new (url);
    json|graphql:ClientError payload = graphqlClient->executeWithType(document);
    test:assertTrue(payload is graphql:InvalidDocumentError);
    graphql:InvalidDocumentError err = <graphql:InvalidDocumentError>payload;
    graphql:ErrorDetail[]? actualErrorDetails = err.detail().errors;
    graphql:ErrorDetail[] expectedErrorDetails = [
        {
            message: "Must provide operation name if query contains multiple operations.",
            locations: []
        }
    ];
    test:assertEquals(actualErrorDetails, expectedErrorDetails);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithMultipleOperationsWithoutOperationNameInRequest() returns error? {
    string url = "http://localhost:9090/records";
    string document = check common:getGraphqlDocumentFromFile("multiple_operations_without_operation_name_in_request");

    graphql:Client graphqlClient = check new (url);
    json|graphql:ClientError payload = graphqlClient->execute(document);
    test:assertTrue(payload is graphql:InvalidDocumentError);
    graphql:InvalidDocumentError err = <graphql:InvalidDocumentError>payload;
    graphql:ErrorDetail[]? actualErrorDetails = err.detail().errors;
    graphql:ErrorDetail[] expectedErrorDetails = [
        {
            message: "Must provide operation name if query contains multiple operations.",
            locations: []
        }
    ];
    test:assertEquals(actualErrorDetails, expectedErrorDetails);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithMultipleOperationsWithOperationNameInRequest() returns error? {
    string url = "http://localhost:9090/records";
    string document = check common:getGraphqlDocumentFromFile("multiple_operations_without_operation_name_in_request");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->executeWithType(document, operationName = "getDetective");
    json expectedPayload = {"data": {"detective": {"name": "Sherlock Holmes"}}};
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithMultipleOperationsWithOperationNameInRequest() returns error? {
    string url = "http://localhost:9090/records";
    string document = check common:getGraphqlDocumentFromFile("multiple_operations_without_operation_name_in_request");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->execute(document, operationName = "getDetective");
    json expectedPayload = {"data": {"detective": {"name": "Sherlock Holmes"}}};
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithMutation() returns error? {
    string url = "http://localhost:9090/mutations";
    string document = string `mutation { setName(name: "Heisenberg") { name } }`;

    graphql:Client graphqlClient = check new (url);
    SetNameResponse actualPayload = check graphqlClient->executeWithType(document);
    SetNameResponse expectedPayload = {
        data: {
            setName: {
                name: "Heisenberg"
            }
        }
    };
    common:assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithMutation() returns error? {
    string url = "http://localhost:9090/mutations";
    string document = string `mutation { setName(name: "Heisenberg") { name } }`;

    graphql:Client graphqlClient = check new (url);
    SetNameResponseWithErrors actualPayload = check graphqlClient->execute(document);
    SetNameResponseWithErrors expectedPayload = {
        data: {
            setName: {
                name: "Heisenberg"
            }
        }
    };
    common:assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithAlias() returns error? {
    string url = "http://localhost:9090/profiles";
    string document = check common:getGraphqlDocumentFromFile("alias");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = {
        data: {
            sherlock: {
                name: {
                    first: "Sherlock"
                },
                address: {
                    city: "London"
                }
            }
        }
    };
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithAlias() returns error? {
    string url = "http://localhost:9090/profiles";
    string document = check common:getGraphqlDocumentFromFile("alias");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->execute(document);
    json expectedPayload = {
        data: {
            sherlock: {
                name: {
                    first: "Sherlock"
                },
                address: {
                    city: "London"
                }
            }
        }
    };
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithEnum() returns error? {
    string url = "http://localhost:9090/special_types";
    string document = "query { time { weekday } }";

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = {
        data: {
            time: {
                weekday: "MONDAY"
            }
        }
    };
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithEnum() returns error? {
    string url = "http://localhost:9090/special_types";
    string document = "query { time { weekday } }";

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->execute(document);
    json expectedPayload = {
        data: {
            time: {
                weekday: "MONDAY"
            }
        }
    };
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithFragmentsOnRecordObjects() returns error? {
    string url = "http://localhost:9090/records";
    string document = check common:getGraphqlDocumentFromFile("fragments_on_record_objects");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = check common:getJsonContentFromFile("fragments_on_record_objects");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithFragmentsOnRecordObjects() returns error? {
    string url = "http://localhost:9090/records";
    string document = check common:getGraphqlDocumentFromFile("fragments_on_record_objects");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->execute(document);
    json expectedPayload = check common:getJsonContentFromFile("fragments_on_record_objects");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithNestedFragments() returns error? {
    string url = "http://localhost:9090/records";
    string document = check common:getGraphqlDocumentFromFile("nested_fragments");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = check common:getJsonContentFromFile("nested_fragments");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithNestedFragments() returns error? {
    string url = "http://localhost:9090/records";
    string document = check common:getGraphqlDocumentFromFile("nested_fragments");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->execute(document);
    json expectedPayload = check common:getJsonContentFromFile("nested_fragments");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithInlineFragment() returns error? {
    string url = "http://localhost:9090/records";
    string document = check common:getGraphqlDocumentFromFile("inline_fragment");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = check common:getJsonContentFromFile("inline_fragment");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithInlineFragment() returns error? {
    string url = "http://localhost:9090/records";
    string document = check common:getGraphqlDocumentFromFile("inline_fragment");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->execute(document);
    json expectedPayload = check common:getJsonContentFromFile("inline_fragment");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithBallerinaRecordAsGraphqlObject() returns error? {
    string url = "http://localhost:9090/records";
    string document = "query getPerson { detective { name, address { street } } }";

    graphql:Client graphqlClient = check new (url);
    PersonResponse actualPayload = check graphqlClient->executeWithType(document);
    PersonResponse expectedPayload = {
        data: {
            detective: {
                name: "Sherlock Holmes",
                address: {
                    street: "Baker Street"
                }
            }
        }
    };
    common:assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithBallerinaRecordAsGraphqlObject() returns error? {
    string url = "http://localhost:9090/records";
    string document = "query getPerson { detective { name, address { street } } }";

    graphql:Client graphqlClient = check new (url);
    PersonResponseWithErrors actualPayload = check graphqlClient->execute(document);
    PersonResponseWithErrors expectedPayload = {
        data: {
            detective: {
                name: "Sherlock Holmes",
                address: {
                    street: "Baker Street"
                }
            }
        }
    };
    common:assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithRecordTypeArrays() returns error? {
    string document = "{ people { name address { city } } }";
    string url = "http://localhost:9090/records";

    graphql:Client graphqlClient = check new (url);
    PeopleResponse actualPayload = check graphqlClient->executeWithType(document);
    PeopleResponse expectedPayload = {
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
    common:assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithRecordTypeArrays() returns error? {
    string document = "{ people { name address { city } } }";
    string url = "http://localhost:9090/records";

    graphql:Client graphqlClient = check new (url);
    PeopleResponseWithErrors actualPayload = check graphqlClient->executeWithType(document);
    PeopleResponseWithErrors expectedPayload = {
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
    common:assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteForDataBindingError() returns error? {
    string document = "{ one: profile(id: 100) {name} }";
    string url = "http://localhost:9090/records";

    graphql:Client graphqlClient = check new (url);
    ProfileResponseWithErrors|graphql:ClientError payload = graphqlClient->execute(document);
    test:assertTrue(payload is graphql:PayloadBindingError, "This should be a payload binding error");
    graphql:PayloadBindingError err = <graphql:PayloadBindingError>payload;
    graphql:ErrorDetail[] expectedErrorDetails = [
        {
            message: "{ballerina/lang.array}IndexOutOfRange",
            locations: [{line: 1, column: 3}],
            path: ["one"]
        }
    ];

    graphql:ErrorDetail[]? actualErrorDetails = err.detail().errors;
    test:assertEquals(actualErrorDetails, expectedErrorDetails);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientDataBindingErrorHavingACause() returns error? {
    string url = "http://localhost:9090/special_types";
    string document = string `query { specialHolidays }`;

    graphql:Client graphqlClient = check new (url);
    ProfileResponseWithErrors|graphql:ClientError payload = graphqlClient->execute(document);
    test:assertTrue(payload is graphql:PayloadBindingError, "This should be a payload binding error");
    graphql:PayloadBindingError err = <graphql:PayloadBindingError>payload;
    graphql:ErrorDetail[] expectedErrorDetails = [
        {
            message: "Holiday!",
            locations: [{line: 1, column: 9}],
            path: ["specialHolidays", 1]
        }
    ];

    graphql:ErrorDetail[]? actualErrorDetails = err.detail().errors;
    test:assertEquals(actualErrorDetails, expectedErrorDetails);
    test:assertTrue(err.cause() !is (), "PayloadBindingError should have a cause");
}
