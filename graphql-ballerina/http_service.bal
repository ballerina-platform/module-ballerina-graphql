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

service class HttpService {
    private Engine engine;

    isolated function init(Engine engine) {
        self.engine = engine;
    }

    isolated resource function get .(http:Request request) returns http:Response {
        return handleGetRequests(self.engine, request);
    }

    isolated resource function post .(http:Request request) returns http:Response {
        return handlePostRequests(self.engine, request);
    }
}
