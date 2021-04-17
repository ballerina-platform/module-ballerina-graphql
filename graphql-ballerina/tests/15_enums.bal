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
}

@test:Config {
    groups: ["enum", "unit"]
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
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["enum", "unit"]
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
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["enum", "unit"]
}
function testEnumIntrospection() returns error? {
    string document = "{ __schema { types { name enumValues { name } } } }";
    string url = "http://localhost:9107/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    test:assertEquals(actualPayload, enumTypeInspectionResult);
}

@test:Config {
    groups: ["enum", "unit"]
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
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["enum", "unit"]
}
function testEnumWithInvalidUnion() returns error? {
    Listener l = check new(9108);
    var result = l.attach(serviceWithInvalidUnion, "/graphql");
    test:assertTrue(result is error);
    error err = <error>result;
    string expectedMessage =
        string`Unsupported union: If a field type is a union, it should be a subtype of "<T>|error?", except "error?"`;
    test:assertEquals(err.message(), expectedMessage);
}

Service serviceWithInvalidUnion = service object {
    isolated resource function get invalidResource() returns Weekday|string {
        return "John Doe";
    }
};
