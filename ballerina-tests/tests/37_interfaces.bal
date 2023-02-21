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
    groups: ["interfaces"],
    dataProvider: dataProviderInterface
}
isolated function testInterfaces(string url, string resourceFileName) returns error? {
    string document = check getGraphqlDocumentFromFile(resourceFileName);
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(resourceFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderInterface() returns string[][] {
    string url1 = "http://localhost:9098/interfaces";
    string url2 = "http://localhost:9089/interfaces_implementing_interface";

    return [
        [url1, "interfaces"],
        [url1, "interface_introspection"],
        [url1, "interface_field"],
        [url1, "interfaces_with_nested_fragments"],
        [url1, "interfaces_with_invalid_field"],
        [url1, "interfaces_with_type_name_introspection"],
        [url1, "interfaces_with_interface_type_array"],
        [url2, "test_quering_on_interface"],
        [url2, "test_querying_on_transitive_type"],
        [url2, "test_querying_on_transitive_type_and_interface"],
        [url2, "test_querying_fragment_on_transitive_interface"],
        [url2, "interfaces_implementing_interface_introsepction"]
    ];
}
