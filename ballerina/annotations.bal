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

# Provides a set of configurations for the GraphQL service.
public type GraphqlServiceConfig record {|
    # The maximum depth allowed for a query
    int maxQueryDepth?;
    # Listener authentication configurations
    ListenerAuthConfig[] auth?;
    # Function to initialize the context. If not provided, an empty context will be created
    ContextInit contextInit = initDefaultContext;
    # The cross origin resource sharing configurations for the service
    CorsConfig cors?;
    # GraphiQL client configurations
    Graphiql graphiql = {};
    # The generated schema. This is auto-generated at the compile-time. Providing a value for this field will end up in
    # a compilation error.
    readonly string schemaString = "";
    # GraphQL service level interceptors
    readonly (readonly & Interceptor)|(readonly & Interceptor)[] interceptors = [];
    # Whether to enable or disable the introspection on the service
    boolean introspection = true;
    # Whether to enable or disable the constraint validation
    boolean validation = true;
    # The cache configurations for the operations
    ServerCacheConfig cacheConfig?;
    # The field cache config derived from the resource annotations. This is auto-generated at the compile time
    readonly ServerCacheConfig? fieldCacheConfig = ();
    # The query complexity configuration for the service.
    QueryComplexityConfig queryComplexityConfig?;
|};

# The annotation to configure a GraphQL service.
public annotation GraphqlServiceConfig ServiceConfig on service;

# Provides a set of configurations for the GraphQL resolvers.
public type GraphqlResourceConfig record {|
    # GraphQL field level interceptors
    readonly (readonly & Interceptor)|(readonly & Interceptor)[] interceptors = [];
    # The name of the instance method to be used for prefetching
    string prefetchMethodName?;
    # The cache configurations for the fields
    ServerCacheConfig cacheConfig?;
    # The complexity value of the field
    int complexity?;
|};

# The annotation to configure a GraphQL resolver.
public annotation GraphqlResourceConfig ResourceConfig on object function;

# Provides a set of configurations for the GraphQL interceptors.
public type GraphqlInterceptorConfig record {|
    # Scope of the interceptor. If `true`, the interceptor will be applied to all the resolvers.
    boolean global = true;
|};

# The annotation to configure a GraphQL interceptor.
public annotation GraphqlInterceptorConfig InterceptorConfig on class;
