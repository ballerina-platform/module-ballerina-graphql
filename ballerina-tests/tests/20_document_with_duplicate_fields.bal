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
    groups: ["duplicate"],
    dataProvider: dataProviderDuplicateFields
}
isolated function testDuplicateFields(string url, string resourceFileName) returns error? {
    string document = check getGraphqlDocumentFromFile(resourceFileName);
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(resourceFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderDuplicateFields() returns string[][] {
    string url1 = "http://localhost:9094/profiles";
    string url2 = "http://localhost:9091/records";

    return [
        [url1, "duplicate_fields_with_record_types"],
        [url2, "named_fragments_with_duplicate_fields"],
        [url2, "duplicate_inline_fragments"]
    ];
}
