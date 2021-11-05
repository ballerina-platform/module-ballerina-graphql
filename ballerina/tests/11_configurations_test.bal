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
import ballerina/test;

@test:Config {
    groups: ["configs"]
}
isolated function testTimeoutResponse() returns error? {
    string document = "{ greet }";
    json payload = {
        query: document
    };
    http:Client httpClient = check new("http://localhost:9093/timeoutService");
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
    groups: ["configs"]
}
isolated function testQueryExceedingMaxDepth() returns error? {
    string document = "{ book { author { books { author { books } } } } }";
    string url = "http://localhost:9091/depthLimitService";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
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
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["configs"]
}
isolated function testFragmentQueryExceedingMaxDepth() returns error? {
    string document = check getGraphQLDocumentFromFile("fragment_query_exceeding_max_depth.graphql");
    string url = "http://localhost:9091/depthLimitService";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("fragment_query_exceeding_max_depth.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["configs"]
}
isolated function testQueryWithNamedOperationExceedingMaxDepth() returns error? {
    string document = check getGraphQLDocumentFromFile("query_with_named_operation_exceeding_max_depth.graphql");
    string url = "http://localhost:9091/depthLimitService";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "Query \"getData\" has depth of 3, which exceeds max depth of 2",
                locations: [
                    {
                        line: 1,
                        column: 1
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
