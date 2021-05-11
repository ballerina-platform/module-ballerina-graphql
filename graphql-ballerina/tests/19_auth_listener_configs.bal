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

// Unsecured service

listener Listener securedEP1 = new(9401, {
    secureSocket: {
        key: {
            path: KEYSTORE_PATH,
            password: "ballerina"
        }
    }
});

service /noAuth on securedEP1 {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

@test:Config {}
isolated function testNoAuthServiceSuccess() {
    assertSuccess(sendBearerTokenRequest(9401, "/noAuth", JWT1));
    assertSuccess(sendJwtRequest(9401, "/noAuth"));
}

// Basic auth secured service

listener Listener securedEP2 = new(9402, {
    secureSocket: {
        key: {
            path: KEYSTORE_PATH,
            password: "ballerina"
        }
    }
});

@ServiceConfiguration {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["write", "update"]
        }
    ]
}
service /basicAuth on securedEP2 {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

@test:Config {}
isolated function testBasicAuthServiceAuthSuccess() {
    assertSuccess(sendBasicTokenRequest(9402, "/basicAuth", "alice", "xxx"));
}

@test:Config {}
isolated function testBasicAuthServiceAuthzFailure() {
    assertForbidden(sendBasicTokenRequest(9402, "/basicAuth", "bob", "yyy"));
}

@test:Config {}
isolated function testBasicAuthServiceAuthnFailure() {
    assertUnauthorized(sendBasicTokenRequest(9402, "/basicAuth", "peter", "123"));
    assertUnauthorized(sendNoTokenRequest(9402, "/basicAuth"));
}

// JWT auth secured service

listener Listener securedEP3 = new(9403, {
    secureSocket: {
        key: {
            path: KEYSTORE_PATH,
            password: "ballerina"
        }
    }
});

@ServiceConfiguration {
    auth: [
        {
            jwtValidatorConfig: {
                issuer: "wso2",
                audience: "ballerina",
                signatureConfig: {
                    trustStoreConfig: {
                        trustStore: {
                            path: TRUSTSTORE_PATH,
                            password: "ballerina"
                        },
                        certAlias: "ballerina"
                    }
                },
                scopeKey: "scp"
            },
            scopes: ["write", "update"]
        }
    ]
}
service /jwtAuth on securedEP3 {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

@test:Config {}
isolated function testJwtAuthServiceAuthSuccess() {
    assertSuccess(sendBearerTokenRequest(9403, "/jwtAuth", JWT1));
    assertSuccess(sendJwtRequest(9403, "/jwtAuth"));
}

@test:Config {}
isolated function testJwtAuthServiceAuthzFailure() {
    assertForbidden(sendBearerTokenRequest(9403, "/jwtAuth", JWT2));
}

@test:Config {}
isolated function testJwtAuthServiceAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest(9403, "/jwtAuth", JWT3));
    assertUnauthorized(sendNoTokenRequest(9403, "/jwtAuth"));
}

// OAuth2 auth secured service

listener Listener securedEP4 = new(9404, {
    secureSocket: {
        key: {
            path: KEYSTORE_PATH,
            password: "ballerina"
        }
    }
});

@ServiceConfiguration {
    auth: [
        {
            oauth2IntrospectionConfig: {
                url: "https://localhost:9445/oauth2/introspect",
                tokenTypeHint: "access_token",
                scopeKey: "scp",
                clientConfig: {
                    secureSocket: {
                       cert: {
                           path: TRUSTSTORE_PATH,
                           password: "ballerina"
                       }
                    }
                }
            },
            scopes: ["write", "update"]
        }
    ]
}
service /oauth2 on securedEP4 {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

@test:Config {}
isolated function testOAuth2ServiceAuthSuccess() {
    assertSuccess(sendBearerTokenRequest(9404, "/oauth2", ACCESS_TOKEN_1));
    assertSuccess(sendOAuth2TokenRequest(9404, "/oauth2"));
}

@test:Config {}
isolated function testOAuth2ServiceAuthzFailure() {
    assertForbidden(sendBearerTokenRequest(9404, "/oauth2", ACCESS_TOKEN_2));
}

@test:Config {}
isolated function testOAuth2ServiceAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest(9404, "/oauth2", ACCESS_TOKEN_3));
    assertUnauthorized(sendNoTokenRequest(9404, "/oauth2"));
}

// Testing multiple auth configurations support.
// OAuth2, Basic auth & JWT auth secured service

listener Listener securedEP5 = new(9405, {
    secureSocket: {
        key: {
            path: KEYSTORE_PATH,
            password: "ballerina"
        }
    }
});

@ServiceConfiguration {
    auth: [
        {
            oauth2IntrospectionConfig: {
                url: "https://localhost:9445/oauth2/introspect",
                tokenTypeHint: "access_token",
                scopeKey: "scp",
                clientConfig: {
                    secureSocket: {
                       cert: {
                           path: TRUSTSTORE_PATH,
                           password: "ballerina"
                       }
                    }
                }
            },
            scopes: ["write", "update"]
        },
        {
            fileUserStoreConfig: {},
            scopes: ["write", "update"]
        },
        {
            jwtValidatorConfig: {
                issuer: "wso2",
                audience: "ballerina",
                signatureConfig: {
                    trustStoreConfig: {
                        trustStore: {
                            path: TRUSTSTORE_PATH,
                            password: "ballerina"
                        },
                        certAlias: "ballerina"
                    }
                },
                scopeKey: "scp"
            },
            scopes: ["write", "update"]
        }
    ]
}
service /multipleAuth on securedEP5 {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

@test:Config {}
isolated function testMultipleServiceAuthSuccess() {
    assertSuccess(sendBearerTokenRequest(9405, "/multipleAuth", JWT1));
    assertSuccess(sendJwtRequest(9405, "/multipleAuth"));

}

@test:Config {}
isolated function testMultipleServiceAuthzFailure() {
    assertForbidden(sendBearerTokenRequest(9405, "/multipleAuth", JWT2));
}

@test:Config {}
isolated function testMultipleServiceAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest(9405, "/multipleAuth", JWT3));
    assertUnauthorized(sendNoTokenRequest(9405, "/multipleAuth"));
}

// JWT auth secured service (without scopes)

listener Listener securedEP6 = new(9406, {
    secureSocket: {
        key: {
            path: KEYSTORE_PATH,
            password: "ballerina"
        }
    }
});

@ServiceConfiguration {
    auth: [
        {
            jwtValidatorConfig: {
                issuer: "wso2",
                audience: "ballerina",
                signatureConfig: {
                    trustStoreConfig: {
                        trustStore: {
                            path: TRUSTSTORE_PATH,
                            password: "ballerina"
                        },
                        certAlias: "ballerina"
                    }
                }
            }
        }
    ]
}
service /noScopes on securedEP6 {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

@test:Config {}
isolated function testServiceAuthWithoutScopesAuthSuccess() {
    assertSuccess(sendBearerTokenRequest(9406, "/noScopes", JWT1));
    assertSuccess(sendBearerTokenRequest(9406, "/noScopes", JWT2));
    assertSuccess(sendJwtRequest(9406, "/noScopes"));
}

@test:Config {}
isolated function testServiceAuthWithoutScopesAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest(9406, "/noScopes", JWT3));
    assertUnauthorized(sendNoTokenRequest(9406, "/noScopes"));
}
