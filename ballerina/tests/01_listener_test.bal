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

@test:Config {
    groups: ["listener", "attach_detach"]
}
function testDetachAndAttach() returns error? {
    check wrappedListener.attach(simpleService1, "graphql");
    check wrappedListener.detach(simpleService1);
    check wrappedListener.attach(simpleService1, "graphql");
    error? attachResult = trap wrappedListener.attach(simpleService1, "graphql");
    test:assertTrue(attachResult is Error);
    Error err = <Error>attachResult;
    string expectedErrorMessage = "Error occurred while attaching the service";
    test:assertEquals(err.message(), expectedErrorMessage);

    error? cause = err.cause();
    test:assertTrue(cause is error);
    error causingError = <error>cause;
    string expectedCausingErrorMessage = string`Service registration failed: two services have the same basePath : '/graphql'`;
    test:assertEquals(causingError.message(), expectedCausingErrorMessage);
    check wrappedListener.detach(simpleService1);
}

@test:Config {
    groups: ["listener", "attach_detach"],
    dependsOn: [testDetachAndAttach]
}
function testAttachAndDetachMultipleServices() returns error? {
    string document = "{ name }";
    check wrappedListener.attach(simpleService1, "endpoint_1");
    check wrappedListener.attach(simpleService2, "endpoint_2");

    string url1 = "http://localhost:9090/endpoint_1";
    string url2 = "http://localhost:9090/endpoint_2";
    json result1 = check getJsonPayloadFromService(url1, document);
    json result2 = check getJsonPayloadFromService(url2, document);

    json expectedResult = { data: { name: "Walter White" } };

    assertJsonValuesWithOrder(result1, expectedResult);
    assertJsonValuesWithOrder(result2, expectedResult);

    // Detach first service
    check wrappedListener.detach(simpleService1);
    string errorMessage = check getTextPayloadFromBadService(url1, document);
    json newResult2 = check getJsonPayloadFromService(url2, document);
    test:assertEquals("no matching service found for path : /endpoint_1", errorMessage);
    assertJsonValuesWithOrder(newResult2, expectedResult);
}

@test:Config {
    groups: ["listener", "configs"]
}
function testInvalidMaxQueryDepth() returns error? {
    Error? result = wrappedListener.attach(invalidMaxQueryDepthService, "invalid");
    test:assertTrue(result is Error);
    Error err = <Error>result;
    test:assertEquals(err.message(), "Max query depth value must be a positive integer");
}
