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
    groups: ["intersection"],
    dataProvider: dataProviderIntersectionType
}
isolated function testIntersectionType(string jsonFileName, string operationName, json variables) returns error? {
    string document = check getGraphqlDocumentFromFile("intersection_types");
    string url = "http://localhost:9091/intersection_types";
    json actualPayload = check getJsonPayloadFromService(url, document, variables, operationName = operationName);
    json expectedPayload = check getJsonContentFromFile(jsonFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderIntersectionType() returns map<[string, string, json]> {
    json variableGetCommonName = {
        animal: {
            commonName: "Sri Lankan Tree Nymph",
            species: {
                genus: "Idea",
                specificName: "iasonia"
            }
        }
    };

    map<[string, string, json]> dataSet = {
        "1": ["input_with_intersection_parameter", "getName", ()],
        "2": ["input_with_intersection_parameter_reference", "getCity", ()],
        "3": ["output_with_intersection_paramenter", "getProfile", ()],
        "4": ["output_with_intersection_paramenter_reference", "getBook", ()],
        "5": ["input_with_intersection_parameter_array", "getNames", ()],
        "6": ["input_with_intersection_parameter_reference_array", "getCities", ()],
        "7": ["output_with_intersection_parameter_array", "getProfiles", ()],
        "8": ["output_with_intersection_parameter_reference_array", "getBooks", ()],
        "9": ["input_with_intersection_referring_non_intersection_type", "getCommonName", variableGetCommonName],
        "10": ["input_with_non_intersection_type_referring_intersection_type", "getOwnerName", ()]
    };
    return dataSet;
}
