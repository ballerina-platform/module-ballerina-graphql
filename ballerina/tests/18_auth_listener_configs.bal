// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

// NOTE: All the tokens/credentials used in this test are dummy tokens/credentials and used only for testing purposes.

import ballerina/test;

@test:Config {
    groups: ["auth"]
}
isolated function testNoAuthServiceSuccess() {
    assertSuccess(sendBearerTokenRequest(9096, "/noAuth", JWT1));
    assertSuccess(sendJwtRequest(9096, "/noAuth"));
}

@test:Config {
    groups: ["auth"]
}
isolated function testBasicAuthServiceAuthSuccess() {
    assertSuccess(sendBasicTokenRequest(9096, "/basicAuth", "alice", "xxx"));
}

@test:Config {
    groups: ["auth"]
}
isolated function testBasicAuthServiceAuthzFailure() {
    assertForbidden(sendBasicTokenRequest(9096, "/basicAuth", "bob", "yyy"));
}

@test:Config {
    groups: ["auth"]
}
isolated function testBasicAuthServiceAuthnFailure() {
    assertUnauthorized(sendBasicTokenRequest(9096, "/basicAuth", "peter", "123"));
    assertUnauthorized(sendNoTokenRequest(9096, "/basicAuth"));
}

@test:Config {
    groups: ["auth"]
}
isolated function testJwtAuthServiceAuthSuccess() {
    assertSuccess(sendBearerTokenRequest(9096, "/jwtAuth", JWT1));
    assertSuccess(sendJwtRequest(9096, "/jwtAuth"));
}

@test:Config {
    groups: ["auth"]
}
isolated function testJwtAuthServiceAuthzFailure() {
    assertForbidden(sendBearerTokenRequest(9096, "/jwtAuth", JWT2));
}

@test:Config {
    groups: ["auth"]
}
isolated function testJwtAuthServiceAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest(9096, "/jwtAuth", JWT3));
    assertUnauthorized(sendNoTokenRequest(9096, "/jwtAuth"));
}

@test:Config {
    groups: ["auth"]
}
isolated function testOAuth2ServiceAuthSuccess() {
    assertSuccess(sendBearerTokenRequest(9096, "/oauth2", ACCESS_TOKEN_1));
    assertSuccess(sendOAuth2TokenRequest(9096, "/oauth2"));
}

@test:Config {
    groups: ["auth"]
}
isolated function testOAuth2ServiceAuthzFailure() {
    assertForbidden(sendBearerTokenRequest(9096, "/oauth2", ACCESS_TOKEN_2));
}

@test:Config {
    groups: ["auth"]
}
isolated function testOAuth2ServiceAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest(9096, "/oauth2", ACCESS_TOKEN_3));
    assertUnauthorized(sendNoTokenRequest(9096, "/oauth2"));
}

@test:Config {
    groups: ["auth"]
}
isolated function testMultipleServiceAuthSuccess() {
    assertSuccess(sendBearerTokenRequest(9096, "/multipleAuth", JWT1));
    assertSuccess(sendJwtRequest(9096, "/multipleAuth"));

}

@test:Config {
    groups: ["auth"]
}
isolated function testMultipleServiceAuthzFailure() {
    assertForbidden(sendBearerTokenRequest(9096, "/multipleAuth", JWT2));
}

@test:Config {
    groups: ["auth"]
}
isolated function testMultipleServiceAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest(9096, "/multipleAuth", JWT3));
    assertUnauthorized(sendNoTokenRequest(9096, "/multipleAuth"));
}

@test:Config {
    groups: ["auth"]
}
isolated function testServiceAuthWithoutScopesAuthSuccess() {
    assertSuccess(sendBearerTokenRequest(9096, "/noScopes", JWT1));
    assertSuccess(sendBearerTokenRequest(9096, "/noScopes", JWT2));
    assertSuccess(sendJwtRequest(9096, "/noScopes"));
}

@test:Config {
    groups: ["auth"]
}
isolated function testServiceAuthWithoutScopesAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest(9096, "/noScopes", JWT3));
    assertUnauthorized(sendNoTokenRequest(9096, "/noScopes"));
}
