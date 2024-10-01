// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/graphql;

// Unsecured service
service /noAuth on secureListener {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

// Basic auth secured service
@graphql:ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["write", "update"]
        }
    ],
    graphiql: {
        enabled: true
    }
}
service /basicAuth on secureListener {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

// JWT auth secured service
@graphql:ServiceConfig {
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
service /jwtAuth on secureListener {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

// OAuth2 auth secured service
@graphql:ServiceConfig {
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
service /oauth2 on secureListener {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

// Testing multiple auth configurations support.
// OAuth2, Basic auth & JWT auth secured service
@graphql:ServiceConfig {
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
service /multipleAuth on secureListener {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}

// JWT auth secured service (without scopes)
@graphql:ServiceConfig {
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
service /noScopes on secureListener {
    isolated resource function get greeting() returns string {
        return "Hello World!";
    }
}
