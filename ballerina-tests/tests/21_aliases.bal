// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
    groups: ["alias"],
    dataProvider: dataProviderAliases
}
isolated function testAlias(string url, string documentFileName) returns error? {
    string document = check getGraphqlDocumentFromFile(documentFileName);
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(documentFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderAliases() returns string[][] {
    string url1 = "http://localhost:9094/profiles";
    string url2 = "http://localhost:9091/records";
    string url3 = "http://localhost:9092/unions";

    return [
        [url1, "alias"],
        [url2, "same_field_with_multiple_alias"],
        [url2, "same_field_with_multiple_alias_different_subfields"],
        [url2, "alias_with_invalid_field_name"],
        [url3, "alias_on_service_objects_union"],
        [url1, "alias_on_hierarchical_resources"]
    ];
}
