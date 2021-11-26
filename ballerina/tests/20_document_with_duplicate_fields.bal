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
    groups: ["duplicate", "records"]
}
isolated function testDuplicateFieldWithResourceReturningRecord() returns error? {
    string document = check getGraphQLDocumentFromFile("duplicate_fields_with_record_types.graphql");
    string url = "http://localhost:9091/duplicates";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            profile: {
                name: "Sherlock Holmes",
                address: {
                    city: "London",
                    street: "Baker Street"
                }
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["duplicate", "fragments"]
}
isolated function testNamedFragmentsWithDuplicateFields() returns error? {
    string document = check getGraphQLDocumentFromFile("named_fragments_with_duplicate_fields.graphql");
    string url = "http://localhost:9091/duplicates";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("named_fragments_with_duplicate_fields.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["duplicate", "fragments", "inline"]
}
isolated function testDuplicateInlineFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("duplicate_inline_fragments.graphql");
    string url = "http://localhost:9091/duplicates";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("duplicate_inline_fragments.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
