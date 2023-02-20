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
    groups: ["introspection"],
    dataProvider: dataProviderIntrospection
}
isolated function testIntrospection(string url, string documentFileName, json variables = ()) returns error? {
    string document = check getGraphqlDocumentFromFile(documentFileName);
    json actualPayload = check getJsonPayloadFromService(url, document, variables);
    json expectedPayload = check getJsonContentFromFile(documentFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderIntrospection() returns map<[string, string, json]> {
    string url1 = "http://localhost:9092/service_objects";
    string url2 = "http://localhost:9091/records";
    string url3 = "http://localhost:9091/mutations";
    string url4 = "http://localhost:9092/unions";
    string url5 = "http://localhost:9091/input_objects";
    string url6 = "http://localhost:9091/inputs";
    string url7 = "http://localhost:9091/documentation";
    string url8 = "http://localhost:9090/deprecation";

    map<[string, string, json]> dataSet = {
        "1": [url1, "complex_introspection_query"],
        "2": [url1, "invalid_introspection_query"],
        "3": [url1, "introspection_query_with_missing_selection"],
        "4": [url2, "invalid_schema_introspection_field"],
        "5": [url2, "query_type_introspection"],
        "6": [url3, "mutation_type_introspection"],
        "7": [url1, "complex_introspection_query_with_other_fields"],
        "8": [url1, "enum_value_introspection"],
        "9": [url2, "type_name_introspection_on_operation"],
        "10": [url2, "type_name_introspection_on_record_types"],
        "11": [url2, "querying_subfields_on_type_name"],
        "12": [url1, "type_name_introspection_on_service_types"],
        "13": [url4, "type_name_introspection_on_union_of_service_types"],
        "14": [url4, "type_name_introspection_on_nullable_union_of_service_types"],
        "15": [url4, "type_name_introspection_in_fragments"],
        "16": [url5, "introspection_on_service_with_input_objects"],
        "17": [url2, "typename_introspection_on_scalar"],
        "18": [url2, "type_introspection_without_type_name_argument"],
        "19": [url2, "type_introspection_in_invalid_place"],
        "20": [url2, "type_introspection_on_non_existing_type"],
        "21": [url2, "type_introspection_without_fields"],
        "22": [url2, "type_introspection"],
        "23": [url6, "introspection_on_inputs_with_default_values"],
        "24": [url2, "directive_locations"],
        "25": [url7, "documentation"],
        "26": [url8, "deprecated_fields_introspection"],
        "27": [url8, "deprecated_fields_filtering"],
        "28": [url8, "deprecated_fields_filtering_with_variables", {includeDeprecated: false}],
        "29": [url8, "deprecated_fields_introspection_with_variables", {includeDeprecated: true}],
        "30": [url2, "type_introspection_with_alias", {includeDeprecated: true}],
        "31": [url2, "typename_introspection_on_type_record"],
        "32": [url2, "typename_introspection_on_schema_introspection"],
        "33": [url2, "typename_introspection_on_field"]
    };
    return dataSet;
}
