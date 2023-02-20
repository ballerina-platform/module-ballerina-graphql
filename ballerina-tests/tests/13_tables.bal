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
    groups: ["tables"],
    dataProvider: dataProviderTables
}
isolated function testTables(string url, string documentFileName) returns error? {
    string document = check getGraphqlDocumentFromFile(documentFileName);
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(documentFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderTables() returns string[][] {
    string url1 = "http://localhost:9091/tables";
    string url2 = "http://localhost:9091/covid19";

    return [
        [url1, "resource_returning_tables"],
        [url1, "querying_table_without_selections"],
        [url2, "resolver_returning_tables"]
    ];
}
