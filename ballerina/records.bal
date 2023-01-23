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
|};

# Configures the SSL/TLS options to be used for the underlying HTTP service used in GraphQL service.
public type ListenerSecureSocket record {|
    *http:ListenerSecureSocket;
|};

# Provides inbound request URI, total header and entity body size threshold configurations.
public type RequestLimitConfigs record {|
    *http:RequestLimitConfigs;
|};

# Provides settings related to HTTP/1.x protocol.
public type ClientHttp1Settings record {|
    *http:ClientHttp1Settings;
|};

# Provides configurations for controlling the endpoint's behaviour in response to HTTP redirect related responses.
public type FollowRedirects record {|
    *http:FollowRedirects;
|};

# Configurations for managing GraphQL client connection pool.
public type PoolConfiguration record {|
    *http:PoolConfiguration;
|};

# Provides a set of configurations for controlling the caching behaviour of the endpoint.
public type CacheConfig record {|
    *http:CacheConfig;
|};

# Provides a set of configurations for controlling the behaviour of the Circuit Breaker.
public type CircuitBreakerConfig record {|
    *http:CircuitBreakerConfig;
|};

# Provides configurations for controlling the retrying behavior in failure scenarios.
public type RetryConfig record {|
    *http:RetryConfig;
|};

# Client configuration for cookies.
public type CookieConfig record {|
    *http:CookieConfig;
|};

# Provides inbound response status line, total header and entity body size threshold configurations.
public type ResponseLimitConfigs record {|
    *http:ResponseLimitConfigs;
|};

# Provides configurations for facilitating secure communication with a remote GraphQL endpoint.
public type ClientSecureSocket record {|
    *http:ClientSecureSocket;
|};

# Proxy server configurations to be used with the GraphQL client endpoint.
public type ProxyConfig record {|
    *http:ProxyConfig;
|};

# Provides a set of configurations for controlling the behaviour of the GraphQL client when communicating with 
# the GraphQL server that operates over HTTP.
#
# + http1Settings - Configurations related to HTTP/1.1 protocol
# + timeout - The maximum time to wait (in seconds) for a response before closing the connection
# + forwarded - The choice of setting `forwarded`/`x-forwarded` header
# + followRedirects - Configurations associated with Redirection
# + poolConfig - Configurations associated with request pooling
# + cache - HTTP caching related configurations
# + compression - Specifies the way of handling compression (`accept-encoding`) header
# + auth - Configurations related to client authentication
# + circuitBreaker - Configurations associated with the behaviour of the Circuit Breaker
# + retryConfig - Configurations associated with retrying
# + cookieConfig - Configurations associated with cookies
# + responseLimits - Configurations associated with inbound response size limits
# + secureSocket - SSL/TLS-related options
# + proxy - Proxy server related options
# + validation - Enables the inbound payload validation functionalty which provided by the constraint package. Enabled by default
public type ClientConfiguration record {|
    ClientHttp1Settings http1Settings = {};
    decimal timeout = 60;
    string forwarded = "disable";
    FollowRedirects? followRedirects = ();
    PoolConfiguration? poolConfig = ();
    CacheConfig cache = {};
    Compression compression = COMPRESSION_AUTO;
    ClientAuthConfig? auth = ();
    CircuitBreakerConfig? circuitBreaker = ();
    RetryConfig? retryConfig = ();
    CookieConfig? cookieConfig = ();
    ResponseLimitConfigs responseLimits = {};
    ClientSecureSocket? secureSocket = ();
    ProxyConfig? proxy = ();
    boolean validation = true;
|};

type Data record {
    // Intentionally kept empty
};

type Location record {|
    *parser:Location;
|};

public type ErrorDetail record {|
    *parser:ErrorDetail;
|};

type OutputObject record {|
    ErrorDetail[] errors?;
    Data? data?;
|};

type __Schema record {|
    string? description = ();
    __Type[] types;
    __Type queryType;
    __Type? mutationType = ();
    __Type? subscriptionType = ();
    __Directive[] directives = [];
|};

type __Type record {|
    __TypeKind kind;
    string? name = ();
    string? description = ();
    __Field[]? fields = ();
    __Type[]? interfaces = ();
    __Type[]? possibleTypes = ();
    __EnumValue[]? enumValues = ();
    __InputValue[]? inputFields = ();
    __Type? ofType = ();
|};

type __EnumValue record {|
    string name;
    string? description = ();
    boolean isDeprecated = false;
    string? deprecationReason = ();
|};

type __Field record {|
    string name;
    string? description = ();
    __InputValue[] args;
    __Type 'type;
    boolean isDeprecated = false;
    string? deprecationReason = ();
|};

type __InputValue record {|
    string name;
    string? description = ();
    __Type 'type;
    string? defaultValue = ();
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
    string? description = ();
    __DirectiveLocation[] locations = [];
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
    VARIABLE_DEFINITION,
    SCHEMA,
    SCALAR,
    OBJECT,
    FIELD_DEFINITION,
    ARGUMENT_DEFINITION,
    INTERFACE,
    UNION,
    ENUM,
    ENUM_VALUE,
    INPUT_OBJECT,
    INPUT_FIELD_DEFINITION
}

type ParseResult record {|
    parser:DocumentNode document;
    ErrorDetail[] validationErrors;
|};
