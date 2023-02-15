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
    groups: ["input_objects", "inputs"],
    dataProvider: dataProviderInputObject
}
isolated function testInputObject(string documentFileName, json variables = ()) returns error? {
    string url = "http://localhost:9091/input_objects";
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderInputObject() returns map<[string, json]> {
    json var1 = {
        info: {
            bookName: "Sherlock",
            edition: 4,
            author: {
                name: "Arthur"
            }
        }
    };

    json var2 = {
        bName: "Harry Potter",
        bAuthor: {
            name: "J.K Rowling",
            age: 50
        }
    };

    json var3 = {
        bName: "Study in Scarlet",
        bAuthor: {
            name: "J.K Rowling",
            age: 50
        }
    };

    json var4 = {
        bName: "Study in Scarlet",
        bAuthor: {
            age: 50
        }
    };

    json var5 = {
        bName: "Harry",
        bAuthor: {
            name: "J.K Rowling"
        }
    };

    json var6 = {
        bName: "Harry",
        bAuthor: {
            name: "Doyle"
        },
        dir: "Chris Columbus"
    };

    json var7 = {
        bName: "Harry",
        bAuthor: [{name:"arthur"}, {name:"J.K Rowling"}],
        dir: "Chris Columbus"
    };

    map<[string, json]> dataSet = {
        "1": ["input_object"],
        "2": ["input_object_with_missing_arguments"],
        "3": ["input_object_with_invalid_arguments1"],
        "4": ["input_object_with_invalid_arguments2"],
        "5": ["input_object_with_variables", {profile:{name:"Arthur", age:5}}],
        "6": ["input_object_with_nested_input_object_variables", var1],
        "7": ["input_object_include_fields_with_variables", {bName:"Harry Potter", authorAge:50}],
        "8": ["input_object_with_duplicate_fields", var2],
        "9": ["input_object_with_undefined_fields", var2],
        "10": ["input_object_include_fields_with_undefined_variables", {authorAge: 50}],
        "11": ["input_object_include_fields_with_complex_variables", var3],
        "12": ["input_object_with_nested_object"],
        "13": ["input_object_with_default_value"],
        "14": ["input_object_without_optional_fields"],
        "15": ["input_object_with_missing_variables_arguments", var4],
        "16": ["input_object_with_enum_type_argument", {day:{day: SUNDAY}}],
        "17": ["input_object_with_fragment_and_variables", var5],
        "18": ["input_object_with_inline_fragment_with_variables", var6],
        "19": ["input_object_with_float_type_variables", {weight: { weightInKg: 70.5 }}],
        "20": ["input_object_with_invalid_type_variables1", {weight: { weight: 70.5 }}],
        "21": ["input_object_with_invalid_type_variables2", {bAuthor: {name:{}, age:{}}}],
        "22": ["input_object_with_unexpected_variable_values", var7],
        "23": ["input_object_variables_with_invalid_type_name", {profile:{name: "Arthur", age: 5}}],
        "24": ["input_object_with_missing_nullable_variable_value"],
        "25": ["default_values_in_input_object_fields"]
    };
    return dataSet;
}
