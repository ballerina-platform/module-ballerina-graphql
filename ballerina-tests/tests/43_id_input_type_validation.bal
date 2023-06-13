// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
import ballerina/graphql;

const string URL = "http://localhost:9091/id_annotation_2";
final graphql:Client graphqlClient = check new (URL);

@test:Config {
    groups: ["id_validation"]
}
isolated function idInputTypeValidationTestForString() returns error? {
    string document = string `query { stringId(stringId: "hello") }`;
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = 
        {
            "data": {
                "stringId": "Hello, World"
            }
        };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["id_validation"]
}
isolated function idInputTypeValidationTestForInt() returns error? {
    string document = string `query { intId(intId: 56) }`;
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = 
        {
            "data": {
                "intId": "Hello, World"
            }
        };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["id_validation"]
}
isolated function idInputTypeValidationTestForFloat() returns error? {
    string document = string `query { floatId(floatId: "6.0") }`;
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = 
        {
            "data": {
                "floatId": "Hello, World"
            }
        };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["id_validation"]
}
isolated function idInputTypeValidationTestForDecimal() returns error? {
    string document = string `query { decimalId(decimalId: "45.0") }`;
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = 
        {
            "data": {
                "decimalId": "Hello, World"
            }
        };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}


@test:Config {
    groups: ["id_validation"]
}
isolated function idInputTypeValidationTestForStringOrNil() returns error? {
    string document = string `query { stringId1(stringId: "hello") }`;
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = 
        {
            "data": {
                "stringId1": "Hello, World"
            }
        };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["id_validation"]
}
isolated function idInputTypeValidationTestForIntOrNil() returns error? {
    string document = string `query { intId1(intId: 56) }`;
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = 
        {
            "data": {
                "intId1": "Hello, World"
            }
        };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["id_validation"]
}
isolated function idInputTypeValidationTestForFloatOrNil() returns error? {
    string document = string `query { floatId1(floatId: "6.0") }`;
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = 
        {
            "data": {
                "floatId1": "Hello, World"
            }
        };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["id_validation"]
}
isolated function idInputTypeValidationTestForDecimalOrNil() returns error? {
    string document = string `query { decimalId1(decimalId: "45.0") }`;
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = 
        {
            "data": {
                "decimalId1": "Hello, World"
            }
        };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["id_validation"]
}
isolated function idInputTypeValidationTestForInt1() returns error? {
    string document = string `query {
                                intIdReturnRecord(intId: 67) {
                                    __typename
                                    id
                                    name
                                }
                            }`;
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = 
        {
            "data": {
                "intIdReturnRecord": {
                "__typename": "Student5",
                "id": 2,
                "name": "Jennifer Flackett"
                }
            }
        };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["id_validation"]
}
isolated function idInputTypeValidationTestForIntArray1() returns error? {
    string document = string `query {
                                    intArrayReturnRecord(intId: "[2,3]") {
                                        __typename
                                        id
                                        name
                                    }
                                }`;
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = 
        {
            "data": {
                "intArrayReturnRecord": {
                "__typename": "Student5",
                "id": 2,
                "name": "Jennifer Flackett"
                }
            }
        };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["id_validation"]
}
isolated function idInputTypeValidationTestForStringArray1() returns error? {
    string document = string `query {
                                    stringArrayReturnRecord(stringId: "[Hello, World]") {
                                        __typename
                                        id
                                        name
                                    }
                                }`;
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = 
        {
            "data": {
                "stringArrayReturnRecord": {
                "__typename": "Student5",
                "id": 2,
                "name": "Jennifer Flackett"
                }
            }
        };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["id_validation"]
}
isolated function idInputTypeValidationTestForFloatArray1() returns error? {
    string document = string `query {
                                    floatArrayReturnRecord(floatId: "[0.8,5.0, 6.9]") {
                                        __typename
                                        id
                                        name
                                    }
                                }`;
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = 
        {
            "data": {
                "floatArrayReturnRecord": {
                "__typename": "Student5",
                "id": 2,
                "name": "Jennifer Flackett"
                }
            }
        };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

@test:Config {
    groups: ["id_validation"]
}
isolated function idInputTypeValidationTestForDecimalArray1() returns error? {
    string document = string `query {
                                    decimalArrayReturnRecord(decimalId: "[0.8,5.0, 6.9]") {
                                        __typename
                                        id
                                        name
                                    }
                                }`;
    json actualPayload = check graphqlClient->executeWithType(document);
    json expectedPayload = 
        {
            "data": {
                "decimalArrayReturnRecord": {
                "__typename": "Student5",
                "id": 2,
                "name": "Jennifer Flackett"
                }
            }
        };
    assertJsonValuesWithOrder(actualPayload.toJson(), expectedPayload.toJson());
}

