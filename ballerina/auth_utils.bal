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
import ballerina/oauth2;

// Uses for declarative auth design, where the authentication decision is taken by reading the auth annotations
// provided in service and the `Authorization` header of request.
isolated function authenticateService(ListenerAuthConfig[]? authConfigs, http:Request req) returns http:Response? {
    if (authConfigs is ()) {
        return;
    }
    string|http:HeaderNotFoundError header = req.getHeader("Authorization");
    if (header is string) {
        http:Unauthorized|http:Forbidden? result = tryAuthenticate(<ListenerAuthConfig[]>authConfigs, header);
        if (result is http:Unauthorized) {
            return createUnauthorizedResponse();
        } else if (result is http:Forbidden) {
            return createForbiddenResponse();
        }
        return;
    } else {
        return createUnauthorizedResponse();
    }
}

isolated function tryAuthenticate(ListenerAuthConfig[] authConfig, string header) returns http:Unauthorized|http:Forbidden? {
    foreach ListenerAuthConfig config in authConfig {
        if (config is FileUserStoreConfigWithScopes) {
            http:ListenerFileUserStoreBasicAuthHandler handler = new(config.fileUserStoreConfig);
            auth:UserDetails|http:Unauthorized authn = handler.authenticate(header);
            string|string[]? scopes = config?.scopes;
            if (authn is auth:UserDetails) {
                if (scopes is string|string[]) {
                    http:Forbidden? authz = handler.authorize(authn, scopes);
                    return authz;
                }
                return;
            }
        } else if (config is LdapUserStoreConfigWithScopes) {
            http:ListenerLdapUserStoreBasicAuthHandler handler = new(config.ldapUserStoreConfig);
            auth:UserDetails|http:Unauthorized authn = handler->authenticate(header);
            string|string[]? scopes = config?.scopes;
            if (authn is auth:UserDetails) {
                if (scopes is string|string[]) {
                    http:Forbidden? authz = handler->authorize(authn, scopes);
                    return authz;
                }
                return;
            }
        } else if (config is JwtValidatorConfigWithScopes) {
            http:ListenerJwtAuthHandler handler = new(config.jwtValidatorConfig);
            jwt:Payload|http:Unauthorized authn = handler.authenticate(header);
            string|string[]? scopes = config?.scopes;
            if (authn is jwt:Payload) {
                if (scopes is string|string[]) {
                    http:Forbidden? authz = handler.authorize(authn, scopes);
                    return authz;
                }
                return;
            }
        } else {
            // Here, config is OAuth2IntrospectionConfigWithScopes
            http:ListenerOAuth2Handler handler = new(config.oauth2IntrospectionConfig);
            oauth2:IntrospectionResponse|http:Unauthorized|http:Forbidden auth = handler->authorize(header, config?.scopes);
            if (auth is oauth2:IntrospectionResponse) {
                return;
            } else if (auth is http:Forbidden) {
                return auth;
            }
        }
    }
    http:Unauthorized unauthorized = {};
    return unauthorized;
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
