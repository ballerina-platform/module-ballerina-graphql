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

service /graphql on new Listener(9106) {
    resource function get people() returns Person[] {
        return people;
    }

    resource function get students() returns Student[] {
        return students;
    }
}

@test:Config {
    groups: ["fragments", "unit"]
}
isolated function testUnknownFragment() returns error? {
    string document = string
`query {
    ...friend
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    string message = string`Unknown fragment "friend".`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 2,
                        column: 8
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "unit"]
}
isolated function testUnknownNestedFragments() returns error? {
    string document = string
`query {
    ...data
}

fragment data on Query {
    students {
        ...details
    }
}

fragment details on Student {
    courses {
        name
        ...fail
    }
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    string message = string`Unknown fragment "fail".`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 14,
                        column: 12
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["fragments", "unit"]
}
isolated function testFragments() returns error? {
    string document = string
`query {
    ...data
}

fragment data on Query {
    people {
        name
    }
}`;
    string url = "http://localhost:9106/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            employees: [
                {
                    name: "John Doe"
                },
                {
                    name: "Jane Doe"
                },
                {
                    name: "Johnny Roe"
                }
            ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}


