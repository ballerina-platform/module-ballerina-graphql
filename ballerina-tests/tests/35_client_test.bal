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
import ballerina/test;

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithJson() returns error? {
    string url = "http://localhost:9091/inputs";
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
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithOpenRecord() returns error? {
    string url = "http://localhost:9091/inputs";
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
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithKnownRecord() returns error? {
    string url = "http://localhost:9091/inputs";
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
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithGenericRecord() returns error? {
    string url = "http://localhost:9091/inputs";
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
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithJson() returns error? {
    string url = "http://localhost:9091/inputs";
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
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithOpenRecord() returns error? {
    string url = "http://localhost:9091/inputs";
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
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithKnownRecord() returns error? {
    string url = "http://localhost:9091/inputs";
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
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithGenericRecord() returns error? {
    string url = "http://localhost:9091/inputs";
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
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithInvalidRequest() returns error? {
    string url = "http://localhost:9091/inputs";
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
    string url = "http://localhost:9091/inputs";
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
    string url = "http://localhost:9091/inputs";
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
    string url = "http://localhost:9095/special_types";
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
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithPartialDataRequest() returns error? {
    string url = "http://localhost:9095/special_types";
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
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithMultipleOperationsWithoutOperationNameInRequest() returns error? {
    string url = "http://localhost:9091/validation";
    string document = check getGraphQLDocumentFromFile("multiple_operations_without_operation_name_in_request.graphql");

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
    string url = "http://localhost:9091/validation";
    string document = check getGraphQLDocumentFromFile("multiple_operations_without_operation_name_in_request.graphql");

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
    string url = "http://localhost:9091/validation";
    string document = check getGraphQLDocumentFromFile("multiple_operations_without_operation_name_in_request.graphql");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->executeWithType(document, operationName = "getName");
    json expectedPayload = {"data": {"name": "James Moriarty"}};
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithMultipleOperationsWithOperationNameInRequest() returns error? {
    string url = "http://localhost:9091/validation";
    string document = check getGraphQLDocumentFromFile("multiple_operations_without_operation_name_in_request.graphql");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->execute(document, operationName = "getName");
    json expectedPayload = {"data": {"name": "James Moriarty"}};
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithMutation() returns error? {
    string url = "http://localhost:9091/mutations";
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
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithMutation() returns error? {
    string url = "http://localhost:9091/mutations";
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
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithAlias() returns error? {
    string url = "http://localhost:9091/duplicates";
    string document = check getGraphQLDocumentFromFile("alias.graphql");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = {
        data: {
            sherlock: {
                name: "Sherlock Holmes",
                address: {
                    city: "London"
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithAlias() returns error? {
    string url = "http://localhost:9091/duplicates";
    string document = check getGraphQLDocumentFromFile("alias.graphql");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->execute(document);
    json expectedPayload = {
        data: {
            sherlock: {
                name: "Sherlock Holmes",
                address: {
                    city: "London"
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithEnum() returns error? {
    string url = "http://localhost:9095/special_types";
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
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithEnum() returns error? {
    string url = "http://localhost:9095/special_types";
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
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithFragmentsOnRecordObjects() returns error? {
    string url = "http://localhost:9091/records";
    string document = check getGraphQLDocumentFromFile("fragments_on_record_objects.graphql");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = check getJsonContentFromFile("fragments_on_record_objects.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithFragmentsOnRecordObjects() returns error? {
    string url = "http://localhost:9091/records";
    string document = check getGraphQLDocumentFromFile("fragments_on_record_objects.graphql");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->execute(document);
    json expectedPayload = check getJsonContentFromFile("fragments_on_record_objects.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithNestedFragments() returns error? {
    string url = "http://localhost:9091/records";
    string document = check getGraphQLDocumentFromFile("nested_fragments.graphql");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = check getJsonContentFromFile("nested_fragments.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithNestedFragments() returns error? {
    string url = "http://localhost:9091/records";
    string document = check getGraphQLDocumentFromFile("nested_fragments.graphql");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->execute(document);
    json expectedPayload = check getJsonContentFromFile("nested_fragments.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithInlineFragment() returns error? {
    string url = "http://localhost:9091/records";
    string document = check getGraphQLDocumentFromFile("inline_fragment.graphql");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = check getJsonContentFromFile("inline_fragment.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithInlineFragment() returns error? {
    string url = "http://localhost:9091/records";
    string document = check getGraphQLDocumentFromFile("inline_fragment.graphql");

    graphql:Client graphqlClient = check new (url);
    json actualPayload = check graphqlClient->execute(document);
    json expectedPayload = check getJsonContentFromFile("inline_fragment.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithBallerinaRecordAsGraphqlObject() returns error? {
    string url = "http://localhost:9091/records";
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
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithBallerinaRecordAsGraphqlObject() returns error? {
    string url = "http://localhost:9091/records";
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
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithTypeWithRecordTypeArrays() returns error? {
    string document = "{ people { name address { city } } }";
    string url = "http://localhost:9091/records";

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
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteWithRecordTypeArrays() returns error? {
    string document = "{ people { name address { city } } }";
    string url = "http://localhost:9091/records";

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
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["client"]
}
isolated function testClientExecuteForDataBindingError() returns error? {
    string document = "{ one: profile(id: 100) {name} }";
    string url = "http://localhost:9091/records";

    graphql:Client graphqlClient = check new (url);
    ProfileResponseWithErrors|graphql:ClientError payload = graphqlClient->execute(document);
    test:assertTrue(payload is graphql:PayloadBindingError, "This should be a payload binding error");
    graphql:PayloadBindingError err = <graphql:PayloadBindingError>payload;
    graphql:ErrorDetail[] expectedErrorDetails = [
        {
            message: "{ballerina/lang.array}IndexOutOfRange",
            locations: [{line: 1, column: 3}],
            path: ["profile"]
        }
    ];

    graphql:ErrorDetail[]? actualErrorDetails = err.detail().errors;
    test:assertEquals(actualErrorDetails, expectedErrorDetails);
}

@test:Config {
    groups: ["client"]
}
isolated function testClientConfiguration() returns error? {
    string document = "{ greeting }";
    string url = "https://localhost:9096/basicAuth ";

    graphql:Client graphqlClient = check new (url,
        cache = {enabled: true, isShared: true},
        timeout = 1,
        http1Settings = {keepAlive: "NEVER"},
        secureSocket = {cert: {path: TRUSTSTORE_PATH, password: "ballerina"}},
        auth = {username: "alice", password: "xxx"});

    json payload = check graphqlClient->execute(document);
    json expectedPayload = {data: {greeting: "Hello World!"}};
    test:assertEquals(payload, expectedPayload);
}

type ProfileResponseWithErrors record {|
    *graphql:GenericResponseWithErrors;
    ProfileResponse data;
|};

type ProfileResponse record {|
    ProfileData one;
|};

type ProfileData record {
    string name;
};

type GreetingResponse record {|
    map<json?> extensions?;
    record {|
        string greet;
    |} data;
|};

type GenericGreetingResponse record {|
    map<json?> extensions?;
    map<json?> data?;
|};

type GreetingResponseWithErrors record {|
    map<json?> extensions?;
    record {|
        string greet;
    |} data;
    graphql:ErrorDetail[] errors?;
|};

type GenericGreetingResponseWithErrors record {|
    map<json?> extensions?;
    map<json?> data?;
    graphql:ErrorDetail[] errors?;
|};

type SetNameResponse record {|
    map<json?> extensions?;
    record {|
        record {|
            string name;
        |} setName;
    |} data;
|};

type SetNameResponseWithErrors record {|
    map<json?> extensions?;
    record {|
        record {|
            string name;
        |} setName;
    |} data;
    graphql:ErrorDetail[] errors?;
|};

type PersonResponse record {|
    map<json?> extensions?;
    PersonDataResponse data;
|};

type PersonResponseWithErrors record {|
    map<json?> extensions?;
    PersonDataResponse data;
    graphql:ErrorDetail[] errors?;
|};

type PersonDataResponse record {|
    DetectiveResponse detective;
|};

type DetectiveResponse record {|
    string name;
    AddressResponse address;
|};

type AddressResponse record {|
    string street;
|};

type PeopleResponse record {|
    map<json?> extensions?;
    PeopleDataResponse data;
|};

type PeopleResponseWithErrors record {|
    map<json?> extensions?;
    PeopleDataResponse data;
    graphql:ErrorDetail[] errors?;
|};

type PeopleDataResponse record {|
    PersonInfoResponse[] people;
|};

type PersonInfoResponse record {|
    string name;
    AddressInfoResponse address;
|};

type AddressInfoResponse record {|
    string city;
|};
