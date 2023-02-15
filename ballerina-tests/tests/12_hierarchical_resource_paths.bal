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
    groups: ["hierarchical_paths"],
    dataProvider: dataProviderHierarchicalResourcePaths
}
isolated function testHierarchicalResourcePaths(string url, string documentFileName) returns error? {
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderHierarchicalResourcePaths() returns string[][] {
    string url1 = "http://localhost:9094/profiles";
    string url2 = "http://localhost:9094/snowtooth";
    string url3 = "http://localhost:9094/hierarchical";

    return [
        [url1, "hierarchical_resource_paths"],
        [url1, "hierarchical_resource_paths_with_multiple_fields"],
        [url1, "hierarchical_resource_paths_complete"],
        [url1, "hierarchical_paths_same_type_in_multiple_paths"],
        [url1, "invalid_hierarchical_resource_paths"],
        [url1, "hierarchical_resource_paths_introspection"],
        [url2, "hierarchical_resource_paths_with_same_field_repeating_1"],
        [url2, "hierarchical_resource_paths_with_same_field_repeating_2"],
        [url3, "hierarchical_resource_paths_returning_services_with_hierarchical_resource_path"],
        [url1, "hierarchical_resource_paths_with_fragments"]
    ];
}
