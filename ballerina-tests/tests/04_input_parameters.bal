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
import ballerina/lang.value;

@test:Config {
    groups: ["inputs"],
    dataProvider: dataProviderInputParameters
}
isolated function testInputParameters(string documentFileName) returns error? {
    string url = "http://localhost:9091/inputs";
    string document = check getGraphQLDocumentFromFile(appendGraphqlExtension(documentFileName));
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile(appendJsonExtension(documentFileName));
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderInputParameters() returns string[][] {
    return [
        ["functions_with_input_parameter"],
        ["input_parameter_type_not_present_in_return_types"],
        ["query_without_default_parameter"],
        ["query_with_default_parameter"],
        ["float_as_input"],
        ["coerce_int_input_to_float"],
        ["optional_enum_argument_without_value"],
        ["optional_enum_argument_with_value"],
        ["input_with_escape_characters"],
        ["input_with_unicode_characters"]
    ];
}

@test:Config {
    groups: ["inputs"]
}
isolated function testFloatWithPositiveInfinity() returns error? {
    string document = "{ weightInPounds(weightInKg: 1.7E309) }";
    string url = "http://localhost:9091/inputs";
    string actualPayload = check getTextPayloadFromService(url, document);
    json payloadWithFloatValues = check value:fromJsonFloatString(actualPayload);
    json expectedPayload = {
        data: {
            weightInPounds: float:Infinity
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}

@test:Config {
    groups: ["inputs"]
}
isolated function testFloatNegativeInfinity() returns error? {
    string document = "{ weightInPounds(weightInKg: -1.7E309) }";
    string url = "http://localhost:9091/inputs";
    string actualPayload = check getTextPayloadFromService(url, document);
    json payloadWithFloatValues = check value:fromJsonFloatString(actualPayload);
    json expectedPayload = {
        data: {
            weightInPounds: -float:Infinity
        }
    };
    assertJsonValuesWithOrder(payloadWithFloatValues, expectedPayload);
}
