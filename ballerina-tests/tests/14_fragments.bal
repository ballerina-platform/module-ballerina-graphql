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
    groups: ["fragments", "validation"],
    dataProvider: dataProviderFragments
}
isolated function testFragments(string url, string resourceFileName) returns error? {
    string document = check getGraphqlDocumentFromFile(resourceFileName);
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(resourceFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderFragments() returns string[][] {
    string url1 = "http://localhost:9091/records";
    string url2 = "http://localhost:9092/service_types";
    string url3 = "http://localhost:9092/service_objects";

    return [
        [url1, "fragment_on_invalid_type"],
        [url1, "fragment_with_invalid_field"],
        [url1, "fragments_on_record_objects"],
        [url1, "nested_fragments"],
        [url1, "fragments_with_multiple_resource_invocation"],
        [url1, "fragments_with_invalid_introspection"],
        [url1, "fragments_with_introspection"],
        [url2, "fragments_querying_service_objects"],
        [url1, "inline_fragment"],
        [url1, "unknown_inline_fragment"],
        [url1, "invalid_spread_inline_fragments"],
        [url3, "fragments_inside_fragments_when_returning_services"],
        [url3, "nested_fragments_querying_service_objects_with_multiple_fields"]
    ];
}
