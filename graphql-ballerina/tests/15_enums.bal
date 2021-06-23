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

service /graphql on new Listener(9107) {
    isolated resource function get weekday(int number) returns Weekday {
        match number {
            1 => {
                return MONDAY;
            }
            2 => {
                return TUESDAY;
            }
            3 => {
                return WEDNESDAY;
            }
            4 => {
                return THURSDAY;
            }
            5 => {
                return FRIDAY;
            }
            6 => {
                return SATURDAY;
            }
        }
        return SUNDAY;
    }

    isolated resource function get day(int number) returns Weekday|error {
        if (number < 1 || number > 7) {
            return error("Invalid number");
        } else if (number == 1) {
            return MONDAY;
        } else if (number == 2) {
            return TUESDAY;
        } else if (number == 3) {
            return WEDNESDAY;
        } else if (number == 4) {
            return THURSDAY;
        } else if (number == 5) {
            return FRIDAY;
        } else if (number == 6) {
            return SATURDAY;
        } else {
            return SUNDAY;
        }
    }

    isolated resource function get time() returns Time {
        return {
            weekday: MONDAY,
            time: "22:10:33"
        };
    }

    isolated resource function get isHoliday(Weekday weekday) returns boolean {
        if (weekday == SATURDAY || weekday == SUNDAY) {
            return true;
        }
        return false;
    }

    isolated resource function get holidays() returns Weekday[] {
        return [SATURDAY, SUNDAY];
    }
}

@test:Config {
    groups: ["enum"]
}
isolated function testEnum() returns error? {
    string document = "query { time { weekday } }";
    string url = "http://localhost:9107/graphql";
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
    groups: ["enum"]
}
isolated function testEnumInsideRecord() returns error? {
    string document = "query { weekday(number: 3) }";
    string url = "http://localhost:9107/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            weekday: "WEDNESDAY"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["enum"]
}
isolated function testEnumIntrospection() returns error? {
    string document = "{ __schema { types { name enumValues { name } } } }";
    string url = "http://localhost:9107/graphql";
    json expectedPayload = check getJsonContentFromFile("enum_introspection.json");
    json actualPayload = check getJsonPayloadFromService(url, document);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["enum"]
}
isolated function testEnumWithUnion() returns error? {
    string document = "query { day(number: 10) }";
    string url = "http://localhost:9107/graphql";
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
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["enum"]
}
isolated function testEnumInputParameter() returns error? {
    string document = "query { isHoliday(weekday: SUNDAY) }";
    string url = "http://localhost:9107/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            isHoliday: true
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}


@test:Config {
    groups: ["enum", "array"]
}
isolated function testReturningEnumArray() returns error? {
    string document = "query { holidays }";
    string url = "http://localhost:9107/graphql";
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
    groups: ["enum"]
}
isolated function testEnumInvalidInputParameter() returns error? {
    string document = "query { isHoliday(weekday: FUNDAY) }";
    string url = "http://localhost:9107/graphql";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Value "FUNDAY" does not exist in "weekday" enum.`,
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
    groups: ["enum"]
}
isolated function testEnumInputParameterAsString() returns error? {
    string document = string`query { isHoliday(weekday: "SUNDAY") }`;
    string url = "http://localhost:9107/graphql";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Enum "Weekday" cannot represent non-enum value: "SUNDAY"`,
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
