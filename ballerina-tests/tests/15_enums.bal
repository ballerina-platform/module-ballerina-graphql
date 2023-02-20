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
    groups: ["enums"],
    dataProvider: dataProviderEnums
}
isolated function testEnum(string documentFileName, json variables = ()) returns error? {
    string url = "http://localhost:9095/special_types";
    string document = check getGraphqlDocumentFromFile(documentFileName);
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile(documentFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderEnums() returns map<[string, json]> {
    map<[string, json]> dataSet = {
        "1": ["enum"],
        "2": ["enum_inside_record"],
        "3": ["enum_introspection"],
        "4": ["enum_with_union"],
        "5": ["enum_input_parameter"],
        "6": ["returning_enum_array"],
        "7": ["returning_enum_array_with_errors"],
        "8": ["returning_nullable_enum_array_with_errors"],
        "9": ["enum_invalid_input_parameter"],
        "10": ["enum_input_parameter_as_string"],
        "11": ["enum_with_values_assigned"],
        "12": ["enum_with_values_assigned_using_variables", {month: "MAY"}]
    };
    return dataSet;
}
