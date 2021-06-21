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

service /graphql on new Listener(9113) {
    isolated resource function get profile(int id) returns StudentService|TeacherService {
        if (id < 100) {
            return new StudentService(1, "Jesse Pinkman");
        } else {
            return new TeacherService(737, "Walter White", "Chemistry");
        }
    }

    isolated resource function get search() returns (StudentService|TeacherService)[] {
        StudentService s = new StudentService(1, "Jesse Pinkman");
        TeacherService t = new TeacherService(737, "Walter White", "Chemistry");
        return [s, t];
    }
}

distinct service class StudentService {
    private int id;
    private string name;

    public isolated function init(int id, string name) {
        self.id = id;
        self.name = name;
    }

    isolated resource function get id() returns int {
        return self.id;
    }

    isolated resource function get name() returns string {
        return self.name;
    }
}

distinct service class TeacherService {
    private int id;
    private string name;
    private string subject;

    public isolated function init(int id, string name, string subject) {
        self.id = id;
        self.name = name;
        self.subject = subject;
    }

    isolated resource function get id() returns int {
        return self.id;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get subject() returns string {
        return self.subject;
    }
}

@test:Config {
    groups: ["service", "union"]
}
isolated function testUnionOfDistinctServices() returns error? {
    string document = string
`query {
    profile(id: 200) {
        ... on StudentService {
            name
        }
        ... on TeacherService {
            name
            subject
        }
    }
}`;
    string url = "http://localhost:9113/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            profile: {
                name: "Walter White",
                subject: "Chemistry"
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["service", "union", "negative"]
}
isolated function testInvalidQueryWithDistinctServiceUnions() returns error? {
    string document = string
`query {
    profile(id: 200) {
        name
    }
}`;
    string url = "http://localhost:9113/graphql";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Cannot query field "name" on type "StudentService|TeacherService". Did you mean to use a fragment on "StudentService" or "TeacherService"?`,
                locations: [
                    {
                        line: 3,
                        column: 9
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}


@test:Config {
    groups: ["service", "union"]
}
isolated function testUnionOfDistinctServicesQueryOnSelectedTypes() returns error? {
    string document = string
`query {
    profile(id: 200) {
        ... on StudentService {
            name
        }
    }
}`;
    string url = "http://localhost:9113/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            profile: {}
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["service", "union"]
}
isolated function testUnionOfDistinctServicesArrayQueryOnSelectedTypes() returns error? {
    string document = string
`query {
    search {
        ... on TeacherService {
            name
        }
    }
}`;
    string url = "http://localhost:9113/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            search: [
                {},
                {
                    name: "Walter White"
                }
            ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["service", "union"]
}
isolated function testUnionOfDistinctServicesArrayQueryOnSelectedTypesFragmentOnRoot() returns error? {
    string document = string
`query {
    ... on Query {
        search {
            ... on TeacherService {
                name
            }
        }
    }
}`;
    string url = "http://localhost:9113/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            search: [
                {},
                {
                    name: "Walter White"
                }
            ]
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}
