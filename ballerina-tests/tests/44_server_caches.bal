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

@test:Config {
    groups: ["server_cache"],
    dataProvider: dataProviderServerCacheOperationalLevel
}
isolated function testServerSideCacheInOperationalLevel(string documentFile, string[] resourceFileNames, json variables = (), string[] operationNames = []) returns error? {
    string url = "http://localhost:9091/server_cache_operations";
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
        "7": ["server_cache_eviction_with_arrays", ["server_cache_with_arrays_1", "server_cache_with_arrays_2", "server_cache_with_arrays_4"], (), ["A", "B", "A"]]
    };
    return dataSet;
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
    };
    return dataSet;
}
