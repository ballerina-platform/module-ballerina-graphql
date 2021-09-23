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

import ballerina/graphql;
import ballerina/http;

public isolated function initContext(http:Request request, http:RequestContext requestContext)
returns graphql:Context|error {
    graphql:Context context = new;
    check context.add("auth", "TOKEN");
    return context;
}

@graphql:ServiceConfig {
    contextInit: initContext
}
service graphql:Service on new graphql:Listener(4000) {
    resource function get name(graphql:Context context) returns string {
        return "Walter White";
    }

    remote function setName(graphql:Context context, string name) returns string {
        return name;
    }
}
