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

@test:Config {
    groups: ["interceptors"]
}
//Done
isolated function testInterceptors() returns error? {
    string document = string `{ enemy }`;
    string url = "http://localhost:9091/intercept_string";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
//Done
isolated function testInterceptorsWithServiceObjects() returns error? {
    string document = string `{ teacher{ id, name, subject }}`;
    string url = "http://localhost:9091/intercept_service_obj";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_service_object.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
//Done
isolated function testInterceptorsWithArrays() returns error? {
    string document = string `{ houses }`;
    string url = "http://localhost:9091/intercept_arrays";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_arrays.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
//Done
isolated function testInterceptorsWithRecords() returns error? {
    string document = string `{ profile{ name, address{ number, street }}}`;
    string url = "http://localhost:9091/intercept_records";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_records.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
//Done
isolated function testInterceptorsReturningError() returns error? {
    string document = string `{ greet }`;
    string url = "http://localhost:9091/intercept_errors";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_returning_error.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
//Done
isolated function testExecuteSameInterceptorMultipleTimes() returns error? {
    string document = string `{ age }`;
    string url = "http://localhost:9091/interceptors";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("execute_same_interceptor_multiple_times.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
//Done
isolated function testInterceptorWithDestructiveModification() returns error? {
    string document = string `{ students{ name, id }}`;
    string url = "http://localhost:9091/intercept_service_obj_arrays";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptor_with_destructive_modification.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
//Done
isolated function testInterceptorWithMutation() returns error? {
    string document = string `mutation{ setName(name: "Ballerina"){ name }`;
    string url = "http://localhost:9091/mutation_interceptor";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptor_with_mutation.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
//Cannot do until nuvindu's PR merged
isolated function testInterceptorWithSubscription() returns error? {
    string document = check getGraphQLDocumentFromFile("interceptor_with_subscription.graphql");
    string url = "http://localhost:9091/subscription_interceptor";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptor_with_subscription..json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

isolated function testInterceptorsReturnInvalidValues() returns error? {
    string document = string `{ greet }`;
    string url = "http://localhost:9091/intercept_errors";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_returning_error.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
