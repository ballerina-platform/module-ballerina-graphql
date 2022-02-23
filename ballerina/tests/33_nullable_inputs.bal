// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
    groups: ["inputs", "input_objects", "nullable_inputs"]
}
isolated function testNullInputForNullableRecord() returns error? {
    string url = "http://localhost:9091/nullable_inputs";
    string document = "{ city(address: null) }";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            city: null
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_objects", "nullable_inputs"]
}
isolated function testNonNullInputForNullableRecord() returns error? {
    string url = "http://localhost:9091/nullable_inputs";
    string document = check getGraphQLDocumentFromFile("non_null_input_for_nullable_record.graphql");
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            city: "Albequerque"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_objects", "nullable_inputs", "list"]
}
isolated function testNullInputForNullableList() returns error? {
    string url = "http://localhost:9091/nullable_inputs";
    string document = "{ cities(addresses: null) }";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            cities: null
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_objects", "nullable_inputs", "list"]
}
isolated function testNonNullInputForNullableList() returns error? {
    string url = "http://localhost:9091/nullable_inputs";
    string document = check getGraphQLDocumentFromFile("non_null_input_for_nullable_list.graphql");
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            cities: ["Albequerque", "Hogwarts"]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_objects", "nullable_inputs", "list"]
}
isolated function testNullInputForNullableRecordField() returns error? {
    string url = "http://localhost:9091/nullable_inputs";
    string document = check getGraphQLDocumentFromFile("null_input_for_nullable_record_field.graphql");
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            accountNumber: 123456
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_objects", "nullable_inputs", "list"]
}
isolated function testNonNullInputForNullableRecordField() returns error? {
    string url = "http://localhost:9091/nullable_inputs";
    string document = check getGraphQLDocumentFromFile("non_null_input_for_nullable_record_field.graphql");
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            accountNumber: 123456
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
