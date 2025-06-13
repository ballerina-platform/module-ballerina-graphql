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

import ballerina/graphql_test_common as common;
import ballerina/test;

@test:Config {
    groups: ["id_validation"],
    dataProvider: dataProviderIdAnnotation
}
isolated function testIdTypeAnnotation(string resourceFileName, json variables = ()) returns error? {
    string url = "http://localhost:9091/id_annotation_2";
    string document = check common:getGraphqlDocumentFromFile(resourceFileName);
    json actualPayload = check common:getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check common:getJsonContentFromFile(resourceFileName);
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderIdAnnotation() returns map<[string, json]> {
    json values = {
        "ids": ["2.9", "3.3", "4.5"]
    };
    json person = {
        "input": {
            "name": 4
        }
    };
    json nestedIdInput1 = {
        "input": [{
            "id": "5",
            "person": {
                "name": 3
            }
        }]
    };
    json nestedIdInput2 = {
        "input": {
            "id": "55",
            "person": {
                "name": 334
            }
        }
    };
    json idInput = {
        "input": {
            "ids": ["5", "6", "7"],
            "persons": [{
                    "name": 3
                },
                {
                    "name": 4
                },
                {
                    "name": 5
                }
            ]
        }
    };
    json uuidInput = {
        "input": [
            "{\"timeLow\":32377426,\"timeMid\":55867,\"timeHiAndVersion\":6608,\"clockSeqHiAndReserved\":131,\"clockSeqLo\":89,\"node\":143363128380312}",
            "{\"timeLow\":32377426,\"timeMid\":55867,\"timeHiAndVersion\":6608,\"clockSeqHiAndReserved\":131,\"clockSeqLo\":89,\"node\":143363128380312}",
            "uuid"
        ]
    };
    map<[string, json]> dataSet = {
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
        "18": ["id_input_type_validation_return_record"],
        "19": ["id_input_type_validation_float_array1", values],
        "20": ["id_input_validation_with_variable_1", person],
        "21": ["id_input_type_validation_array_1", nestedIdInput1],
        "22": ["id_input_validation_with_variable_2", nestedIdInput2],
        "23": ["id_input_type_validation_array_2", idInput],
        "24": ["id_input_type_validation_array_3"],
        "25": ["id_input_type_validation_string_2"],
        "26": ["id_input_type_validation_float_2"],
        "27": ["id_input_type_validation_decimal_2"],
        "28": ["id_input_type_validation_int_2"],
        "29": ["id_input_type_validation_int_3"],
        "30": ["id_input_type_validation_with_invalid_input_1", {"input": "6.01"}],
        "31": ["id_input_type_validation_with_invalid_input_2"],
        "32": ["id_input_type_validation_with_invalid_input_3", {"input": ["6", "5",  "4.1"]}],
        "33": ["id_input_type_validation_with_invalid_input_4", {"input": ["6.5", "5.523",  "4.4e"]}],
        "34": ["id_input_type_validation_with_invalid_input_5", {"input": "string"}],
        "35": ["id_input_type_validation_with_invalid_input_6", uuidInput],
        "36": ["id_input_type_validation_with_invalid_input_7", {"input": ["5.6", "7.2", "id"]}]
    };
    return dataSet;
}
