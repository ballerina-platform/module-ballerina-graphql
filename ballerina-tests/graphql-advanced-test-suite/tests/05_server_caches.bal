// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com).
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

import ballerina/graphql_test_common as common;
import ballerina/lang.runtime;
import ballerina/test;

@test:Config {
    groups: ["server_cache"],
    dataProvider: dataProviderServerCache
}
isolated function testServerSideCache(string documentFile, string[] resourceFileNames, json variables = (), string[] operationNames = []) returns error? {
    string url = "http://localhost:9090/server_cache";
    string document = check common:getGraphqlDocumentFromFile(documentFile);
    foreach int i in 0 ..< resourceFileNames.length() {
        json actualPayload = check common:getJsonPayloadFromService(url, document, variables, operationNames[i]);
        json expectedPayload = check common:getJsonContentFromFile(resourceFileNames[i]);
        common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
    }
}

function dataProviderServerCache() returns map<[string, string[], json, string[]]> {
    map<[string, string[], json, string[]]> dataSet = {
        "1": ["server_cache", ["server_cache_1", "server_cache_2", "server_cache_3"], (), ["A", "B", "A"]],
        "2": ["server_cache_eviction", ["server_cache_2", "server_cache_4"], (), ["B", "A"]],
        "3": ["server_cache_with_records", ["server_cache_with_rec_1", "server_cache_with_rec_2", "server_cache_with_rec_1"], (), ["A", "B", "A"]],
        "4": ["server_cache_with_service_obj", ["server_cache_with_svc_obj_1", "server_cache_with_svc_obj_2", "server_cache_with_svc_obj_1"], (), ["A", "B", "A"]],
        "5": ["server_cache_eviction_with_service_obj", ["server_cache_with_svc_obj_1", "server_cache_with_svc_obj_2", "server_cache_with_svc_obj_3"], (), ["A", "B", "A"]],
        "6": ["server_cache_with_arrays", ["server_cache_with_arrays_1", "server_cache_with_arrays_2", "server_cache_with_arrays_3"], (), ["A", "B", "A"]],
        "7": ["server_cache_eviction_with_arrays", ["server_cache_with_arrays_1", "server_cache_with_arrays_2", "server_cache_with_arrays_4"], (), ["A", "B", "A"]],
        "8": ["server_cache_with_union", ["server_cache_with_union_1", "server_cache_with_union_2", "server_cache_with_union_1"], (), ["A", "B", "A"]],
        "9": ["server_cache_eviction_with_union", ["server_cache_with_union_1", "server_cache_with_union_3", "server_cache_with_union_4"], (), ["A", "B", "A"]],
        "10": ["server_cache_with_errors", ["server_cache_with_errors_1", "server_cache_with_errors_2"], (), ["A", "B"]],
        "11": ["server_cache_with_nullable_inputs", ["server_cache_with_nullable_inputs_1", "server_cache_with_nullable_inputs_2", "server_cache_with_nullable_inputs_1"], (), ["A", "B", "A"]],
        "12": ["server_cache_eviction_with_nullable_inputs", ["server_cache_eviction_with_nullable_inputs_1", "server_cache_eviction_with_nullable_inputs_2", "server_cache_eviction_with_nullable_inputs_3"], (), ["A", "B", "A"]],
        "13": ["server_cache_with_list_inputs", ["server_cache_eviction_with_list_inputs_1", "server_cache_eviction_with_list_inputs_2", "server_cache_eviction_with_list_inputs_1"], {"names": ["Enemy3"]}, ["A", "B", "A"]],
        "14": ["server_cache_eviction_with_list_inputs", ["server_cache_eviction_with_list_inputs_1", "server_cache_eviction_with_list_inputs_2", "server_cache_eviction_with_list_inputs_3"], {"names": ["Enemy3"]}, ["A", "B", "A"]],
        "15": ["server_cache_with_null_values", ["server_cache_with_null_values_1", "server_cache_with_null_values_2", "server_cache_with_null_values_3"], (), ["A", "B", "A"]],
        "16": ["server_cache_with_input_object", ["server_cache_with_input_object_1", "server_cache_with_input_object_2", "server_cache_with_input_object_3"], (), ["A", "B", "A"]]
    };
    return dataSet;
}

@test:Config {
    groups: ["server_cache"],
    dataProvider: dataProviderServerCacheOperationalLevel
}
isolated function testServerSideCacheInOperationalLevel(string documentFile, string[] resourceFileNames, json variables = (), string[] operationNames = []) returns error? {
    string url = "http://localhost:9090/server_cache_operations";
    string document = check common:getGraphqlDocumentFromFile(documentFile);
    foreach int i in 0 ..< resourceFileNames.length() {
        json actualPayload = check common:getJsonPayloadFromService(url, document, variables, operationNames[i]);
        json expectedPayload = check common:getJsonContentFromFile(resourceFileNames[i]);
        common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
    }
}

function dataProviderServerCacheOperationalLevel() returns map<[string, string[], json, string[]]> {
    map<[string, string[], json, string[]]> dataSet = {
        "1": ["server_cache", ["server_cache_1", "server_cache_2", "server_cache_1"], (), ["A", "B", "A"]],
        "2": ["server_cache_eviction", ["server_cache_2", "server_cache_4"], (), ["B", "A"]],
        "3": ["server_cache_with_records_operations", ["server_cache_with_rec_1", "server_cache_with_rec_3", "server_cache_with_rec_1"], (), ["A", "B", "A"]],
        "4": ["server_cache_with_records_eviction", ["server_cache_with_rec_1", "server_cache_with_rec_5", "server_cache_with_rec_4"], (), ["A", "B", "A"]],
        "5": ["server_cache_with_service_obj", ["server_cache_with_svc_obj_1", "server_cache_with_svc_obj_2", "server_cache_with_svc_obj_1"], (), ["A", "B", "A"]],
        "6": ["server_cache_eviction_with_service_obj", ["server_cache_with_svc_obj_1", "server_cache_with_svc_obj_2", "server_cache_with_svc_obj_3"], (), ["A", "B", "A"]],
        "7": ["server_cache_with_arrays", ["server_cache_with_arrays_5", "server_cache_with_arrays_2", "server_cache_with_arrays_5"], (), ["A", "B", "A"]],
        "8": ["server_cache_eviction_with_arrays", ["server_cache_with_arrays_7", "server_cache_with_arrays_2", "server_cache_with_arrays_6"], (), ["A", "B", "A"]],
        "9": ["server_cache_with_unions_operational_level", ["server_cache_with_unions_1", "server_cache_with_unions_2", "server_cache_with_unions_1"], (), ["A", "B", "A"]],
        "10": ["server_cache_with_unions_operational_level", ["server_cache_with_unions_1", "server_cache_with_unions_2", "server_cache_with_unions_3"], (), ["A", "C", "A"]],
        "11": ["server_cache_eviction", ["server_cache_2", "server_cache_4", "server_cache_5", "server_cache_4"], (), ["B", "A", "C", "A"]],
        "12": ["server_cache_with_inputs", ["server_cache_with_nullable_inputs_7", "server_cache_with_nullable_inputs_8"], (), ["B", "C"]],
        "13": ["server_cache_with_inputs", ["server_cache_with_empty_input_1", "server_cache_with_empty_input_2"], (), ["B", "D"]],
        "14": ["server_cache_with_partial_responses", ["server_cache_with_partial_reponses_1", "server_cache_with_partial_reponses_2", "server_cache_with_partial_reponses_1"], (), ["A", "B", "A"]],
        "15": ["server_cache_with_partial_responses", ["server_cache_with_partial_reponses_1", "server_cache_with_partial_reponses_2", "server_cache_with_partial_reponses_3"], (), ["A", "C", "A"]],
        "16": ["server_cache_with_errors_2", ["server_cache_with_errors_4", "server_cache_with_errors_5", "server_cache_with_errors_3"], (), ["A", "B", "A"]]
    };
    return dataSet;
}

@test:Config {
    groups: ["server_cache"]
}
isolated function testServerSideCacheInOperationalLevelWithTTL() returns error? {
    string url = "http://localhost:9090/server_cache_operations";
    string document = check common:getGraphqlDocumentFromFile("server_cache_operations_with_TTL");
    runtime:sleep(21);

    json actualPayload = check common:getJsonPayloadFromService(url, document, (), "A");
    json expectedPayload = check common:getJsonContentFromFile("server_cache_1");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);

    actualPayload = check common:getJsonPayloadFromService(url, document, (), "B");
    expectedPayload = check common:getJsonContentFromFile("server_cache_10");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);

    actualPayload = check common:getJsonPayloadFromService(url, document, (), "A");
    expectedPayload = check common:getJsonContentFromFile("server_cache_1");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);

    runtime:sleep(21);

    actualPayload = check common:getJsonPayloadFromService(url, document, (), "A");
    expectedPayload = check common:getJsonContentFromFile("server_cache_9");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["server_cache"]
}
isolated function testCachingRecordWithoutNonOptionalFields() returns error? {
    string url = "http://localhost:9090/server_cache_records_with_non_optional";
    string document = check common:getGraphqlDocumentFromFile("server_cache_records_with_non_optional_fields_1");

    json actualPayload = check common:getJsonPayloadFromService(url, document, (), "GetProfiles");
    json expectedPayload = check common:getJsonContentFromFile("server_cache_records_with_non_optional_fields_1");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);

    _ = check common:getJsonPayloadFromService(url, document, {enableEvict: false}, "RemoveProfiles");

    actualPayload = check common:getJsonPayloadFromService(url, document, (), "GetProfiles");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);

    document = check common:getGraphqlDocumentFromFile("server_cache_records_with_non_optional_fields_2");
    actualPayload = check common:getJsonPayloadFromService(url, document, (), "GetProfiles");
    expectedPayload = check common:getJsonContentFromFile("server_cache_records_with_non_optional_fields_2");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);

    _ = check common:getJsonPayloadFromService(url, document, {enableEvict: true}, "RemoveProfiles");

    actualPayload = check common:getJsonPayloadFromService(url, document, (), "GetProfiles");
    expectedPayload = check common:getJsonContentFromFile("server_cache_records_with_non_optional_fields_3");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["server_cache"]
}
isolated function testServerCacheEvictionWithTTL() returns error? {
    string url = "http://localhost:9090/field_caching_with_ttl";
    string document = check common:getGraphqlDocumentFromFile("server_cache_fields_with_TTL");

    json actualPayload = check common:getJsonPayloadFromService(url, document, (), "A");
    json expectedPayload = check common:getJsonContentFromFile("server_cache_eviction_with_TTL_1");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);

    actualPayload = check common:getJsonPayloadFromService(url, document, {"name": "Potter"}, "B");
    expectedPayload = check common:getJsonContentFromFile("server_cache_eviction_with_TTL_2");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);

    actualPayload = check common:getJsonPayloadFromService(url, document, (), "A");
    expectedPayload = check common:getJsonContentFromFile("server_cache_eviction_with_TTL_1");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);

    runtime:sleep(11);

    actualPayload = check common:getJsonPayloadFromService(url, document, (), "A");
    expectedPayload = check common:getJsonContentFromFile("server_cache_eviction_with_TTL_3");
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["server_cache", "records"],
    dataProvider: dataProviderServerSideCacheWithDynamicResponse
}
isolated function testServerSideCacheWithDynamicResponse(string documentFile, string[] resourceFileNames, json variables = (), string[] operationNames = []) returns error? {
    string url = "http://localhost:9090/dynamic_response";
    string document = check common:getGraphqlDocumentFromFile(documentFile);
    foreach int i in 0 ..< resourceFileNames.length() {
        json actualPayload = check common:getJsonPayloadFromService(url, document, variables, operationNames[i]);
        json expectedPayload = check common:getJsonContentFromFile(resourceFileNames[i]);
        common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
    }
}

function dataProviderServerSideCacheWithDynamicResponse() returns map<[string, string[], json, string[]]> {
    map<[string, string[], json, string[]]> dataSet = {
        "1": ["server_cache_with_dynamic_responses", ["server_cache_with_dynamic_responses_1", "server_cache_with_dynamic_responses_2", "server_cache_with_dynamic_responses_3"], (), ["A", "B", "C"]],
        "2": ["server_cache_with_dynamic_responses", ["server_cache_with_dynamic_responses_2", "server_cache_with_dynamic_responses_4", "server_cache_with_dynamic_responses_2"], (), ["B", "D", "B"]],
        "3": ["server_cache_with_dynamic_responses", ["server_cache_with_dynamic_responses_3", "server_cache_with_dynamic_responses_4", "server_cache_with_dynamic_responses_3"], (), ["C", "D", "C"]],
        "4": ["server_cache_with_dynamic_responses", ["server_cache_with_dynamic_responses_3", "server_cache_with_dynamic_responses_4", "server_cache_with_dynamic_responses_5"], (), ["C", "E", "C"]],
        "5": ["server_cache_with_dynamic_responses", ["server_cache_with_dynamic_responses_6", "server_cache_with_dynamic_responses_7", "server_cache_with_dynamic_responses_8"], (), ["B", "F", "B"]]
    };
    return dataSet;
}

@test:Config {
    groups: ["server_cache"],
    dataProvider: dataProviderServerCacheWithListInput
}
isolated function testServerCacheWithListInput(string documentFile, string[] resourceFileNames, json variables = (), string[] operationNames = []) returns error? {
    string url = "http://localhost:9090/cache_with_list_input";
    string document = check common:getGraphqlDocumentFromFile("server_cache_with_list_input");

    foreach int i in 0 ..< resourceFileNames.length() {
        json actualPayload = check common:getJsonPayloadFromService(url, document, variables, operationNames[i]);
        json expectedPayload = check common:getJsonContentFromFile(resourceFileNames[i]);
        common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
    }
}

function dataProviderServerCacheWithListInput() returns map<[string, string[], json, string[]]> {
    map<[string, string[], json, string[]]> dataSet = {
        "1": ["server_cache_with_list_input", ["server_cache_with_list_input_1", "server_cache_with_list_input_2", "server_cache_with_list_input_3", "server_cache_with_list_input_1"], (), ["A", "B", "G", "A"]],
        "2": ["server_cache_with_list_input", ["server_cache_with_list_input_4", "server_cache_with_list_input_5", "server_cache_with_list_input_6", "server_cache_with_list_input_4"], (), ["D", "H", "E", "D"]],
        "3": ["server_cache_with_list_input", ["server_cache_with_list_input_7", "server_cache_with_list_input_8", "server_cache_with_list_input_7"], (), ["F", "I", "F"]]
    };
    return dataSet;
}
