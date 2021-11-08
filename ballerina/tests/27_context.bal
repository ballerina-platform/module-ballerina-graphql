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

import ballerina/http;
import ballerina/test;

@test:Config {
    groups: ["context"]
}
function testCreatingContextWithScalarValues() returns error? {
    ContextInit contextInit =
        isolated function (http:RequestContext requestContext, http:Request request) returns Context|error {
            Context context = new;
            check context.add("String", "Ballerina");
            check context.add("Int", 5);
            check context.add("Boolean", false);
            return context;
        };
    http:Request request = new;
    http:RequestContext requestContext = new;
    Context context = check contextInit(requestContext, request);
    test:assertEquals(<string> check context.get("String"), "Ballerina");
    test:assertEquals(<int> check context.get("Int"), 5);
    test:assertEquals(<boolean> check context.get("Boolean"), false);
}

@test:Config {
    groups: ["context"]
}
function testCreatingContextWithObjectValues() returns error? {
    ContextInit contextInit =
        isolated function (http:RequestContext requestContext, http:Request request) returns Context|error {
            Context context = new;
            check context.add("HierarchicalServiceObject", new HierarchicalName());
            return context;
        };
    http:Request request = new;
    http:RequestContext requestContext = new;
    Context context = check contextInit(requestContext, request);
    test:assertTrue((check context.get("HierarchicalServiceObject")) is HierarchicalName);
}

@test:Config {
    groups: ["context"]
}
function testRemovingAttributeFromContext() returns error? {
    ContextInit contextInit =
        isolated function (http:RequestContext requestContext, http:Request request) returns Context|error {
            Context context = new;
            check context.add("String", "Ballerina");
            return context;
        };
    http:Request request = new;
    http:RequestContext requestContext = new;
    Context context = check contextInit(requestContext, request);
    var attribute1 = check context.remove("String");
    test:assertTrue(attribute1 is string);
    test:assertEquals(<string>attribute1, "Ballerina");

    var attribute2 = context.remove("String");
    test:assertTrue(attribute2 is Error);
    test:assertEquals((<Error>attribute2).message(), "Attribute with the key \"String\" not found in the context");
}

@test:Config {
    groups: ["context"]
}
function testRemovingObjectAttributeFromContext() returns error? {
    ContextInit contextInit =
        isolated function (http:RequestContext requestContext, http:Request request) returns Context|error {
            Context context = new;
            check context.add("HierarchicalServiceObject", new HierarchicalName());
            return context;
        };
    http:Request request = new;
    http:RequestContext requestContext = new;
    Context context = check contextInit(requestContext, request);
    var attribute1 = check context.remove("HierarchicalServiceObject");
    test:assertTrue(attribute1 is HierarchicalName);

    var attribute2 = context.remove("String");
    test:assertTrue(attribute2 is Error);
    test:assertEquals((<Error>attribute2).message(), "Attribute with the key \"String\" not found in the context");
}

@test:Config {
    groups: ["context"]
}
function testRequestingInvalidAttributeFromContext() returns error? {
    ContextInit contextInit =
        isolated function (http:RequestContext requestContext, http:Request request) returns Context|error {
            Context context = new;
            check context.add("String", "Ballerina");
            return context;
        };
    http:Request request = new;
    http:RequestContext requestContext = new;
    Context context = check contextInit(requestContext, request);
    var invalidAttribute = context.get("No");
    test:assertTrue(invalidAttribute is Error);
    test:assertEquals((<Error>invalidAttribute).message(), "Attribute with the key \"No\" not found in the context");
}

@test:Config {
    groups: ["context"]
}
function testAddingDuplicateAttribute() returns error? {
    ContextInit contextInit =
        isolated function (http:RequestContext requestContext, http:Request request) returns Context|error {
            Context context = new;
            check context.add("String", "Ballerina");
            check context.add("String", "Ballerina");
            return context;
        };
    http:Request request = new;
    http:RequestContext requestContext = new;
    Context|error context = contextInit(requestContext, request);
    test:assertTrue(context is error);
    test:assertEquals((<error>context).message(), "Cannot add attribute to the context. Key \"String\" already exists");
}

@test:Config {
    groups: ["context"]
}
isolated function testContextWithHttpHeaderValues() returns error? {
    string url = "http://localhost:9092/context";
    string document = "{ profile { name } }";
    http:Request request = new;
    request.setHeader("scope", "admin");
    request.setPayload({ query: document });
    json actualPayload = check getJsonPayloadFromRequest(url, request);
    json expectedPayload = {
        data: {
            profile: {
                name: "Walter White"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["context"]
}
isolated function testContextWithAdditionalParameters() returns error? {
    string url = "http://localhost:9092/context";
    string document = string`{ name(name: "Jesse Pinkman") }`;
    http:Request request = new;
    request.setHeader("scope", "admin");
    request.setPayload({ query: document });
    json actualPayload = check getJsonPayloadFromRequest(url, request);
    json expectedPayload = {
        data: {
            name: "Jesse Pinkman"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["context"]
}
isolated function testContextWithHttpHeaderValuesWithInvalidScope() returns error? {
    string url = "http://localhost:9092/context";
    string document = "{ profile { name } }";
    http:Request request = new;
    request.setHeader("scope", "user");
    request.setPayload({ query: document });
    json actualPayload = check getJsonPayloadFromRequest(url, request);
    json expectedPayload = {
        errors: [
            {
                message: "You don't have permission to retrieve data",
                locations: [
                    {
                        line: 1,
                        column: 3
                    }
                ],
                path: [
                    "profile"
                ]
            }
        ],
        data: null
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["context"]
}
isolated function testContextWithHttpHeaderValuesInRemoteFunction() returns error? {
    string url = "http://localhost:9092/context";
    string document = "mutation { update { name } }";
    http:Request request = new;
    request.setHeader("scope", "admin");
    request.setPayload({ query: document });
    json actualPayload = check getJsonPayloadFromRequest(url, request);
    json expectedPayload = {
        data: {
            update: [
                {
                    name: "Sherlock Holmes"
                },
                {
                    name: "Walter White"
                },
                {
                    name: "Tom Marvolo Riddle"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["context"]
}
isolated function testContextWithHttpHeaderValuesInRemoteFunctionWithInvalidScope() returns error? {
    string url = "http://localhost:9092/context";
    string document = "mutation { update { name } }";
    http:Request request = new;
    request.setHeader("scope", "user");
    request.setPayload({ query: document });
    json actualPayload = check getJsonPayloadFromRequest(url, request);
    json expectedPayload = {
        errors: [
            {
                message: "You don't have permission to retrieve data",
                locations: [
                    {
                        line: 1,
                        column: 12
                    }
                ],
                path: [ "update", 1 ]
            }
        ],
        data: null
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["context"]
}
isolated function testNullableArrayElementValuesWithError() returns error? {
    string url = "http://localhost:9092/context";
    string document = "mutation { updateNullable { name } }";
    http:Request request = new;
    request.setHeader("scope", "user");
    request.setPayload({ query: document });
    json actualPayload = check getJsonPayloadFromRequest(url, request);
    json expectedPayload = {
        errors: [
            {
                message: "You don't have permission to retrieve data",
                locations: [
                    {
                        line: 1,
                        column: 12
                    }
                ],
                path: [ "updateNullable", 1 ]
            }
        ],
        data: {
            updateNullable: [
                {
                    name: "Sherlock Holmes"
                },
                null,
                {
                    name: "Tom Marvolo Riddle"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["context"]
}
isolated function testContextWithMissingAttribute() returns error? {
    string url = "http://localhost:9092/context";
    string document = "mutation { update { name } }";
    json actualPayload = check assertResponseAndGetPayload(url, document,
                                                           statusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    json expectedPayload = {
        errors: [
            {
                message: "Http header does not exist"
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["context"]
}
isolated function testContextWithAdditionalParametersInNestedObject() returns error? {
    string url = "http://localhost:9092/context";
    string document = string`{ animal { call(sound: "Meow", count: 3) } }`;
    http:Request request = new;
    request.setHeader("scope", "admin");
    request.setPayload({ query: document });
    json actualPayload = check getJsonPayloadFromRequest(url, request);
    json expectedPayload = {
        data: {
            animal: {
                call: "Meow Meow Meow "
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["context"]
}
isolated function testContextWithAdditionalParametersInNestedObjectWithInvalidScope() returns error? {
    string url = "http://localhost:9092/context";
    string document = string`{ animal { call(sound: "Meow", count: 3) } }`;
    http:Request request = new;
    request.setHeader("scope", "user");
    request.setPayload({ query: document });
    json actualPayload = check getJsonPayloadFromRequest(url, request);
    json expectedPayload = {
        data: {
            animal: {
                call: "Meow"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
