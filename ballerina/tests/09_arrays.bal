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

isolated service class Vehicle {
    private final string id;
    private final string name;
    private final int? registeredYear;

    isolated function init(string id, string name, int? registeredYear = ()) {
        self.id = id;
        self.name = name;
        self.registeredYear = registeredYear;
    }

    isolated resource function get id() returns string {
        return self.id;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get registeredYear() returns int|error {
        int? registeredYear = self.registeredYear;
        if (registeredYear == ()) {
            return error("Registered Year is Not Found");
        } else {
            return registeredYear;
        }
    }
}

@test:Config {
    groups: ["arrays"]
}
isolated function testScalarArrays() returns error? {
    string graphqlUrl = "http://localhost:9091/validation";
    string document = "{ ids }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedResult = {
        data: {
            ids: [0, 1, 2]
        }
    };
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["array", "service"]
}
isolated function testResourceReturningServiceObjectArray() returns error? {
    string graphqlUrl = "http://localhost:9092/service_objects";
    string document = string `{ allVehicles { name } }`;
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = {
        data: {
            allVehicles: [
                {
                    name: "Benz"
                },
                {
                    name: "BMW"
                },
                {
                    name: "Ford"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["array", "service"]
}
isolated function testResourceReturningOptionalServiceObjectsArray() returns error? {
    string graphqlUrl = "http://localhost:9092/service_objects";
    string document = string `{ searchVehicles(keyword: "vehicle") { ...on Vehicle { id } } }`;
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = {
        data: {
            searchVehicles: [
                {
                    id: "V1"
                },
                {
                    id: "V2"
                },
                {
                    id: "V3"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["array", "service"]
}
isolated function testOptionalArrayInvalidQuery() returns error? {
    string graphqlUrl = "http://localhost:9092/service_objects";
    string document = string `{ searchVehicles(keyword: "vehicle") }`;
    json result = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Field "searchVehicles" of type "[Vehicle!]" must have a selection of subfields. Did you mean "searchVehicles { ... }"?`,
                locations: [
                    {
                        line: 1,
                        column: 3
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["array", "service"]
}
isolated function testServiceObjectArrayWithFragmentReturningError() returns error? {
    string graphqlUrl = "http://localhost:9092/service_objects";
    string document = check getGraphQLDocumentFromFile("service_object_array_with_fragment_returning_error.graphql");
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = check getJsonContentFromFile("service_object_array_with_fragment_returning_error.json");
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["array", "service"]
}
isolated function testServiceObjectArrayWithInvalidResponseOrder() returns error? {
    string graphqlUrl = "http://localhost:9092/service_objects";
    string document = check getGraphQLDocumentFromFile("service_object_array_with_fragment_returning_error.graphql");
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = check getJsonContentFromFile("service_object_array_with_invalid_response_order.json");
    test:assertEquals(result, expectedPayload);
    string actualPayloadString = result.toString();
    string expectedPayloadString = expectedPayload.toString();
    test:assertNotEquals(actualPayloadString, expectedPayloadString);
}
