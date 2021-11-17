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

import ballerina/http;

isolated service class HttpService {
    *http:Service;

    private final Engine engine;
    private final readonly & ListenerAuthConfig[]? authConfig;
    private final ContextInit contextInit;

    isolated function init(Engine engine, GraphqlServiceConfig? serviceConfig) {
        self.engine = engine;
        self.authConfig = getListenerAuthConfig(serviceConfig).cloneReadOnly();
        self.contextInit = getContextInit(serviceConfig);
    }

    isolated resource function get .(http:Request request) returns http:Response {
         // TODO: Temporary initiate the request context here, since it is not yet added in the HTTP resource
        http:RequestContext requestContext = new;
        Context|http:Response context = self.initContext(requestContext, request);
        if context is http:Response {
            return context;
        } else {
            http:Response? authResult = authenticateService(self.authConfig, request);
            if authResult is http:Response {
                return authResult;
            }
            return handleGetRequests(self.engine, context, request);
        }
    }

    isolated resource function post .(http:Request request) returns http:Response {
         // TODO: Temporary initiate the request context here, since it is not yet added in the HTTP resource
        http:RequestContext requestContext = new;
        Context|http:Response context = self.initContext(requestContext, request);
        if context is http:Response {
            return context;
        } else {
            http:Response? authResult = authenticateService(self.authConfig, request);
            if authResult is http:Response {
                return authResult;
            }
            return handlePostRequests(self.engine, context, request);
        }
    }

    isolated function initContext(http:RequestContext requestContext, http:Request request) returns Context|http:Response {
        Context|error context = self.contextInit(requestContext, request);
        if context is error {
            json payload = { errors: [{ message: context.message() }] };
            http:Response response = new;
            if (context is AuthnError || context is AuthzError) {
                response.statusCode = http:STATUS_BAD_REQUEST;
            } else {
                response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            }
            response.setPayload(payload);
            return response;
        } else {
            return context;
        }
    }
}
