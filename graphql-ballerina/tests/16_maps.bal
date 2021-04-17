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

public type Contact record {
    string number;
};

public type Worker record {|
    string id;
    string name;
    map<Contact> contacts;
|};

public type Company record {|
    map<Worker> workers;
    map<Contact> contacts;
|};

Contact contact1 = {
    number: "+94112233445"
};

Contact contact2 = {
    number: "+94717171717"
};

Contact contact3 = {
    number: "+94771234567"
};

Worker w1 = {
    id: "id1",
    name: "John Doe",
    contacts: { home: contact1 }
};

Worker w2 = {
    id: "id2",
    name: "Jane Doe",
    contacts: { home: contact2 }
};

Worker w3 = {
    id: "id3",
    name: "Jonny Doe",
    contacts: { home: contact3 }
};

map<Worker> workers = { id1: w1, id2: w2, id3: w3 };
map<Contact> contacts = { home1: contact1, home2: contact2, home3: contact3 };

Company company = {
    workers: workers,
    contacts: contacts
};

service /graphql on new Listener(9109) {
    resource function get company() returns Company {
        return company;
    }
}

@test:Config {
    groups: ["map", "unit"]
}
isolated function testMap() returns error? {
    string document = string`query { company { workers(key: "id1") { name } } }`;
    string url = "http://localhost:9109/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            company: {
                workers: {
                    name: "John Doe"
                }
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["map", "unit"]
}
isolated function testNestedMap() returns error? {
    string document = string`query { company { workers(key: "id3") { contacts(key: "home") { number } } } }`;
    string url = "http://localhost:9109/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            company: {
                workers: {
                    contacts: {
                        number: "+94771234567"
                    }
                }
            }
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["map", "unit"]
}
isolated function testMapWithoutKeyInput() returns error? {
    string document = string`query { company { workers { name } } }`;
    string url = "http://localhost:9109/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    string message = string`Field "workers" argument "key" of type "String" is required, but it was not provided.`;
    json expectedPayload = {
        errors: [
            {
                message: message,
                locations: [
                    {
                        line: 1,
                        column: 19
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["map", "unit"]
}
isolated function testNestedMapWithoutKeyInput() returns error? {
    string document = string`query { company { workers(key: "w1") { contacts } } }`;
    string url = "http://localhost:9109/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    string message1 = string`Field "contacts" argument "key" of type "String" is required, but it was not provided.`;
    string message2 = string`Field "contacts" of type "Contact" must have a selection of subfields. Did you mean "contacts { ... }"?`;
    json expectedPayload = {
        errors: [
            {
                message: message1,
                locations: [
                    {
                        line: 1,
                        column: 40
                    }
                ]
            },
            {
                message: message2,
                locations: [
                    {
                        line: 1,
                        column: 40
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["map", "unit"]
}
function testMapsReturningFromResource() returns error? {
    Listener l = check new(9110);
    var result = l.attach(serviceWithResourcesReturningMaps, "/graphql");
    test:assertTrue(result is error);
    error err = <error>result;
    string expectedMessage = string`GraphQL resource cannot return type: map`;
    test:assertEquals(err.message(), expectedMessage);
}

Service serviceWithResourcesReturningMaps = service object {
    resource function get invalidResource() returns map<Contact> {
        return contacts;
    }
};
