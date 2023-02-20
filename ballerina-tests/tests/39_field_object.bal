// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
    groups: ["field-object"],
    dataProvider: dataProviderFieldObject
}
function testFieldObject(string url, string documentFileName, string jsonFileName, string operationName) returns error? {
    string document = check getGraphqlDocumentFromFile(documentFileName);
    json actualPayload = check getJsonPayloadFromService(url, document, operationName = operationName);
    json expectedPayload = check getJsonContentFromFile(jsonFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderFieldObject() returns string[][] {

    string url1 = "localhost:9092/service_types";
    string url2 = "localhost:9092/service_objects";

    return [
        [url1, "field_object", "field_object", "QueryName"],
        [url1, "field_object", "field_object_with_multiple_args", "QueryNameAndAge"],
        [url1, "field_object", "field_object_with_multiple_args", "QueryNameAndAgeWithFragments"],
        [url2, "field_object_parameter_order", "field_object_parameter_order1", "FieldObjectParameterOrder1"],
        [url2, "field_object_parameter_order", "field_object_parameter_order2", "FieldObjectParameterOrder2"]
    ];
}
