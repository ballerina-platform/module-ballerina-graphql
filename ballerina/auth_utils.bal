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

import ballerina/auth;
import ballerina/http;
import ballerina/jwt;
import ballerina/log;
import ballerina/oauth2;
import ballerina/regex;

// Uses for declarative auth design, where the authentication decision is taken by reading the auth annotations
// provided in service and the `Authorization` header of request.
isolated function authenticateService(ListenerAuthConfig[]? authConfigs, http:Request req) returns http:Response? {
    if authConfigs is () {
        return;
    }
    string|http:HeaderNotFoundError header = req.getHeader("Authorization");
    if header is string {
        http:Unauthorized|http:Forbidden? result = tryAuthenticate(<ListenerAuthConfig[]>authConfigs, header);
        if result is http:Unauthorized {
            return createUnauthorizedResponse();
        } else if result is http:Forbidden {
            return createForbiddenResponse();
        }
        return;
    }
    return createUnauthorizedResponse();
}

isolated map<ListenerAuthHandler> authHandlers = {};

isolated function tryAuthenticate(ListenerAuthConfig[] authConfig, string header) returns http:Unauthorized|http:Forbidden? {
    string scheme = extractScheme(header);
    http:Unauthorized|http:Forbidden? authResult = <http:Unauthorized>{};
    foreach ListenerAuthConfig config in authConfig {
        if scheme is AUTH_SCHEME_BASIC {
            if config is FileUserStoreConfigWithScopes {
                authResult = authenticateWithFileUserStore(config, header);
            } else if config is LdapUserStoreConfigWithScopes {
                authResult = authenticateWithLdapUserStoreConfig(config, header);
            } else {
                log:printDebug("Invalid configurations for 'Basic' scheme.");
            }
        } else if scheme is AUTH_SCHEME_BEARER {
            if config is JwtValidatorConfigWithScopes {
                authResult = authenticateWithJwtValidatorConfig(config, header);
            } else if config is OAuth2IntrospectionConfigWithScopes {
                authResult = authenticateWithOAuth2IntrospectionConfig(config, header);
            } else {
                log:printDebug("Invalid configurations for 'Bearer' scheme.");
            }
        }
        if authResult is () || authResult is http:Forbidden {
            return authResult;
        }
    }
    return authResult;
}

isolated function authenticateWithFileUserStore(FileUserStoreConfigWithScopes config, string header)
                                                returns http:Unauthorized|http:Forbidden? {
    http:ListenerFileUserStoreBasicAuthHandler handler;
    lock {
        string key = config.fileUserStoreConfig.toString();
        if authHandlers.hasKey(key) {
            handler = <http:ListenerFileUserStoreBasicAuthHandler> authHandlers.get(key);
        } else {
            handler = new(config.fileUserStoreConfig.cloneReadOnly());
            authHandlers[key] = handler;
        }
    }
    auth:UserDetails|http:Unauthorized authn = handler.authenticate(header);
    string|string[]? scopes = config?.scopes;
    if authn is auth:UserDetails {
        if scopes is string|string[] {
            http:Forbidden? authz = handler.authorize(authn, scopes);
            return authz;
        }
        return;
    }
    return authn;
}

isolated function authenticateWithLdapUserStoreConfig(LdapUserStoreConfigWithScopes config, string header)
                                                      returns http:Unauthorized|http:Forbidden? {
    http:ListenerLdapUserStoreBasicAuthHandler handler;
    lock {
        string key = config.ldapUserStoreConfig.toString();
        if authHandlers.hasKey(key) {
            handler = <http:ListenerLdapUserStoreBasicAuthHandler> authHandlers.get(key);
        } else {
            handler = new(config.ldapUserStoreConfig.cloneReadOnly());
            authHandlers[key] = handler;
        }
    }
    auth:UserDetails|http:Unauthorized authn = handler->authenticate(header);
    string|string[]? scopes = config?.scopes;
    if authn is auth:UserDetails {
        if scopes is string|string[] {
            http:Forbidden? authz = handler->authorize(authn, scopes);
            return authz;
        }
        return;
    }
    return authn;
}

isolated function authenticateWithJwtValidatorConfig(JwtValidatorConfigWithScopes config, string header)
                                                     returns http:Unauthorized|http:Forbidden? {
    http:ListenerJwtAuthHandler handler;
    lock {
        string key = config.jwtValidatorConfig.toString();
        if authHandlers.hasKey(key) {
            handler = <http:ListenerJwtAuthHandler> authHandlers.get(key);
        } else {
            handler = new(config.jwtValidatorConfig.cloneReadOnly());
            authHandlers[key] = handler;
        }
    }
    jwt:Payload|http:Unauthorized authn = handler.authenticate(header);
    string|string[]? scopes = config?.scopes;
    if authn is jwt:Payload {
        if scopes is string|string[] {
            http:Forbidden? authz = handler.authorize(authn, scopes);
            return authz;
        }
        return;
    } else {
        return authn;
    }
}

isolated function authenticateWithOAuth2IntrospectionConfig(OAuth2IntrospectionConfigWithScopes config, string header)
                                                            returns http:Unauthorized|http:Forbidden? {
    http:ListenerOAuth2Handler handler;
    lock {
        string key = config.oauth2IntrospectionConfig.toString();
        if authHandlers.hasKey(key) {
            handler = <http:ListenerOAuth2Handler> authHandlers.get(key);
        } else {
            handler = new(config.oauth2IntrospectionConfig.cloneReadOnly());
            authHandlers[key] = handler;
        }
    }
    oauth2:IntrospectionResponse|http:Unauthorized|http:Forbidden auth = handler->authorize(header, config?.scopes);
    if auth is oauth2:IntrospectionResponse {
        return;
    } else {
        return auth;
    }
}

// Extract the scheme from `string` header.
isolated function extractScheme(string header) returns string {
    return regex:split(header, " ")[0];
}

isolated function createUnauthorizedResponse() returns http:Response {
    http:Response response = new;
    response.statusCode = http:STATUS_BAD_REQUEST;
    json payload = {
        errors: [
            {
                message: "Required authentication information is either missing or not valid for the resource."
            }
        ]
    };
    response.setPayload(payload);
    return response;
}

isolated function createForbiddenResponse() returns http:Response {
    http:Response response = new;
    response.statusCode = http:STATUS_BAD_REQUEST;
    json payload = {
        errors: [
            {
                message: "Access is denied to the requested resource. The user might not have enough permission."
            }
        ]
    };
    response.setPayload(payload);
    return response;
}
