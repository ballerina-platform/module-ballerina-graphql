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

import ballerina/http;
import ballerina/lang.runtime;
import ballerina/test;

ListenerConfiguration configs = {
    timeout: 1.0
};
listener Listener timeoutListener = new(9102, configs);
listener Listener depthLimitListener = new(9103);

service /timeoutService on timeoutListener {
    isolated resource function get greet() returns string {
        runtime:sleep(3);
        return "Hello";
    }
}

@ServiceConfiguration {
    maxQueryDepth: 2
}
service /depthLimitService on depthLimitListener {
    isolated resource function get greet() returns string {
        return "Hello";
    }
}

service object {} InvalidDepthLimitService =
@ServiceConfiguration {
    maxQueryDepth: 0
}
service object {
    isolated resource function get greet() returns string {
        return "Hello";
    }
};

@test:Config {
    groups: ["configs", "unit"]
}
isolated function testTimeoutResponse() returns error? {
    string document = "{ greet }";
    json payload = {
        query: document
    };
    http:Client httpClient = check new("http://localhost:9102/timeoutService");
    http:Request request = new;
    request.setPayload(payload);

    http:Response response = check httpClient->post("/", request);
    int statusCode = response.statusCode;
    test:assertEquals(statusCode, 408, msg = "Unexpected status code received: " + statusCode.toString());
    string actualPaylaod = check response.getTextPayload();
    string expectedMessage = "Idle timeout triggered before initiating outbound response";
    test:assertEquals(actualPaylaod, expectedMessage);
}

@test:Config {
    groups: ["negative", "configs", "unit"]
}
function testConfigurationsWithHttpListener() returns error? {
    http:Listener httpListener = check new(91021);
    var graphqlListener = new Listener(httpListener, configs);
    if (graphqlListener is Error) {
        string message = "Provided `HttpConfiguration` will be overridden by the given http listener configurations";
        test:assertEquals(message, graphqlListener.message());
    } else {
        test:assertFail("This must throw an error");
    }
}

@test:Config {
    groups: ["negative", "configs", "unit"]
}
function testInvalidMaxDepth() returns error? {
    Listener graphqlListener = check new Listener(91022);
    var result = graphqlListener.attach(InvalidDepthLimitService);
    if (result is Error) {
        string message = "Maximum query depth should be an integer greater than 0";
        test:assertEquals(message, result.message());
    } else {
        test:assertFail("This must throw an error");
    }
}

@test:Config {
    groups: ["configs", "unit"]
}
isolated function testQueryExceedingMaxDepth() returns error? {
    string document = "{ book { author { books { author { books } } } } }";
    string url = "http://localhost:9103/depthLimitService";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        errors: [
            {
                message: "Query has depth of 5, which exceeds max depth of 2",
                locations: [
                    {
                        line: 1,
                        column: 1
                    }
                ]
            }
        ]
    };
    test:assertEquals(actualPayload, expectedPayload);
}


