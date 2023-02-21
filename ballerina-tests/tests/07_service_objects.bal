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
    groups: ["service"],
    dataProvider: dataProviderServiceObjects
}
isolated function testServiceObject(string url, string resourceFileName) returns error? {
    string document = check getGraphqlDocumentFromFile(resourceFileName);
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(resourceFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderServiceObjects() returns string[][] {
    string url1 = "http://localhost:9092/service_types";
    string url2 = "http://localhost:9090/reviews";

    return [
        [url1, "resource_returning_service_object"],
        [url1, "invalid_query_from_service_object_resource"],
        [url1, "complex_service"],
        [url2, "service_object_defined_as_record_field"],
        [url2, "resolver_returning_list_of_nested_service_objects"],
        [url2, "resolver_returning_table_of_nested_service_objects"]
    ];
}
