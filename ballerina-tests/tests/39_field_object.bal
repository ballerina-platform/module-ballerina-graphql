// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
    groups: ["field-object"]
}
function testFieldObject() returns error? {
    string document = check getGraphQLDocumentFromFile("field_object.graphql");
    string url = "localhost:9092/service_types";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "QueryName");
    json expectedPayload = {
        data: {
            person: {
                name: "Sherlock Holmes"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["field-object"]
}
function testFieldObjectWithMultipleArgs() returns error? {
    string document = check getGraphQLDocumentFromFile("field_object.graphql");
    string url = "localhost:9092/service_types";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "QueryNameAndAge");
    json expectedPayload = {
        data: {
            person: {
                name: "Walter White",
                age: 50
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["field-object"]
}
function testFieldObjectUsingFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("field_object.graphql");
    string url = "localhost:9092/service_types";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "QueryNameAndAgeWithFragments");
    json expectedPayload = {
        data: {
            person: {
                name: "Walter White",
                age: 50
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["field-object"]
}
function testFieldObjectParameterOrder() returns error? {
    string document = check getGraphQLDocumentFromFile("field_object_parameter_order.graphql");
    string url = "localhost:9092/service_objects";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "FieldObjectParameterOrder1");
    json expectedPayload = {
        data: {
            student: {
                name: "Jesse Pinkman"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["field-object"]
}
function testFieldObjectParameterOrder2() returns error? {
    string document = check getGraphQLDocumentFromFile("field_object_parameter_order.graphql");
    string url = "localhost:9092/service_objects";
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = "FieldObjectParameterOrder2");
    json expectedPayload = {
        data: {
            student: {
                name: "Skinny Pete",
                id: 100
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
