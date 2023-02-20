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
    groups: ["mutations", "validation"],
    dataProvider: dataProviderMutation
}
isolated function testMutationRequestOnNonMutatableSchema(string url, string documentFileName) returns error? {
    string document = check getGraphqlDocumentFromFile(documentFileName);
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(documentFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderMutation() returns string[][] {
    string url1 = "http://localhost:9091/records";
    string url2 = "http://localhost:9091/mutations";

    return [
        [url1, "mutation_request_on_non_mutable_schema"],
        [url2, "mutation"],
        [url2, "multiple_mutations"],
        [url2, "invalid_mutation"],
        [url2, "multiple_mutations_on_service_objects"]
    ];
}
