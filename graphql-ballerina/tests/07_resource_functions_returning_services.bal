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

listener Listener serviceTypeListener = new(9097);

service class Name {
    isolated resource function get first() returns string {
        return "Sherlock";
    }

    isolated resource function get last() returns string {
        return "Holmes";
    }
}

service class Profile {
    isolated resource function get name() returns Name {
        return new;
    }
}

service class GeneralGreeting {
    isolated resource function get generalGreeting() returns string {
        return "Hello, world";
    }
}

service /graphql on serviceTypeListener {
    isolated resource function get greet() returns GeneralGreeting {
        return new;
    }

    isolated resource function get profile() returns Profile {
        return new;
    }
}

Service serviceReturningServiceObjects = service object {
    isolated resource function get profile() returns service object {} {
        return service object {
            isolated resource function get name() returns service object {} {
                return service object {
                    isolated resource function get first() returns string {
                        return "Sherlock";
                    }
                    isolated resource function get last() returns string {
                        return "Holmes";
                    }
                };
            }
        };
    }
};

@test:Config {
    groups: ["service", "unit"]
}
isolated function testResourceReturningServiceObject() returns @tainted error? {
    string graphqlUrl = "http://localhost:9097/graphql";
    string document = "{ greet { generalGreeting } }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

    json expectedPayload = {
        data: {
            greet: {
                generalGreeting: "Hello, world"
            }
        }
    };
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["service", "unit"]
}
isolated function testInvalidQueryFromServiceObjectResource() returns @tainted error? {
    string graphqlUrl = "http://localhost:9097/graphql";
    string document = "{ profile { name { nonExisting } } }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

    json expectedPayload = {
        errors: [
            {
                maessage: "Cannot query field \"nonExisting\" on type \"Name\"",
                location: {
                    line: 1,
                    column: 9
                }
            }
        ]
    };
}

@test:Config {
    groups: ["service", "unit"]
}
isolated function testComplexService() returns error? {
    string graphqlUrl = "http://localhost:9097/graphql";
    string document = "{ profile { name { first, last } } }";
    json result = check getJsonPayloadFromService(graphqlUrl, document);

    json expectedPayload = {
        data: {
            profile: {
                name: {
                    first: "Sherlock",
                    last: "Holmes"
                }
            }
        }
    };
    test:assertEquals(result, expectedPayload);
}

@test:Config {
    groups: ["service", "unit"]
}
function testResourcesReturningServiceObjects() returns @tainted error? {
    var result = serviceTypeListener.attach(serviceReturningServiceObjects, "invalidService");
    test:assertTrue(result is Error);
    Error err = <Error> result;
    string expectedMessage = "Returning anonymous service objects are not supported by GraphQL resources";
    test:assertEquals(err.message(), expectedMessage);
}
