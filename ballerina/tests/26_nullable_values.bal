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
    groups: ["inputs", "enums", "nullable"]
}
isolated function testNullAsEnumInputValue() returns error? {
    string url = "http://localhost:9091/inputs";
    string document = "{ isHoliday(weekday: null) }";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            isHoliday: false
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "nullable"]
}
isolated function testNullAsScalarInputValue() returns error? {
    string url = "http://localhost:9091/null_values";
    string document = "{ profile(id: null) { name } }";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            profile: {
                name: "Sherlock Holmes"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "nullable"]
}
isolated function testNullValueForNonNullArgument() returns error? {
    string url = "http://localhost:9091/inputs";
    string document = "{ greet(name: null) }";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Expected value of type "String!", found null.`,
                locations: [
                    {
                        line: 1,
                        column: 15
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "nullable"]
}
isolated function testNullValueForDefaultableArguments() returns error? {
    string url = "http://localhost:9091/null_values";
    string document = "mutation { profile(name: null) { name } }";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            profile: {
                name: "Sherlock Holmes"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "nullable"]
}
isolated function testNullValueInInputObjectField() returns error? {
    string url = "http://localhost:9091/null_values";
    string document = "{ book(author: { name: null, id: 1 }) { name } }";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            book: {
                name: "The Art of Electronics"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "nullable"]
}
isolated function testNullAsResourceFunctionName() returns error? {
    string url = "http://localhost:9091/null_values";
    string document = "{ null(value: null) }";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            'null: null
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
