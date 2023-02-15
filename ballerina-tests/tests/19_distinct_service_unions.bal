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
    groups: ["service", "union"],
    dataProvider: dataProviderDistinctServiceObjects
}
isolated function testUnionOfDistinctServiceObjects(string url, string documentFileName) returns error? {
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderDistinctServiceObjects() returns string[][] {
    string url1 = "http://localhost:9092/unions";
    string url2 = "http://localhost:9092/union_type_names";

    return [
        [url1, "union_of_distinct_service_objects"],
        [url1, "invalid_query_with_distinct_service_unions"],
        [url1, "union_of_distinct_services_query_on_selected_types"],
        [url1, "union_of_distinct_services_array_query_on_selected_types"],
        [url1, "union_of_distinct_services_array_query_on_selected_types_fragment_on_root"],
        [url1, "union_types_with_field_returning_enum"],
        [url1, "union_types_with_nested_object_includes_field_returning_enum"],
        [url1, "nullable_union_of_distinct_services_array_query_on_selected_types"],
        [url2, "union_type_names"]
    ];
}
