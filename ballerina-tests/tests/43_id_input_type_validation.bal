// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com).
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
    groups: ["id_validation"],
    dataProvider: dataProviderIdAnnotation
}
isolated function testIdTypeAnnotation(string resourceFileName) returns error? {
    string url = "http://localhost:9091/id_annotation_2";
    string document = check getGraphqlDocumentFromFile(resourceFileName);
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(resourceFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderIdAnnotation() returns map<[string]> {
    map<[string]> dataSet = {
        "1": ["id_input_type_validation_string"],
        "2": ["id_input_type_validation_int"],
        "3": ["id_input_type_validation_float"],
        "4": ["id_input_type_validation_decimal"],
        "5": ["id_input_type_validation_string_or_nil"],
        "6": ["id_input_type_validation_int_or_nil"],
        "7": ["id_input_type_validation_float_or_nil"],
        "8": ["id_input_type_validation_decimal_or_nil"],
        "9": ["id_input_type_validation_int1"],
        "10": ["id_input_type_validation_int_array"],
        "11": ["id_input_type_validation_string_array"],
        "12": ["id_input_type_validation_float_array"],
        "13": ["id_input_type_validation_decimal_array"],
        "14": ["id_input_type_validation_uuid"],
        "15": ["id_input_type_validation_uuid_array"],
        "16": ["id_input_type_validation_uuid_array_or_nil"],
        "17": ["id_input_type_validation_return_record_array"],
        "18": ["id_input_type_validation_return_record"]
    };
    return dataSet;
}
