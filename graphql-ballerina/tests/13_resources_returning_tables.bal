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

service /graphql on new Listener(9105) {
    resource function get employees() returns EmployeeTable? {
        return employees;
    }
}

@test:Config {
    groups: ["tables", "unit"]
}
isolated function testResourceReturningTables() returns error? {
    string document = "{ employees { name } }";
    string url = "http://localhost:9105/graphql";
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

@test:Config {
    groups: ["negative", "tables", "unit"]
}
isolated function testQueryingTableWithoutSelections() returns error? {
    string document = "{ employees }";
    string url = "http://localhost:9105/graphql";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);

    string message = string`Field "employees" of type "[Employee]" must have a selection of subfields. Did you mean "employees { ... }"?`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 1,
                        column: 3
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}
