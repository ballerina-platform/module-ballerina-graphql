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
    groups: ["list", "input"],
    dataProvider: dataProviderListTypeInput
}
isolated function testListTypeInput(string documentFileName, json variables = ()) returns error? {
    string url = "http://localhost:9091/list_inputs";
    string document = check getGraphQLDocumentFromFile(appendGraphqlExtension(documentFileName));
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile(appendJsonExtension(documentFileName));
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderListTypeInput() returns map<[string, json]> {
    json var1 = {
        series1: {
            name: "Michael",
            episodes: [
                {
                    title: "ep1",
                    newCharacters: ["Sherlock", "Sara"]
                }
            ]
        }
    };

    json var2 = {
        tvSeries: [
            {
                name: "Breaking Bad",
                episodes: [
                    {
                        title:"ep1"
                    }
                ]
            }
        ]
    };

    json var3 = {
        tvSeries: [
            {
                name: "Breaking Bad",
                episodes: [
                    {
                        title:"ep1"
                    }
                ]
            },
            {
                name: "Breaking Bad",
                episodes:true
            }
        ]
    };

    json var4 = {
        tvSeries: [
            {
                name: "GOT",
                episodes: [
                    {
                        title:"ep1",
                        newCharacters: ["Sherlock", "Jessie"]
                    },
                    {
                        title:"ep2",
                        newCharacters: ["Michael", "Jessie"]
                    }
                ]
            }
        ]
    };

    json var5 = {
        tvSeries: [
            {
                name: "GOT",
                episodes: [
                    {
                        title:"ep1",
                        newCharacters: ["Sherlock", "Jessie"]
                    },
                    {
                        title:"ep2",
                        newCharacters: [true, 1]
                    }
                ]
            }
        ]
    };

    json var6 = {
        tvSeries:{
            name: "Braking Bad",
            episodes: [
                {
                    title:"Cancer Man",
                    newCharacters: ["Sherlock", "Jessie"]
                }
            ]
        }
    };

    json var7 = {
        tvSeries: {
            name: "Breaking Bad",
            episodes: [
                {
                    title:"Cancer Man",
                    newCharacters:[]
                }
            ]
        }
    };

    json var8 = {
        tvSeries: {
            name: "Breaking Bad",
            episodes: [
                {
                    title:"Cancer Man",
                    newCharacters: [true, 44]
                }
            ]
        }
    };

    map<[string, json]> dataSet = {
        "1": ["list_type_input"],
        "2": ["list_type_input_with_empty_value"],
        "3": ["list_type_input_with_null_value"],
        "4": ["nullable_list_type_input_without_value"],
        "5": ["nullable_list_type_input_with_invalid_value"],
        "6": ["list_type_inputs_with_nested_list"],
        "7": ["nested_list_input_with_invalid_values_1"],
        "8": ["nested_list_input_with_invalid_values_2"],
        "9": ["list_type_input_with_variable", {words: ["Hello!", "This", "is", "Ballerina", "GraphQL"]}],
        "10": ["list_type_input_with_invalid_variables", {words: ["Hello!", true, "is", 4, "GraphQL"]}],
        "11": ["list_type_with_input_objects"],
        "12": ["list_type_with_invalid_input_objects_value"],
        "13": ["list_type_with_nested_list_in_input_object"],
        "14": ["variables_inside_list_value", {name2: "Jessie"}],
        "15": ["invalid_variables_inside_list_value"],
        "16": ["input_object_type_variables_inside_list_value", var1],
        "17": ["list_type_variables_inside_list_value", {list1: [4, 5, 6, 7]}],
        "18": ["list_type_with_invalid_nested_list_in_input_object"],
        "19": ["list_type_variables_with_input_objects", var2],
        "20": ["list_type_variables_with_invalid_input_objects", var3],
        "21": ["list_type_variables_with_nested_list_in_input_object", var4],
        "22": ["list_type_variables_with_invalid_nested_list_in_input_object", var5],
        "23": ["list_type_within_input_objects"],
        "24": ["empty_list_type_within_input_objects"],
        "25": ["invalid_list_type_within_input_objects"],
        "26": ["invalid_list_type_for_input_objects"],
        "27": ["invalid_value_with_nested_list_in_input_objects"],
        "28": ["list_type_within_input_objects_with_variables", var6],
        "29": ["empty_list_type_within_input_objects_with_variables", var7],
        "30": ["invalid_list_type_within_input_objects_with_variables", var8],
        "31": ["list_type_with_enum_values"],
        "32": ["list_type_with_invalid_enum_values"],
        "33": ["list_type_with_variable_default_values_1"],
        "34": ["list_type_with_variable_default_values_2"],
        "35": ["list_type_with_variable_default_values_3"],
        "36": ["list_type_with_variable_default_values_4"],
        "37": ["list_type_with_variable_default_values_5"],
        "38": ["list_type_with_variable_default_values_6"],
        "39": ["list_type_with_variable_default_values_7"],
        "40": ["list_type_with_variable_default_values_8"],
        "41": ["list_type_with_variable_default_values_9"],
        "42": ["list_type_with_default_value"],
        "43": ["list_type_with_invalid_variable_default_values_1"],
        "44": ["list_type_with_invalid_variable_default_values_2"],
        "45": ["list_type_with_invalid_variable_default_values_3"],
        "46": ["list_type_with_invalid_variable_default_values_4"],
        "47": ["list_type_with_invalid_variable_default_values_5"],
        "48": ["list_type_with_invalid_variable_default_values_6"],
        "49": ["list_type_with_invalid_variable_default_values_7"],
        "50": ["list_type_with_invalid_variable_default_values_8"],
        "51": ["list_type_with_invalid_variable_default_values_9"],
        "52": ["non_null_list_type_variable_with_empty_list_value_1", {tvSeries: []}],
        "53": ["non_null_list_type_variable_with_empty_list_value_2", {tvSeries: []}]
    };
    return dataSet;
}
