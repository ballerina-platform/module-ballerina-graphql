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
#
# + maxQueryDepth - The maximum depth allowed for a query
# + auth - Listener authentication configurations
# + contextInit - Function to initialize the context. If not provided, an empty context will be created
# + cors - The cross origin resource sharing configurations for the service
# + graphiql - GraphiQL client configurations
# + schemaString - The generated schema. This is auto-generated at the compile-time
# + interceptors - GraphQL service level interceptors
# + introspection - Whether to enable or disable the introspection on the service
# + validation - Whether to enable or disable the constraint validation
public type GraphqlServiceConfig record {|
    int maxQueryDepth?;
    ListenerAuthConfig[] auth?;
    ContextInit contextInit = initDefaultContext;
    CorsConfig cors?;
    Graphiql graphiql = {};
    readonly string schemaString = "";
    readonly (readonly & Interceptor)|(readonly & Interceptor)[] interceptors = [];
    boolean introspection = true;
    boolean validation = true;
|};

# The annotation to configure a GraphQL service.
public annotation GraphqlServiceConfig ServiceConfig on service;

# Provides a set of configurations for the GraphQL resolvers.
#
# + interceptors - GraphQL field level interceptors
public type GraphqlResourceConfig record {|
    readonly (readonly & Interceptor)|(readonly & Interceptor)[] interceptors = [];
|};

# The annotation to configure a GraphQL resolver.
public annotation GraphqlResourceConfig ResourceConfig on object function;

# Provides a set of configurations for the GraphQL interceptors.
#
# + global - Scope of the interceptor. If `true`, the interceptor will be applied to all the resolvers.
public type GraphqlInterceptorConfig record {|
    boolean global = true;
|};

# The annotation to configure a GraphQL interceptor.
public annotation GraphqlInterceptorConfig InterceptorConfig on class;
