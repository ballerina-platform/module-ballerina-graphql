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
isolated function testInterceptors() returns error? {
    string document = string `{ enemy }`;
    string url = "http://localhost:9091/intercept_string";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data:{
            enemy: "Tom Marvolo Riddle - voldemort"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
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
isolated function testInterceptorsWithEnums() returns error? {
    string document = string `{ holidays }`;
    string url = "http://localhost:9091/intercept_enum";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            holidays: [SATURDAY, SUNDAY, MONDAY, TUESDAY]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsWithUnion() returns error? {
    string document = string `{ profile(id: 4){ ...on StudentService{ id, name }}}`;
    string url = "http://localhost:9092/intercept_unions";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            profile: {
                id: 3,
                name: "Minerva McGonagall"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testExecuteSameInterceptorMultipleTimes() returns error? {
    string document = string `{ age }`;
    string url = "http://localhost:9091/intercept_int";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data:{
            age: 26
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorWithDestructiveModification1() returns error? {
    string document = string `{ students{ id, name }}`;
    string url = "http://localhost:9091/intercept_service_obj_arrays";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            students: [
                {
                    id: 3,
                    name: "Minerva McGonagall"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsWithDestructiveModification2() returns error? {
    string document = string `{ students{ id, name }}`;
    string url = "http://localhost:9091/intercept_service_obj_array";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            students: ["Ballerina","GraphQL"]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsWithHierarchicalPaths() returns error? {
    string document = string `{ name{ first, last } }`;
    string url = "http://localhost:9091/intercept_hierachical";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            name: {
                first: "Harry",
                last: "Potter"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsWithFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("interceptors_with_fragments.graphql");
    string url = "http://localhost:9091/intercept_service_obj";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_service_object.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorWithMutation() returns error? {
    string document = string `mutation { setName(name: "Heisenberg") { name } }`;
    string url = "http://localhost:9091/mutation_interceptor";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            setName: {
                name: "Albus Percival Wulfric Brian Dumbledore"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsWithInvalidDestructiveModification1() returns error? {
    string document = string `{ age }`;
    string url = "http://localhost:9091/invalid_interceptor1";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_invalid_destructive_modification1.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsWithInvalidDestructiveModification2() returns error? {
    string document = string `{ friends }`;
    string url = "http://localhost:9091/invalid_interceptor2";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_invalid_destructive_modification2.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsWithInvalidDestructiveModification3() returns error? {
    string document = string `{ person { name, address{ city }}}`;
    string url = "http://localhost:9091/invalid_interceptor3";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_invalid_destructive_modification3.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsWithInvalidDestructiveModification4() returns error? {
    string document = string `{ student{ id, name }}`;
    string url = "http://localhost:9091/invalid_interceptor4";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_with_invalid_destructive_modification4.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsReturningError1() returns error? {
    string document = string `{ greet }`;
    string url = "http://localhost:9091/intercept_errors1";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_returning_error1.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsReturningError2() returns error? {
    string document = string `{ friends }`;
    string url = "http://localhost:9091/intercept_errors2";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_returning_error2.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorsReturningError3() returns error? {
    string document = string `{ person{ name, age } }`;
    string url = "http://localhost:9091/intercept_errors3";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interceptors_returning_error3.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interceptors"]
}
isolated function testInterceptorExecutionOrder() returns error? {
    string document = string `{ quote }`;
    string url = "http://localhost:9091/intercept_order";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            quote: "Ballerina is an open-source programming language."
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
