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
    json actualPayload = check getJsonPayloadFromService(url, document);
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

@test:Config {
    groups: ["variables", "inputs", "enums"]
}
isolated function testNullAsEnumInputWithVariableValue() returns error? {
    string document = "($day:Weekday){ isHoliday(weekday: $day) }";
    json variables = { day: null };
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data: {
            isHoliday: false
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "variables", "nullable"]
}
isolated function testNullAsScalarInputWithVariableValue() returns error? {
    string url = "http://localhost:9091/null_values";
    string document = "($id:Int){ profile(id: $id) { name } }";
    json variables = {
        id: null
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
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
    groups: ["inputs", "variables", "nullable"]
}
isolated function testNullValueForNonNullArgumentWithVariableValue() returns error? {
    string url = "http://localhost:9091/inputs";
    string document = "($name: String!){ greet(name: $name) }";
    json variables = {
        name: null
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        errors: [
            {
                message: string `Variable name expected value of type "String!", found null`,
                locations: [
                    {
                        line: 1,
                        column: 32
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "variables", "nullable"]
}
isolated function testNullValueForDefaultableArgumentsWithVariable() returns error? {
    string url = "http://localhost:9091/null_values";
    string document = "mutation($name: String){ profile(name: $name) { name } }";
    json variables = {
        name: null
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
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
    groups: ["inputs", "variables", "nullable"]
}
isolated function testNullValueInInputObjectFieldWithVariableValue() returns error? {
    string url = "http://localhost:9091/null_values";
    string document = "($author: Author){ book(author: $author) { name } }";
    json variables = {
        author: {
            name: null,
            id: 1
        }
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
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
    groups: ["list", "variables", "inputs"]
}
isolated function testNullValueInListTypeInputWithVaraibles() returns error? {
    string document = string`query ($words: [String]){ concat(words: $words) }`;
    string url = "http://localhost:9091/list_inputs";
    json variables = {
        words: ["Hello!", null, "GraphQL"]
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data: {
            concat:  "Hello! GraphQL"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "variables", "nullable"]
}
isolated function testNullValueForNullableInputObjectWithVariableValue() returns error? {
    string url = "http://localhost:9091/null_values";
    string document = "($author: Author){ book(author: $author) { name } }";
    json variables = {
        author: null
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data: {
            book: {
                name: "Algorithms to Live By"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["list", "variables", "inputs"]
}
isolated function testNullValueForNullableListTypeInputWithVaraibles() returns error? {
    string document = string`query ($words: [String]){ concat(words: $words) }`;
    string url = "http://localhost:9091/list_inputs";
    json variables = {
        words: null
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = {
        data: {
            concat:  "Word list is empty"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
