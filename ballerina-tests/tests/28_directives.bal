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
    groups: ["directives"],
    dataProvider: dataProviderDirectives
}
isolated function testDirectives(string url, string documentFileName, json variables) returns error? {
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderDirectives() returns map<[string, string, json]> {
    string url1 = "http://localhost:9092/service_types";
    string url2 = "http://localhost:9091/records";
    string url3 = "http://localhost:9092/service_objects";

    map<[string, string, json]> dataSet = {
        "1": [url1, "directives"],
        "2": [url2, "directives_with_variables_and_fragments", { optional: false  }],
        "3": [url2, "directives_with_duplicate_fields", { optional: false }],
        "4": [url3, "directives_with_service_returning_objects_array"],
        "5": [url2, "multiple_directive_usage_in_fields"],
        "6": [url2, "directives_skip_all_selections"]
    };
    return dataSet;
}
