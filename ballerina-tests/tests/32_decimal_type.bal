// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/lang.value;

@test:Config {
    groups: ["inputs", "decimal"],
    dataProvider: dataProviderDecimalType1
}
isolated function testDecimalType1(string documentFileName, json variables) returns error? {
    string url = "http://localhost:9091/inputs";
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    json actualPayload = check getJsonPayloadFromService(url, document, variables = variables);
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}


function dataProviderDecimalType1() returns map<[string, json]> {
    map<[string, json]> dataSet = {
        "1": ["decimal_type_input", ()],
        "2": ["coerce_int_to_decimal", ()],
        "3": ["coerce_int_to_decimal_with_variable_input", {val: 2}],
        "4": ["coerce_int_to_decimal_with_default_value", ()],
        "5": ["coerce_decimal_to_float", {weight: 56.4d}],
        "6": ["decimal_with_negative_zero", {val: -0}]
    };
    return dataSet;
}

@test:Config {
    groups: ["inputs", "decimal"],
    dataProvider: dataProviderDecimalType2
}
isolated function testDecimalType2(string documentFileName, map<json>? variables) returns error? {
    string url = "http://localhost:9091/inputs";
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    json actualPayload = check getJsonPayloadFromService(url, document, variables = variables);
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    map<value:JsonDecimal> payloadWithFloatValues = check actualPayload.cloneWithType();
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}


function dataProviderDecimalType2() returns map<[string, map<json>?]> {
    map<[string, map<json>?]> dataSet = {
        "1": ["decimal_type_list_input", {prices: [[1.3323232, 4.856343], [5.63535, 6], [5, 7, 8]]}],
        "2": ["decimal_type_list_with_default_input", {}],
        "3": ["decimal_type_list_with_variable_input", {prices: [[1.3323232, 4.856343], [5.63535, 6], [5, 7, 8]]}],
        "4": ["decimal_type_with_input_object_variable", {items: [{name: "soap", price: 64.5555332}, {name: "sugar", price: 154}]}],
        "5": ["decimal_type_with_input_object_default_value", ()]
    };
    return dataSet;
}

@test:Config {
    groups: ["inputs", "decimal"]
}
isolated function testDecimalTypeVariableInput() returns error? {
    string document = "($val:Decimal!){ convertDecimalToFloat(value:$val) }";
    json variables = {
        val: 2.3332414141451451411231341451
    };
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            convertDecimalToFloat: 2.3332414141451451411231341451
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "decimal"]
}
isolated function testDecimalTypeDefaultValue() returns error? {
    string document = "($val:Decimal! = 2.3332414141451451411231341451){ convertDecimalToFloat(value:$val) }";
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            convertDecimalToFloat: 2.3332414141451451411231341451
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "decimal"]
}
isolated function testDecimalWithMarginalValue() returns error? {
    string document = "($val:Decimal!){ convertDecimalToFloat(value:$val) }";
    string url = "http://localhost:9091/inputs";
    json variables = {
        val: 1.797693134862314E+308 
    };
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    map<value:JsonFloat> payloadWithFloatValues = check actualPayload.cloneWithType();
    json expectedPayload = {
        data: {
            convertDecimalToFloat: 1.797693134862314E308
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs", "input_coerce", "decimal"],
    dataProvider: dataProviderDecimalType3
}
isolated function testDecimalType3(string documentFileName) returns error? {
    string url = "http://localhost:9091/inputs";
    string document = check getGraphQLDocumentFromFile(string `${documentFileName}.graphql`);
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(string `${documentFileName}.json`);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderDecimalType3() returns string[][] {
    return [
        ["decimal_with_positive_infinity"],
        ["decimal_with_negative_infinity"]
    ];
}
