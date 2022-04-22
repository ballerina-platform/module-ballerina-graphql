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
    groups: ["service", "schema_generation"]
}
isolated function testReturningRecursiveServiceTypes() returns error? {
    string document = string`query { trail(id: "blue-bird") { name } }`;
    string url = "http://localhost:9092/snowtooth";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            trail: {
                name: "Blue Bird"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["service", "schema_generation"]
}
isolated function testRequestInvalidFieldFromServiceObjects() returns error? {
    string document = check getGraphQLDocumentFromFile("request_invalid_field_from_service_objects.graphql");
    string url = "http://localhost:9092/snowtooth";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Cannot query field "invalid" on type "Lift".`,
                locations: [
                    {
                        line: 5,
                        column: 9
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["service", "union", "recursive_service", "schema_generation"]
}
isolated function testReturningUnionOfServiceObjects() returns error? {
    string document = check getGraphQLDocumentFromFile("returning_union_of_service_objects.graphql");
    string url = "http://localhost:9092/snowtooth";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("returning_union_of_service_objects.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["introspection", "service", "union", "fragments"]
}
isolated function testGraphQLPlaygroundIntrospectionQuery() returns error? {
    string document = check getGraphQLDocumentFromFile("graphql_playground_introspection_query.graphql");
    json expectedPayload = check getJsonContentFromFile("graphql_playground_introspection_query.json");
    string url = "http://localhost:9092/snowtooth";
    json actualPayload = check getJsonPayloadFromService(url, document);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
