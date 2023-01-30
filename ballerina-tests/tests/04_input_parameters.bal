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

const float CONVERSION_KG_TO_LBS = 2.205;

@test:Config {
    groups: ["inputs"]
}
isolated function testFunctionsWithInputParameter() returns error? {
    string document = string`{ greet (name: "Thisaru") }`;
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            greet: "Hello, Thisaru"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs"]
}
isolated function testInputParameterTypeNotPresentInReturnTypes() returns error? {
    string document = "{ isLegal(age: 21) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            isLegal: true
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "validation"]
}
isolated function testInvalidArgument() returns error? {
    string document = "{ quote(id: 4) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Unknown argument "id" on field "Query.quote".`,
                locations: [
                    {
                        line: 1,
                        column: 9
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs"]
}
isolated function testQueryWithoutDefaultParameter() returns error? {
    string document = "{ quoteById }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            quoteById: "I am a high-functioning sociapath!"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs"]
}
isolated function testQueryWithDefaultParameter() returns error? {
    string document = "{ quoteById(id: 2) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            quoteById: "I can make them hurt if I want to!"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs"]
}
isolated function testFloatAsInput() returns error? {
    string document = "{ weightInPounds(weightInKg: 1.3) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            weightInPounds: <float>2.8665000000000003 // Floating point multiplication
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs"]
}
isolated function testFloatWithPositiveInfinity() returns error? {
    string document = "{ weightInPounds(weightInKg: 1.7E309) }";
    string url = "http://localhost:9091/inputs";
    string actualPayload = check getTextPayloadFromService(url, document);
    json payloadWithFloatValues = check value:fromJsonFloatString(actualPayload);
    json expectedPayload = {
        data: {
            weightInPounds: float:Infinity
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs"]
}
isolated function testFloatNegativeInfinity() returns error? {
    string document = "{ weightInPounds(weightInKg: -1.7E309) }";
    string url = "http://localhost:9091/inputs";
    string actualPayload = check getTextPayloadFromService(url, document);
    json payloadWithFloatValues = check value:fromJsonFloatString(actualPayload);
    json expectedPayload = {
        data: {
            weightInPounds: -float:Infinity
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce"]
}
isolated function testCoerceIntInputToFloat() returns error? {
    string document = "{ weightInPounds(weightInKg: 1) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            weightInPounds: <float>2.205
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "validation"]
}
isolated function testPassingFloatForIntArguments() returns error? {
    string document = "{ isLegal(age: 20.5) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
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
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "validation"]
}
isolated function testInvalidArgumentWithValidArgument() returns error? {
    string url = "http://localhost:9091/inputs";
    string document = string`{ greet (name: "name", id: 3) }`;
    json actualPayload = check getJsonPayloadFromService(url, document);
    string expectedMessage = string`Unknown argument "id" on field "Query.greet".`;
    json expectedPayload = {
        errors: [
            {
                message: expectedMessage,
                locations: [
                    {
                        line: 1,
                        column: 24
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "validation"]
}
isolated function testObjectWithMissingRequiredArgument() returns error? {
    string url = "http://localhost:9091/inputs";
    string document = "{ greet }";
    json actualPayload = check getJsonPayloadFromService(url, document);

    string expectedMessage = string`Field "greet" argument "name" of type "String!" is required, but it was not provided.`;
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
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "enums"]
}
isolated function testOptionalEnumArgumentWithoutValue() returns error? {
    string url = "http://localhost:9091/inputs";
    string document = "{ isHoliday }";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            isHoliday: false
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "enums"]
}
isolated function testOptionalEnumArgumentWithValue() returns error? {
    string url = "http://localhost:9091/inputs";
    string document = "{ isHoliday(weekday: SUNDAY) }";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            isHoliday: true
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "escape_characters"]
}
isolated function testInputsWithEscapeCharacters() returns error? {
    string url = "http://localhost:9091/inputs";
    string document = string `{ type(version: "1.0.0") }`;
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            'type: "1.0.0"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "escape_characters"]
}
isolated function testInputsWithUnicodeCharacters() returns error? {
    string url = "http://localhost:9091/inputs";
    string document = string `{ version(name: "SwanLake") }`;
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            'version: "SwanLake"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
