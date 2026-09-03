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

import graphql.parser;

import ballerina/http;
import ballerina/websocket;

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
# + validation - Enables the inbound payload validation functionality which provided by the constraint package. Enabled by default
# + subscription - Configurations related to GraphQL subscriptions over WebSocket. Nil value means the
#                  default subscription behavior with default configurations
public type ClientConfiguration record {|
    // The HTTP-related fields of this record are mapped to the `http:ClientConfiguration` in the
    // `toHttpClientConfig` function. A new HTTP-related field added here must be mapped there as well.
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
    WebSocketConfiguration? subscription = ();
|};

# Represents the WebSocket transport configurations for GraphQL subscriptions.
public type WebSocketConfiguration record {|
    # The WebSocket URL of the subscription endpoint. If not provided, it is derived
    # from the client's service URL by mapping `http` to `ws` and `https` to `wss`
    string? serviceUrl = ();
    # The payload to be sent with the `connection_init` message,
    # commonly used to pass authentication information
    map<json>? connectionInitPayload = ();
    # The maximum time to wait (in seconds) for the `connection_ack` message after sending the
    # `connection_init` message, when establishing the subscription connection. This bounds the
    # `graphql-transport-ws` handshake only; the WebSocket upgrade is bounded separately by
    # `websocketConfig.handShakeTimeout`. This is independent of the client's HTTP `timeout`
    decimal connectionInitTimeout = 60;
    # The reconnection configurations. Nil value disables automatic reconnection
    ReconnectConfig? reconnect = ();
    # The handler for the `ping` messages received from the server. If not
    # provided, the client automatically responds with a `pong` message
    PingMessageHandler? pingMessageHandler = ();
    # The client-side keep-alive configuration. The client periodically sends `ping` messages to
    # detect a silently dropped connection and treats it as lost when the corresponding `pong` is
    # not received in time, triggering reconnection when configured
    KeepAliveConfig keepAlive = {};
    # The configurations of the underlying `websocket:Client`
    WebSocketClientConfiguration websocketConfig = {};
|};

# Represents the client-side keep-alive configuration for a GraphQL subscription connection. The
# client periodically sends `ping` messages and, when the corresponding `pong` is not received
# within the timeout, treats the connection as lost.
#
# + enabled - Whether the client-side keep-alive is active
# + pingInterval - The interval (in seconds) at which the client sends `ping` messages
# + pongTimeout - The maximum time (in seconds) to wait for the `pong` response to each `ping`
#                 before considering the connection lost
public type KeepAliveConfig record {|
    boolean enabled = true;
    decimal pingInterval = 15;
    decimal pongTimeout = 15;
|};

# Represents the server-side keep-alive configuration for GraphQL subscription connections. The
# server periodically sends `ping` messages and, when the corresponding `pong` is not received
# within the timeout, treats the connection as lost and closes it.
#
# + enabled - Whether the server-side keep-alive is active
# + pingInterval - The interval (in seconds) at which the server sends `ping` messages
# + pongTimeout - The maximum time (in seconds) to wait for the `pong` response to each `ping`
#                 before considering the connection lost
public type ServerKeepAliveConfig record {|
    boolean enabled = true;
    decimal pingInterval = 15;
    decimal pongTimeout = 15;
|};

# Handles the `ping` messages received from the GraphQL server.
public type PingMessageHandler isolated function (PingMessageCaller caller, map<json>? payload) returns error?;

# Represents the configurations of the underlying WebSocket client used for GraphQL subscriptions.
# This mirrors the `websocket:ClientConfiguration` without the `subProtocols` field, which is
# controlled internally by the GraphQL client.
public type WebSocketClientConfiguration record {|
    # Custom headers, which should be sent to the server
    map<string> customHeaders = {};
    # Read timeout (in seconds) of the client
    decimal readTimeout = -1;
    # Write timeout (in seconds) of the client
    decimal writeTimeout = -1;
    # SSL/TLS-related options
    websocket:ClientSecureSocket? secureSocket = ();
    # The maximum payload size of a WebSocket frame in bytes.
    # If this is not set, is negative, or is zero, the default frame size of 65536 will be used
    int maxFrameSize = 65536;
    # Enable support for compression in the WebSocket
    boolean webSocketCompressionEnabled = true;
    # Time (in seconds) that a connection waits to get the response of
    # the WebSocket handshake. If the timeout exceeds, then the connection is terminated with
    # an error. If the value < 0, then the value sets to the default value(300)
    decimal handShakeTimeout = 300;
    # An Array of `http:Cookie`
    http:Cookie[] cookies?;
    # Configurations related to client authentication
    websocket:ClientAuthConfig auth?;
    # A service to handle the ping/pong frames.
    # Resources in this service gets called on the receipt of ping/pong frames from the server
    websocket:PingPongService pingPongHandler?;
    # Retry-related configurations
    websocket:WebSocketRetryConfig? retryConfig = ();
    # Enable/disable constraint validation
    boolean validation = true;
|};

# Represents the reconnection configurations for the subscription connection.
public type ReconnectConfig record {|
    # The maximum number of reconnection attempts before giving up
    int maxAttempts = 5;
    # The initial interval (in seconds) between reconnection attempts
    decimal interval = 1;
    # The multiplier applied to the interval after each failed attempt
    float backOffFactor = 2.0;
    # The maximum interval (in seconds) between reconnection attempts
    decimal maxInterval = 30;
|};

type Data record {
    // Intentionally kept empty
};

# Represents a location in a GraphQL document.
public type Location record {|
    *parser:Location;
|};

# Represents an error in GraphQL.
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

# Represents a GraphQL schema type.
# + kind - The `__TypeKind` of the type
# + name - The name of the type. This can be nil if the type is `NON_NULL` or `LIST`
# + description - The description of the type
# + fields - The fields of the type. This only applies if the `kind` is `OBJECT` or `INTERFACE`. Otherwise,
#       this will be nil.
# + interfaces - The interfaces of the type. This only applies if the `kind` is `OBJECT` or `INTERFACE`. Otherwise,
#       this will be nil.
# + possibleTypes - The possible types of the type. This only applies if the `kind` is `UNION` or `INTERFACE`.
#       Otherwise, this will be nil.
# + enumValues - The enum values of the type. This only applies if the `kind` is `ENUM`. Otherwise, this will be nil.
# + inputFields - The input fields of the type. This only applies if the `kind` is `INPUT_OBJECT`. Otherwise,
#       this will be nil.
# + ofType - The type of the type. This only applies if the `kind` is `NON_NULL` or `LIST`. Otherwise, this will be nil.
public type __Type record {|
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

# Represents a GraphQL enum value.
# + name - The name of the enum value
# + description - The description of the enum value
# + isDeprecated - Whether the enum value is deprecated
# + deprecationReason - The reason for deprecation of the enum value
public type __EnumValue record {|
    string name;
    string? description = ();
    boolean isDeprecated = false;
    string? deprecationReason = ();
|};

# Represents a GraphQL field.
# + name - The name of the field
# + description - The description of the field
# + args - The arguments of the field
# + type - The type of the field
# + isDeprecated - Whether the field is deprecated
# + deprecationReason - The reason for deprecation of the field
public type __Field record {|
    string name;
    string? description = ();
    __InputValue[] args;
    __Type 'type;
    boolean isDeprecated = false;
    string? deprecationReason = ();
|};

# Represents a GraphQL input value.
# + name - The name of the input value
# + description - The description of the input value
# + type - The type of the input value
# + defaultValue - The default value of the input value, if there is one
public type __InputValue record {|
    string name;
    string? description = ();
    __Type 'type;
    string? defaultValue = ();
|};

# Represents a GraphQL type kind. This is used to represent the kind of a GraphQL type.
# + SCALAR - Represents a GraphQL scalar type
# + OBJECT - Represents a GraphQL (output) object type
# + ENUM - Represents a GraphQL enum type
# + NON_NULL - Represents a GraphQL non-null type. If a field is of this type, it is guaranteed to be non-null
# + LIST - Represents a GraphQL list type
# + UNION - Represents a GraphQL union type
# + INTERFACE - Represents a GraphQL interface type
# + INPUT_OBJECT - Represents a GraphQL input object type
public enum __TypeKind {
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

type PlaceholderNode record {|
    string __uuid;
|};
