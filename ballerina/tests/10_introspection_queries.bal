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
    groups: ["introspection"]
}
isolated function testComplexIntrospectionQuery() returns error? {
    string graphqlUrl = "http://localhost:9092/service_objects";
    string document = "{ __schema { types { name kind } } }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedResult = check getJsonContentFromFile("complex_introspection_query.json");
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection"]
}
isolated function testInvalidIntrospectionQuery() returns error? {
    string graphqlUrl = "http://localhost:9092/service_objects";
    string document = "{ __schema { greet } }";
    json actualResult = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    string expectedMessage = "Cannot query field \"greet\" on type \"__Schema\".";
    json expectedResult = {
        errors: [
            {
                message: expectedMessage,
                locations: [
                    {
                        line: 1,
                        column: 14
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection"]
}
isolated function testIntrospectionQueryWithMissingSelection() returns error? {
    string graphqlUrl = "http://localhost:9092/service_objects";
    string document = "{ __schema }";
    json actualResult = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedResult = check getJsonContentFromFile("introspection_query_with_missing_selection.json");
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection"]
}
isolated function testQueryTypeIntrospection() returns error? {
    string graphqlUrl ="http://localhost:9091/validation";
    string document = "{ __schema { queryType { kind fields { name } } } }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedResult = check getJsonContentFromFile("query_type_introspection.json");
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection"]
}
isolated function testComplexIntrospectionQueryWithOtherFields() returns error? {
    string graphqlUrl = "http://localhost:9092/service_objects";
    string document = "{ __schema { types { name kind } } allVehicles { name } }";
    json actualResult = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedResult = check getJsonContentFromFile("complex_introspection_query_with_other_fields.json");
    assertJsonValuesWithOrder(actualResult, expectedResult);
}

@test:Config {
    groups: ["introspection"]
}
isolated function testEnumValueIntrospection() returns error? {
    string graphqlUrl ="http://localhost:9092/service_objects";
    string document = "{ __schema { types { enumValues } } }";
    json actualResult = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    json expectedResult = check getJsonContentFromFile("enum_value_introspection.json");
    assertJsonValuesWithOrder(actualResult, expectedResult);
}
