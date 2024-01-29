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
import ballerina/lang.runtime;

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

@test:Config {
    groups: ["server_cache"]
}
isolated function testServerSideCacheInOperationalLevelWithTTL() returns error? {
    string url = "http://localhost:9091/server_cache_operations";
    string document = check getGraphqlDocumentFromFile("server_cache_with_ttl");
    runtime:sleep(21);
    
    json actualPayload = check getJsonPayloadFromService(url, document, (), "A");
    json expectedPayload = check getJsonContentFromFile("server_cache_1");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);

    actualPayload = check getJsonPayloadFromService(url, document, (), "B");
    expectedPayload = check getJsonContentFromFile("server_cache_10");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);

    actualPayload = check getJsonPayloadFromService(url, document, (), "A");
    expectedPayload = check getJsonContentFromFile("server_cache_1");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);

    runtime:sleep(21);

    actualPayload = check getJsonPayloadFromService(url, document, (), "A");
    expectedPayload = check getJsonContentFromFile("server_cache_9");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

// @test:Config {
//     groups: ["server_cache"]
// }
// isolated function testCachingWithInterceptors() returns error? {
//     string url = "http://localhost:9091/server_cache_interceptor";
//     string resourceFileName = "server_cache_with_interceptors";
//     string document = check getGraphqlDocumentFromFile(resourceFileName);
//     json actualPayload = check getJsonPayloadFromService(url, document, (), "A");
//     json expectedPayload = check getJsonContentFromFile(resourceFileName);
//     io:println("Actual Payload 01: ", actualPayload);
//     expectedPayload = actualPayload;
//     actualPayload = check getJsonPayloadFromService(url, document, (), "B");
//     io:println("Actual Payload 02: ", actualPayload);
//     actualPayload = check getJsonPayloadFromService(url, document, (), "A");
//     io:println("Actual Payload 01: ", actualPayload);
//     assertJsonValuesWithOrder(actualPayload, expectedPayload);
// }

// @test:Config {
//     groups: ["dataloader", "query", "server_cache"],
//     after: resetDispatchCounters
// }
// isolated function testDataLoaderWithCaching() returns error? {
//     graphql:Client graphqlClient = check new ("http://localhost:9091/server_cache_operations");
//     string document = check getGraphqlDocumentFromFile("dataloader_with_query");
//     json response = check graphqlClient->execute(document);
//     json expectedPayload = check getJsonContentFromFile("dataloader_with_query");
//     assertJsonValuesWithOrder(response, expectedPayload);
//     assertDispatchCountForAuthorLoader(1);
//     assertDispatchCountForBookLoader(1);
// }

function dataProviderServerCache() returns map<[string, string[], json, string[]]> {
    map<[string, string[], json, string[]]> dataSet = {
        "1": ["server_cache", ["server_cache_1", "server_cache_2", "server_cache_3"], (), ["A", "B", "A"]],
        "2": ["server_cache_eviction", ["server_cache_2", "server_cache_4"], (), ["B", "A"]],
        "3": ["server_cache_with_records", ["server_cache_with_rec_1", "server_cache_with_rec_2", "server_cache_with_rec_1"], (), ["A", "B", "A"]],
        "4": ["server_cache_with_service_obj", ["server_cache_with_svc_obj_1", "server_cache_with_svc_obj_2", "server_cache_with_svc_obj_1"], (), ["A", "B", "A"]],
        "5": ["server_cache_eviction_with_service_obj", ["server_cache_with_svc_obj_1", "server_cache_with_svc_obj_2", "server_cache_with_svc_obj_3"], (), ["A", "B", "A"]],
        "6": ["server_cache_with_arrays", ["server_cache_with_arrays_1", "server_cache_with_arrays_2", "server_cache_with_arrays_1"], (), ["A", "B", "A"]],
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
        "9": ["server_cache_with_unions_operational_level", ["server_cache_with_unions_1", "server_cache_with_unions_2", "server_cache_with_unions_1"], (), ["A", "B", "A"]],
        "10": ["server_cache_with_unions_operational_level", ["server_cache_with_unions_1", "server_cache_with_unions_2", "server_cache_with_unions_3"], (), ["A", "C", "A"]],
        // "11": ["server_cache_with_max_size", ["server_cache_with_ttl_1", "server_cache_6", "server_cache_7", "server_cache_8", "server_cache_with_ttl_1"], (), ["A", "B", "C", "D", "A"]],
        "11": ["server_cache_eviction", ["server_cache_2", "server_cache_4", "server_cache_5", "server_cache_4"], (), ["B", "A", "C", "A"]],
        // "12": ["server_cache_nullable_inputs", ["server_cache_with_nullable_inputs", "server_cache_with_nullable_inputs"], (), ["A", "B"]]
        "13": ["server_cache_with_inputs", ["server_cache_with_nullable_inputs_2", "server_cache_with_nullable_inputs_2"], (), ["B", "C"]],
        "14": ["server_cache_with_inputs", ["server_cache_with_empty_input_1", "server_cache_with_empty_input_2"], (), ["B", "D"]],
        "15": ["server_cache_with_partial_responses", ["server_cache_with_partial_reponses_1", "server_cache_with_partial_reponses_2", "server_cache_with_partial_reponses_1"], (), ["A", "B", "A"]],
        "16": ["server_cache_with_partial_responses", ["server_cache_with_partial_reponses_1", "server_cache_with_partial_reponses_2", "server_cache_with_partial_reponses_3"], (), ["A", "C", "A"]],
        "17": ["server_cache_with_errors", ["server_cache_with_errors_1", "server_cache_with_errors_2", "server_cache_with_errors_3"], (), ["A", "B", "A"]]
    };
    return dataSet;
}
