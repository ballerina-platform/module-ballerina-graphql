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
    groups: ["duplicate"],
    dataProvider: dataProviderDuplicateFields
}
isolated function testDuplicateFields(string url, string resourceFileName, string jsonFileName, json variables = (), string? operationName = ()) returns error? {
    string document = check getGraphqlDocumentFromFile(resourceFileName);
    json actualPayload = check getJsonPayloadFromService(url, document, variables, operationName);
    json expectedPayload = check getJsonContentFromFile(jsonFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderDuplicateFields() returns map<[string, string, string, json, string?]> {
    string url1 = "http://localhost:9094/profiles";
    string url2 = "http://localhost:9091/records";
    string url3 = "http://localhost:9091/inputs";
    string url4 = "http://localhost:9091/input_objects";
    string url5 = "http://localhost:9091/list_inputs";

    json var1 = {
        Name: "Ballerina"
    };

    json var2 = {
        day: "SATURDAY",
        weekday: "SATURDAY"
    };

    json var3 = {
        bAuthor: {name: "arthur"}
    };

    map<[string, string, string, json, string?]> dataSet = {
        "1": [url1, "duplicate_fields_with_record_types", "duplicate_fields_with_record_types"],
        "2": [url2, "named_fragments_with_duplicate_fields", "named_fragments_with_duplicate_fields"],
        "3": [url2, "duplicate_inline_fragments", "duplicate_inline_fragments"],
        "4": [url3, "duplicate_fields_with_arguments", "duplicate_fields_with_scalar_args_1", (), "duplicateFieldsWithScalarArgs1"],
        "5": [url3, "duplicate_fields_with_arguments", "duplicate_fields_with_scalar_args_2", var1, "duplicateFieldsWithScalarArgs2"],
        "6": [url3, "duplicate_fields_with_arguments", "duplicate_fields_with_scalar_args_3", (), "duplicateFieldsWithScalarArgs3"],
        "7": [url3, "duplicate_fields_with_arguments", "duplicate_fields_with_enum_args_1", (), "duplicateFieldsWithEnumArgs1"],
        "8": [url3, "duplicate_fields_with_arguments", "duplicate_fields_with_enum_args_2", (), "duplicateFieldsWithEnumArgs2"],
        "9": [url3, "duplicate_fields_with_arguments", "duplicate_fields_with_enum_args_3", var2, "duplicateFieldsWithEnumArgs3"],
        "10": [url4, "duplicate_fields_with_arguments", "duplicate_fields_with_input_object_args_1", (), "duplicateFieldsWithInputObjectArgs1"],
        "11": [url4, "duplicate_fields_with_arguments", "duplicate_fields_with_input_object_args_2", (), "duplicateFieldsWithInputObjectArgs2"],
        "12": [url4, "duplicate_fields_with_arguments", "duplicate_fields_with_input_object_args_3", var3, "duplicateFieldsWithInputObjectArgs3"],
        "13": [url4, "duplicate_fields_with_arguments", "duplicate_fields_with_input_object_args_4", (), "duplicateFieldsWithInputObjectArgs4"],
        "14": [url5, "duplicate_fields_with_arguments", "duplicate_fields_with_list_args_1", (), "duplicateFieldsWithListArgs1"],
        "15": [url5, "duplicate_fields_with_arguments", "duplicate_fields_with_list_args_2", (), "duplicateFieldsWithListArgs2"],
        "16": [url5, "duplicate_fields_with_arguments", "duplicate_fields_with_list_args_3", (), "duplicateFieldsWithListArgs3"]
    };
    return dataSet;
}
