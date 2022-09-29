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
import ballerina/io;
import ballerina/websocket;

# Represents the Scalar types supported by the Ballerina GraphQL module.
public type Scalar boolean|int|float|string|decimal;

# Represents a GraphQL service.
public type Service distinct service object {
};

# Function type for initializing the `graphql:Context` object.
# This function will be called with the `http:Request` and the `http:RequestContext` objects from the original request
# received to the GraphQL endpoint.
#
# + requestContext - The `http:RequestContext` object from the original request
# + request - The `http:Request` object from the original request
public type ContextInit isolated function (http:RequestContext requestContext, http:Request request) returns Context|error;

# The input parameter type used for file uploads in GraphQL mutations.
#
# + fileName - Name of the file
# + mimeType - File mime type according to the content
# + encoding - File stream encoding
# + byteStream - File content as a stream of `byte[]`
public type Upload record {|
    string fileName;
    string mimeType;
    string encoding;
    stream<byte[], io:Error?> byteStream;
|};

# Represent CORS configurations for internal HTTP service
public type CorsConfig record {|
    *http:CorsConfig;
|};

# Represent GraphiQL client configurations
#
# + enabled - Status of the client
# + path - Path for the client
public type Graphiql record {|
    boolean enabled = false;
    string path = "graphiql";
|};

# Internal HTTP service class for GraphQL services
isolated service class HttpService {
    *http:Service;
}

# Internal Websocket service class for GraphQL subscription
isolated service class UpgradeService {
    *websocket:UpgradeService;
}

# Represent a GraphQL interceptor
public type Interceptor distinct service object {
    isolated remote function execute(Context context, Field 'field) returns anydata|error;
};

// GraphQL client related data binding types representation

# Represents the target type binding record with data and extensions of a GraphQL response for `executeWithType` method.
#
# + extensions -  Meta information on protocol extensions from the GraphQL server
# + data -  The requested data from the GraphQL server
public type GenericResponse record {|
   map<json?> extensions?;
   record {| anydata...; |}|map<json?> data?;
|};

# Represents the target type binding record with data, extensions and errors of a GraphQL response for `execute` method.
#
# + errors - The errors occurred (if present) while processing the GraphQL request.
public type GenericResponseWithErrors record {|
   *GenericResponse;
   ErrorDetail[] errors?;
|};
