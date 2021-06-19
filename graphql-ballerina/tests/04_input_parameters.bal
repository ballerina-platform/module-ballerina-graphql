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
import ballerina/lang.value;

listener Listener functionWithArgumentsListener = new(9093);

const float CONVERSION_KG_TO_LBS = 2.205;

service /graphql on functionWithArgumentsListener {
    isolated resource function get greet(string name) returns string {
        return "Hello, " + name;
    }

    isolated resource function get isLegal(int age) returns boolean {
        if (age < 21) {
            return false;
        }
        return true;
    }

    resource function get person() returns Person {
        return people[0];
    }

    resource function get personById(int id = 0) returns Person? {
        if (id < people.length()) {
            return people[id];
        }
    }

    resource function get weightInPounds(float weightInKg) returns float {
        return weightInKg * CONVERSION_KG_TO_LBS;
    }
}

@test:Config {
    groups: ["input_types", "unit"]
}
isolated function testFunctionsWithInputParameter() returns error? {
    string document = string
    `{
    greet (name: "Thisaru")
}`;
    string url = "http://localhost:9093/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            greet: "Hello, Thisaru"
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_types", "unit"]
}
isolated function testInputParameterTypeNotPresentInReturnTypes() returns error? {
    string document = "{ isLegal(age: 21) }";
    string url = "http://localhost:9093/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            isLegal: true
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_types", "unit"]
}
isolated function testInvalidParameter() returns error? {
    string document = "{ person(id: 4) { name } }";
    string url = "http://localhost:9093/graphql";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);

    json expectedPayload = {
        errors: [
            {
                message: string`Unknown argument "id" on field "Query.person".`,
                locations: [
                    {
                        line: 1,
                        column: 10
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_types", "unit"]
}
isolated function testQueryWithoutDefaultParameter() returns error? {
    string document = "{ personById { name } }";
    string url = "http://localhost:9093/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            personById: {
                name: "Sherlock Holmes"
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_types", "unit"]
}
isolated function testQueryWithDefaultParameter() returns error? {
    string document = "{ personById(id: 2) { name } }";
    string url = "http://localhost:9093/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            personById: {
                name: "Tom Marvolo Riddle"
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_types"]
}
isolated function testFloatAsInput() returns error? {
    string document = "{ weightInPounds(weightInKg: 1.3) }";
    string url = "http://localhost:9093/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            weightInPounds: <float>2.8665000000000003 // Floating point multiplication
        }
    };
    test:assertEquals(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["input_types", "float_to_int_coerce"]
}
isolated function testCoerceIntInputToFloat() returns error? {
    string document = "{ weightInPounds(weightInKg: 1) }";
    string url = "http://localhost:9093/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            weightInPounds: <float>2.205
        }
    };
    test:assertEquals(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["input_types"]
}
isolated function testPassingFloatForIntArguments() returns error? {
    string document = "{ isLegal(age: 20.5) }";
    string url = "http://localhost:9093/graphql";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Int cannot represent non Int value: 20.5`,
                locations: [
                    {
                        line: 1,
                        column: 16
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}
