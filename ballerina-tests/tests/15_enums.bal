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
    groups: ["enums"]
}
isolated function testEnum() returns error? {
    string document = "query { time { weekday } }";
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromService(url, document);
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
    groups: ["enums"]
}
isolated function testEnumInsideRecord() returns error? {
    string document = "query { weekday(number: 3) }";
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            weekday: "WEDNESDAY"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["enums", "introspection"]
}
isolated function testEnumIntrospection() returns error? {
    string document = "{ __schema { types { name enumValues { name } } } }";
    string url = "http://localhost:9095/special_types";
    json expectedPayload = check getJsonContentFromFile("enum_introspection.json");
    json actualPayload = check getJsonPayloadFromService(url, document);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["enums"]
}
isolated function testEnumWithUnion() returns error? {
    string document = "query { day(number: 10) }";
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "Invalid number",
                locations: [
                    {
                        line: 1,
                        column: 9
                    }
                ],
                path: ["day"]
            }
        ],
        data: null
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["enums"]
}
isolated function testEnumInputParameter() returns error? {
    string document = "query { isHoliday(weekday: SUNDAY) }";
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            isHoliday: true
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["enums", "array"]
}
isolated function testReturningEnumArray() returns error? {
    string document = "query { holidays }";
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            holidays: [
                "SATURDAY",
                "SUNDAY"
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["enums", "array"]
}
isolated function testReturningEnumArrayWithErrors() returns error? {
    string document = "query { openingDays }";
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromService(url, document);
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
                path: ["openingDays", 2]
            }
        ],
        data: null
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["enums", "array"]
}
isolated function testReturningNullableEnumArrayWithErrors() returns error? {
    string document = "query { specialHolidays }";
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromService(url, document);
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
    groups: ["enums"]
}
isolated function testEnumInvalidInputParameter() returns error? {
    string document = "query { isHoliday(weekday: FUNDAY) }";
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: string `Value "FUNDAY" does not exist in "weekday" enum.`,
                locations: [
                    {
                        line: 1,
                        column: 28
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["enums"]
}
isolated function testEnumInputParameterAsString() returns error? {
    string document = string `query { isHoliday(weekday: "SUNDAY") }`;
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: string `Enum "Weekday" cannot represent non-enum value: "SUNDAY"`,
                locations: [
                    {
                        line: 1,
                        column: 28
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["enums"]
}
isolated function testEnumWithValuesAssigned() returns error? {
    string document = string `{ month(month: JANUARY) }`;
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            month: "January"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["enums"]
}
isolated function testEnumWithValuesAssignedUsingVariables() returns error? {
    string document = string `query GetMonth($month: Month!) { month(month: $month) }`;
    map<json> variables = {
        month: "MAY"
    };
    string url = "http://localhost:9095/special_types";
    json actualPayload = check getJsonPayloadFromService(url, document, variables = variables);
    json expectedPayload = {
        data: {
            month: "May"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
