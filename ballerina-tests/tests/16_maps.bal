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
    groups: ["maps"],
    dataProvider: dataProviderMaps
}
isolated function testMap(string url, string documentFileName, json variables = ()) returns error? {
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderMaps() returns map<[string, string, json]> {
    string url1 = "http://localhost:9095/special_types";
    string url2 = "http://localhost:9091/maps";
    string url3 = "http://localhost:9090/reviews";

    map<[string, string, json ]> dataSet = {
        "1": [url1, "map"],
        "2": [url1, "nested_map"],
        "3": [url1, "map_without_key_input"],
        "4": [url1, "nested_map_without_key_input"],
        "5": [url2, "map_with_valid_key", {purpose: "backend"}],
        "6": [url2, "map_with_invalid_key", {purpose: "desktop"}],
        "7": [url3, "resolver_returning_map_of_service_objects"]
    };
    return dataSet;
}
