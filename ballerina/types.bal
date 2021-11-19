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

# Represents the Scalar types supported by the Ballerina GraphQL module.
public type Scalar boolean|int|float|string;

# Represents a GraphQL service.
public type Service distinct service object {
};

type AnydataMap map<anydata>;

# Function type for initializing the `graphql:Context` object.
# This function will be called with the `http:Request` and the `http:RequestContext` objects from the original request
# received to the GraphQL endpoint.
#
# + requestContext - The `http:RequestContext` object from the original request
# + request - The `http:Request` object from the original request
public type ContextInit isolated function (http:RequestContext requestContext, http:Request request) returns Context|error;
