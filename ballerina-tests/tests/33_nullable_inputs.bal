// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
    groups: ["inputs", "nullable_inputs"],
    dataProvider: dataProviderNullableInputs
}
isolated function testNullInputForNullableRecord(string documentFileName) returns error? {
    string url = "http://localhost:9091/nullable_inputs";
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderNullableInputs() returns string[][] {
    return [
        ["nullable_input_for_nullable_record"],
        ["non_null_input_for_nullable_record"],
        ["nullable_input_for_nullable_list"],
        ["non_null_input_for_nullable_list"],
        ["null_input_for_nullable_record_field"],
        ["non_null_input_for_nullable_record_field"]
    ];
}
