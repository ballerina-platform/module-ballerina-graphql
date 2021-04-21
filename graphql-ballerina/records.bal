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
import graphql.parser;

# Provides a set of configurations for configure the underlying HTTP listener of the GraphQL listener.
public type ListenerConfiguration record {|
    *http:ListenerConfiguration;
|};

# Provides settings related to HTTP/1.x protocol, when using HTTP 1.x as the underlying protocol for the GraphQL
# service.
public type ListenerHttp1Settings record {|
    *http:ListenerHttp1Settings;
    // TODO: KeepAlive settings?
|};

# Configures the SSL/TLS options to be used for the underlying HTTP service used in GraphQL service.
public type ListenerSecureSocket record {|
    *http:ListenerSecureSocket;
|};

# Provides inbound request URI, total header and entity body size threshold configurations.
public type RequestLimitConfigs record {|
    *http:RequestLimitConfigs;
|};

# Represents the data in an output object for a GraphQL query.
public type Data record {
    // Intentionally kept empty
};

# Represents a location in a GraphQL document.
public type Location record {|
    *parser:Location;
|};

# Represents the details of an error occurred during parsing, validating, or executing a GraphQL document.
public type ErrorDetail record {|
    *parser:ErrorDetail;
|};

# Represents a GraphQL output object.
#
# + data - The corresponding data for a GraphQL request
# + errors - The errors occurred while processing a GraphQL request
public type OutputObject record {
    Data data?;
    ErrorDetail[] errors?;
};

# Represents a GraphQL schema. This will be auto-generated when a service is attached to the GraphQL listener.
#
# + types - The types defined in the GraphQL schema
# + queryType - The root operation type of the GraphQL service
public type __Schema record {|
    map<__Type> types;
    __Type queryType;
|};

# Represents a GraphQL type.
#
# + kind - The `graphql:__TypeKind` type of the type
# + name - The name of the type
# + fields - The fields of the given type, if the type qaulifies to have fields
# + enumValues - The possible set of values, if the type is an enum
# + ofType - If the type is a `NON_NULL` or a `LIST`, the `__Type` of the wrapped type
# + possibleTypes - The list of types that can be represented from this type. Only applies for the Union types, and
#                   the the list can only contain object types
public type __Type record {
    __TypeKind kind;
    string? name;
    __Field[] fields?;
    __EnumValue[] enumValues?;
    __Type ofType?;
    __Type[] possibleTypes?;
};

# Represents a GraphQL enum.
#
# + name - The name of the enum
public type __EnumValue record {
    string name;
};

# Represents a GraphQL field.
#
# + name - Name of the field
# + type - The type of the field
# + args - The arguments needed to query the field
public type __Field record {|
    string name;
    __Type 'type;
    map<__InputValue> args?;
|};

# Represents an input value for a GraphQL field.
#
# + name - Name of the input argument
# + type - The type of the input argument
# + defaultValue - The string reperesentation of the default value of the input argument
public type __InputValue record {|
	string name;
	__Type 'type;
	string defaultValue?;
|};

# Represents the type kind of a GraphQL type.
public enum __TypeKind {
    SCALAR,
    OBJECT,
    ENUM,
    NON_NULL,
    LIST,
    UNION
}

type __Directive record {|
    string name;
    string description?;
|};
