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

type Data record {
    // Intentionally kept empty
};

type Location record {|
    *parser:Location;
|};

type ErrorDetail record {|
    *parser:ErrorDetail;
|};

type OutputObject record {
    Data data?;
    ErrorDetail[] errors?;
};

type __Schema record {|
    __Type[] types;
    __Type queryType;
    __Type mutationType?;
    __Type subscriptionType?;
    __Directive[] directives = [];
|};

type __Type record {|
    __TypeKind kind;
    string name?;
    string description?;
    __Field[] fields?;
    __Type[] interfaces?;
    __Type[] possibleTypes?;
    __EnumValue[] enumValues?;
    __InputValue[] inputFields?;
    __Type ofType?;
|};

type __EnumValue record {|
    string name;
    string description?;
    boolean isDeprecated = false;
    string deprecationReason?;
|};

type __Field record {|
    string name;
    string description?;
    __InputValue[] args;
    __Type 'type;
    boolean isDeprecated = false;
    string deprecationReason?;
|};

type __InputValue record {|
	string name;
	string description?;
	__Type 'type;
	string defaultValue?;
|};

enum __TypeKind {
    SCALAR,
    OBJECT,
    ENUM,
    NON_NULL,
    LIST,
    UNION,
    INTERFACE,
    INPUT_OBJECT
}

type __Directive record {|
    string name;
    string description?;
    __DirectiveLocation[] locations?;
    __InputValue[] args = [];
|};

enum __DirectiveLocation {
  QUERY,
  MUTATION,
  SUBSCRIPTION,
  FIELD,
  FRAGMENT_DEFINITION,
  FRAGMENT_SPREAD,
  INLINE_FRAGMENT,
  SCHEMA,
  FIELD_DEFINITION,
  ARGUMENT_DEFINITION,
  ENUM_VALUE,
  INPUT_FIELD_DEFINITION
}
