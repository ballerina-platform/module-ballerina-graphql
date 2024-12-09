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
import ballerina/test;

@test:Config {
    groups: ["server_cache", "data_loader"],
    dataProvider: dataProviderServerCacheWithDataloader
}
isolated function testServerSideCacheWithDataLoader(string documentFile, string[] resourceFileNames, json variables = (), string[] operationNames = []) returns error? {
    string url = "http://localhost:9090/caching_with_dataloader";
    string document = check common:getGraphqlDocumentFromFile(documentFile);
    foreach int i in 0 ..< resourceFileNames.length() {
        json actualPayload = check common:getJsonPayloadFromService(url, document, variables, operationNames[i]);
        json expectedPayload = check common:getJsonContentFromFile(resourceFileNames[i]);
        common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
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
    dataProvider: dataProviderServerCacheWithDataloaderInOperationalLevel
}
isolated function testServerSideCacheWithDataLoaderInOperationalLevel(string documentFile, string[] resourceFileNames, json variables = (), string[] operationNames = []) returns error? {
    string url = "http://localhost:9090/caching_with_dataloader_operational";
    string document = check common:getGraphqlDocumentFromFile(documentFile);
    foreach int i in 0 ..< resourceFileNames.length() {
        json actualPayload = check common:getJsonPayloadFromService(url, document, variables, operationNames[i]);
        json expectedPayload = check common:getJsonContentFromFile(resourceFileNames[i]);
        common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
    }
    resetDispatchCounters();
}

function dataProviderServerCacheWithDataloaderInOperationalLevel() returns map<[string, string[], json, string[]]> {
    map<[string, string[], json, string[]]> dataSet = {
        "1": ["server_cache_with_dataloader_operational", ["server_cache_with_dataloader_3", "server_cache_with_dataloader_5", "server_cache_with_dataloader_3"], (), ["A", "B", "A"]],
        "2": ["server_cache_eviction_with_dataloader_operational", ["server_cache_with_dataloader_3", "server_cache_with_dataloader_5", "server_cache_with_dataloader_4"], (), ["A", "B", "A"]]
    };
    return dataSet;
}
