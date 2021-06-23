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

service /graphql on new Listener(9112) {
    resource function get person(int id) returns Person? {
        if (id < 3) {
            return people[id];
        }
    }

    isolated resource function get greet() returns string {
        return "Hello, World";
    }
}

@test:Config {
    groups: ["playground", "introspection"]
}
isolated function testGraphQLPlaygroundIntrospectionQuery() returns error? {
    string document = check getGraphQLDocumentFromFile("graphql_playground_introspection_query.txt");
    json expectedPayload = check getJsonContentFromFile("graphql_playground_introspection_query.json");
    string url = "http://localhost:9111/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["playground", "introspection"]
}
isolated function testIntrospectionForPersonAndGreet() returns error? {
    string document = check getGraphQLDocumentFromFile("introspection_for_person_and_greet.txt");
    json expectedPayload = check getJsonContentFromFile("introspection_for_person_and_greet.json");
    string url = "http://localhost:9112/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
