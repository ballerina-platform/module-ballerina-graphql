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

import ballerina/test;

@test:Config {
    groups: ["server_cache"],
    dataProvider: dataProviderServerCache
}
isolated function testServerSideCache(string documentFile, string[] resourceFileNames, json variables = (), string[] operationNames = []) returns error? {
    string url = "http://localhost:9091/server_cache";
    string document = check getGraphqlDocumentFromFile(documentFile);
    foreach int i in 0..<resourceFileNames.length() {
        json actualPayload = check getJsonPayloadFromService(url, document, variables, operationNames[i]);
        json expectedPayload = check getJsonContentFromFile(resourceFileNames[i]);
        assertJsonValuesWithOrder(actualPayload, expectedPayload);
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
    groups: ["server_cache", "data_loader"],
    dataProvider: dataProviderServerCacheWithDataloader
}
isolated function testServerSideCacheWithDataLoader(string documentFile, string[] resourceFileNames, json variables = (), string[] operationNames = []) returns error? {
    string url = "http://localhost:9090/caching_with_dataloader";
    string document = check getGraphqlDocumentFromFile(documentFile);
    foreach int i in 0..< resourceFileNames.length() {
        json actualPayload = check getJsonPayloadFromService(url, document, variables, operationNames[i]);
        json expectedPayload = check getJsonContentFromFile(resourceFileNames[i]);
        assertJsonValuesWithOrder(actualPayload, expectedPayload);
    }
    resetDispatchCounters();
}

function dataProviderServerCacheWithDataloader() returns map<[string, string[], json, string[]]> {
    map<[string, string[], json, string[]]> dataSet = {
        "1": ["server_cache_with_dataloader", ["server_cache_with_dataloader_1", "server_cache_with_dataloader_2", "server_cache_with_dataloader_1"], (), ["A", "B", "A"]],
        "2": ["server_cache_eviction_with_dataloader", ["server_cache_with_dataloader_1", "server_cache_with_dataloader_2", "server_cache_with_dataloader_3"], (), ["A", "B", "A"]]
    };
    return dataSet;
}

@test:Config {
    groups: ["server_cache", "data_loader"],
    dataProvider: dataProviderServerCacheWithInterceptors
}
isolated function testServerSideCacheWithInterceptors(string documentFile, string[] resourceFileNames, json variables = (), string[] operationNames = []) returns error? {
    string url = "http://localhost:9091/field_caching_with_interceptors";
    string document = check getGraphqlDocumentFromFile(documentFile);
    foreach int i in 0..< resourceFileNames.length() {
        json actualPayload = check getJsonPayloadFromService(url, document, variables, operationNames[i]);
        json expectedPayload = check getJsonContentFromFile(resourceFileNames[i]);
        assertJsonValuesWithOrder(actualPayload, expectedPayload);
    }
}

function dataProviderServerCacheWithInterceptors() returns map<[string, string[], json, string[]]> {
    map<[string, string[], json, string[]]> dataSet = {
        "1": ["server_cache_with_interceptors", ["server_cache_with_interceptors_1", "server_cache_with_interceptors_2", "server_cache_with_interceptors_1"], (), ["A", "B", "A"]],
        "2": ["server_cache_eviction_with_interceptors", ["server_cache_with_interceptors_1", "server_cache_with_interceptors_2", "server_cache_with_interceptors_3"], (), ["A", "B", "A"]]
    };
    return dataSet;
}
