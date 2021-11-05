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

@test:Config {
    groups: ["alias"]
}
isolated function testAlias() returns error? {
    string document = check getGraphQLDocumentFromFile("alias.graphql");
    string url = "http://localhost:9091/duplicates";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            sherlock: {
                name: "Sherlock Holmes",
                address: {
                    city: "London"
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["alias", "records"]
}
isolated function testSameFieldWithMultipleAlias() returns error? {
    string document = check getGraphQLDocumentFromFile("same_field_with_multiple_alias.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("same_field_with_multiple_alias.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["alias", "records"]
}
isolated function testSameFieldWithMultipleAliasDifferentSubFields() returns error? {
    string document = check getGraphQLDocumentFromFile("same_field_with_multiple_alias_different_subfields.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("same_field_with_multiple_alias_different_subfields.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["alias", "records", "validation"]
}
isolated function testAliasWithInvalidFieldName() returns error? {
    string document = check getGraphQLDocumentFromFile("alias_with_invalid_field_name.graphql");
    string url = "http://localhost:9091/records";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: string`Cannot query field "firstName" on type "Person".`,
                locations: [
                    {
                        line: 3,
                        column: 9
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["alias", "service", "unions"]
}
isolated function testAliasOnServiceObjectsUnion() returns error? {
    string document = check getGraphQLDocumentFromFile("alias_on_service_objects_union.graphql");
    string url = "http://localhost:9092/unions";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("alias_on_service_objects_union.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["alias", "hierarchical_paths"]
}
isolated function testAliasOnHierarchicalResources() returns error? {
    string document = check getGraphQLDocumentFromFile("alias_on_hierarchical_resources.graphql");
    string url = "http://localhost:9094/profiles";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("alias_on_hierarchical_resources.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
