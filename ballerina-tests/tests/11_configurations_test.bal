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
    http:Client httpClient = check new("http://localhost:9093/timeoutService", httpVersion = "1.1");
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
            },
            {
                message: "Cannot query field \"book\" on type \"Query\".",
                locations: [
                    {
                        line: 1,
                        column: 3
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
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("fragment_query_exceeding_max_depth.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["configs"]
}
isolated function testQueryWithNamedOperationExceedingMaxDepth() returns error? {
    string document = check getGraphQLDocumentFromFile("query_with_named_operation_exceeding_max_depth.graphql");
    string url = "http://localhost:9091/depthLimitService";
    json actualPayload = check getJsonPayloadFromService(url, document);
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

@test:Config {
    groups: ["configs", "cors"]
}
isolated function testCorsConfigurationWithWildCard() returns error? {
    string url = "http://localhost:9091";
    map<string|string[]> headers = {
        ["origin"]:"http://www.wso2.com",
        ["access-control-request-method"]:["POST"],
        ["access-control-request-headers"]:["X-Content-Type-Options"]
    };
    http:Client httpClient = check new(url, httpVersion = "1.1");
    http:Response response = check httpClient->options("/corsConfigService1", headers); // send preflight request
    test:assertEquals(check response.getHeader("access-control-allow-origin"), "http://www.wso2.com");
    test:assertTrue(response.hasHeader("access-control-allow-credentials"));
    test:assertEquals(check response.getHeader("access-control-allow-methods"), "POST");
    test:assertEquals(check response.getHeader("access-control-allow-headers"), "X-Content-Type-Options");
    test:assertEquals(check response.getHeader("access-control-max-age"), "84900");
}

@test:Config {
    groups: ["configs", "cors"]
}
isolated function testCorsConfigurationsWithSpecificOrigins() returns error? {
    string url = "http://localhost:9091";
    map<string|string[]> headers = {
        ["origin"]:"http://www.wso2.com",
        ["access-control-request-method"]:["POST"],
        ["access-control-request-headers"]:["X-PINGOTHER"]
    };
    http:Client httpClient = check new(url, httpVersion = "1.1");
    http:Response response = check httpClient->options("/corsConfigService2", headers); // send preflight request
    test:assertEquals(check response.getHeader("access-control-allow-origin"), "http://www.wso2.com");
    test:assertNotEquals(check response.getHeader("access-control-allow-origin"), "http://www.ws02.com");
    test:assertTrue(response.hasHeader("access-control-allow-credentials"));
    test:assertEquals(check response.getHeader("access-control-allow-methods"), "POST");
    test:assertEquals(check response.getHeader("access-control-allow-headers"), "X-PINGOTHER");
    test:assertEquals(check response.getHeader("access-control-max-age"), "-1");
}

@test:Config {
    groups: ["configs"]
}
isolated function testIntrospectionDisableConfigWithSchemaIntrospection() returns error? {
    string document = string `{ __schema { queryType { kind fields { name } } } }`;
    string url = "http://localhost:9091/introspection";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "GraphQL introspection is not allowed by the GraphQL Service, but the query contained __schema.",
                locations: [
                    {
                        line: 1,
                        column: 3
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
isolated function testIntrospectionDisableConfigWithTypeIntrospection() returns error? {
    string document = string `{ person{ name }, __type(name: "Person") { name } }`;
    string url = "http://localhost:9091/introspection";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "GraphQL introspection is not allowed by the GraphQL Service, but the query contained __type.",
                locations: [
                    {
                        line: 1,
                        column: 19
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
isolated function testIntrospectionDisableConfig() returns error? {
    string document = string `{ __schema { queryType { kind fields { name } } }, __type(name: "Person") { name } }`;
    string url = "http://localhost:9091/introspection";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "GraphQL introspection is not allowed by the GraphQL Service, but the query contained __schema.",
                locations: [
                    {
                        line: 1,
                        column: 3
                    }
                ]
            },
            {
                message: "GraphQL introspection is not allowed by the GraphQL Service, but the query contained __type.",
                locations: [
                    {
                        line: 1,
                        column: 52
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
isolated function testIntrospectionDisableConfigWithTypeNameIntrospection() returns error? {
    string document = string `{ person{ name, age, __typename }, __typename }`;
    string url = "http://localhost:9091/introspection";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data:{
            person:{
                name: "Walter White",
                age:50,
                __typename: "Person"
            },
            __typename:"Query"
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}


@test:Config {
    groups: ["configs"]
}
isolated function testIntrospectionDisableConfigWithMutation() returns error? {
    string document = string `{ __schema { mutationType { kind fields { name } } } }`;
    string url = "http://localhost:9091/introspection";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "GraphQL introspection is not allowed by the GraphQL Service, but the query contained __schema.",
                locations: [
                    {
                        line: 1,
                        column: 3
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
isolated function testIntrospectionDisableConfigWithFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("introspection_disable_config_with_fragments.graphql");
    string url = "http://localhost:9091/introspection";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        errors: [
            {
                message: "GraphQL introspection is not allowed by the GraphQL Service, but the query contained __schema.",
                locations: [
                    {
                        line: 6,
                        column: 5
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
