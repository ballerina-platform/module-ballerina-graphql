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
    groups: ["records"],
    dataProvider: dataProviderRecordObjects
}
isolated function testRecordObjects(string documentFileName) returns error? {
    string url = "http://localhost:9091/records";
    string document = check getGraphqlDocumentFromFile(documentFileName);
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(documentFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderRecordObjects() returns string[][] {
    return [
        ["ballerina_record_as_graphql_object"],
        ["inline_fragments_on_record_objects"],
        ["inline_nested_fragments_on_record_objects"],
        ["requesting_object_without_fields"],
        ["request_invalid_field"],
        ["record_type_arrays"],
        ["resource_returning_arrays_missing_fields"],
        ["nested_records_array"]
    ];
}
