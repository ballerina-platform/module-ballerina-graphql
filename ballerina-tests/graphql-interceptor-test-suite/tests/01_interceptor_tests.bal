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

import ballerina/graphql_test_common as common;
import ballerina/test;

@test:Config {
    groups: ["interceptors"],
    dataProvider: dataProviderInterceptors
}
isolated function testInterceptors(string url, string resourceFileName) returns error? {
    string document = check common:getGraphqlDocumentFromFile(resourceFileName);
    json actualPayload = check common:getJsonPayloadFromService(url, document);
    json expectedPayload = check common:getJsonContentFromFile(resourceFileName);
    common:assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderInterceptors() returns string[][] {
    string url1 = "http://localhost:9090/intercept_service_obj";
    string url2 = "http://localhost:9090/intercept_arrays";
    string url3 = "http://localhost:9090/intercept_records";
    string url4 = "http://localhost:9090/invalid_interceptor1";
    string url5 = "http://localhost:9090/invalid_interceptor2";
    string url6 = "http://localhost:9090/invalid_interceptor3";
    string url7 = "http://localhost:9090/invalid_interceptor4";
    string url8 = "http://localhost:9090/intercept_errors1";
    string url9 = "http://localhost:9090/intercept_errors2";
    string url10 = "http://localhost:9090/intercept_errors3";
    string url11 = "http://localhost:9090/intercept_erros_with_hierarchical";
    string url12 = "http://localhost:9090/interceptors_with_null_values3";
    string url13 = "http://localhost:9090/intercept_enum";
    string url14 = "http://localhost:9090/intercept_int";
    string url15 = "http://localhost:9090/intercept_order";
    string url16 = "http://localhost:9090/intercept_hierarchical";
    string url17 = "http://localhost:9090/mutation_interceptor";
    string url18 = "http://localhost:9090/interceptors_with_null_values1";
    string url19 = "http://localhost:9090/interceptors_with_null_values2";
    string url20 = "http://localhost:9090/intercept_record_fields";
    string url21 = "http://localhost:9090/intercept_map";
    string url22 = "http://localhost:9090/intercept_table";
    string url23 = "http://localhost:9090/intercept_string";
    string url24 = "http://localhost:9090/intercept_service_obj_array1";
    string url25 = "http://localhost:9090/intercept_service_obj_array2";
    string url26 = "http://localhost:9090/intercept_unions";

    return [
        [url1, "interceptors_with_service_object"],
        [url2, "interceptors_with_arrays"],
        [url3, "interceptors_with_records"],
        [url4, "interceptors_with_invalid_destructive_modification1"],
        [url5, "interceptors_with_invalid_destructive_modification2"],
        [url6, "interceptors_with_invalid_destructive_modification3"],
        [url7, "interceptors_with_invalid_destructive_modification4"],
        [url8, "interceptors_returning_error1"],
        [url9, "interceptors_returning_error2"],
        [url10, "interceptors_returning_error3"],
        [url11, "interceptors_returning_errors_with_hierarchical_resources"],
        [url12, "interceptors_returning_invalid_value"],
        [url1, "interceptors_with_fragments"],
        [url13, "interceptors_with_enum"],
        [url14, "duplicate_interceptors"],
        [url15, "interceptor_execution_order"],
        [url16, "interceptors_with_hierarchical_paths"],
        [url17, "interceptors_with_mutation"],
        [url18, "interceptors_with_null_value1"],
        [url19, "interceptors_with_null_value2"],
        [url20, "interceptors_with_record_fields"],
        [url20, "interceptors_with_records_and_fragments"],
        [url21, "interceptors_with_map"],
        [url22, "interceptors_with_table"],
        [url23, "interceptors"],
        [url24, "interceptors_with_destructive_modification1"],
        [url25, "interceptors_with_destructive_modification2"],
        [url26, "interceptors_with_union"],
        [url14, "execute_same_interceptor_multiple_times"],
        [url17, "resource_interceptors"]
    ];
}
