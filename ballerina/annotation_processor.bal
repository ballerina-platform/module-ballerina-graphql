// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/jballerina.java;
import graphql.parser;

isolated function getCorsConfig(GraphqlServiceConfig? serviceConfig) returns CorsConfig {
    if serviceConfig is GraphqlServiceConfig && serviceConfig.cors is CorsConfig {
        return <CorsConfig> serviceConfig.cors;
    }
    return {};
}

isolated function getListenerAuthConfig(GraphqlServiceConfig? serviceConfig) returns ListenerAuthConfig[]? {
    if serviceConfig is GraphqlServiceConfig {
        return serviceConfig?.auth;
    }
    return;
}

isolated function getContextInit(GraphqlServiceConfig? serviceConfig) returns ContextInit {
    if serviceConfig is GraphqlServiceConfig {
        return serviceConfig.contextInit;
    }
    return initDefaultContext;
}

isolated function getServiceConfig(Service serviceObject) returns GraphqlServiceConfig|Error {
    typedesc<any> serviceType = typeof serviceObject;
    GraphqlServiceConfig|error config = serviceType.@ServiceConfig.ensureType();
    if config is error {
        return error Error("Service configuration not found");
    }
    return config;
}

isolated function getServiceInterceptors(GraphqlServiceConfig? serviceConfig) returns readonly & Interceptor[] {
    if serviceConfig is GraphqlServiceConfig {
        readonly & Interceptor|readonly & Interceptor[] interceptors = serviceConfig.interceptors;
        if interceptors is Interceptor {
            return [interceptors];
        } else {
            return interceptors;
        }
    }
    return [];
}

isolated function getIntrospection(GraphqlServiceConfig? serviceConfig) returns boolean {
    if serviceConfig is GraphqlServiceConfig {
        return serviceConfig.introspection;
    }
    return true;
}

isolated function getValidation(GraphqlServiceConfig? serviceConfig) returns boolean {
    if serviceConfig is GraphqlServiceConfig {
        return serviceConfig.validation;
    }
    return true;
}

isolated function getFieldInterceptors(service object {} serviceObj, parser:RootOperationType operationType,
        string fieldName, string[] resourcePath) returns readonly & (readonly & Interceptor)[] {
    GraphqlResourceConfig? resourceConfig = getResourceAnnotation(serviceObj, operationType, resourcePath, fieldName);
    if resourceConfig is GraphqlResourceConfig {
        readonly & ((readonly & Interceptor)|(readonly & Interceptor)[]) interceptors = resourceConfig.interceptors;
        if interceptors is (readonly & Interceptor) {
            return [interceptors];
        } else {
            return interceptors;
        }
    }
    return [];
}

isolated function getPrefetchMethodName(service object {} serviceObj, Field 'field) returns string? {
    GraphqlResourceConfig? resourceConfig = getResourceAnnotation(serviceObj,
        'field.getOperationType(), 'field.getResourcePath(), 'field.getName());
    if resourceConfig is GraphqlResourceConfig {
        return resourceConfig.prefetchMethodName;
    }
    return;
}

isolated function isGlobalInterceptor(readonly & Interceptor interceptor) returns boolean {
    GraphqlInterceptorConfig? interceptorConfig = getInterceptorConfig(interceptor);
    if interceptorConfig is GraphqlInterceptorConfig {
        return interceptorConfig.global;
    }
    return true;
}

isolated function getInterceptorConfig(readonly & Interceptor interceptor) returns GraphqlInterceptorConfig? {
    typedesc<any> classType = typeof interceptor;
    return classType.@InterceptorConfig;
}

isolated function getCacheConfig(GraphqlServiceConfig? serviceConfig) returns ServerCacheConfig? {
    if serviceConfig is GraphqlServiceConfig {
        if serviceConfig.cacheConfig is ServerCacheConfig {
            return serviceConfig.cacheConfig;
        }
    }
    return;
}

isolated function getFieldCacheConfigFromServiceConfig(GraphqlServiceConfig? serviceConfig) returns ServerCacheConfig? {
    if serviceConfig is GraphqlServiceConfig {
        return serviceConfig.fieldCacheConfig;
    }
    return;
}

isolated function getFieldCacheConfig(service object {} serviceObj, parser:RootOperationType operationType,
        string fieldName, string[] resourcePath) returns ServerCacheConfig? {
    GraphqlResourceConfig? resourceConfig = getResourceAnnotation(serviceObj, operationType, resourcePath, fieldName);
    if resourceConfig is GraphqlResourceConfig {
        return resourceConfig.cacheConfig;
    }
    return;
}

isolated function getResourceAnnotation(service object {} serviceObject, parser:RootOperationType operationType,
        string[] path, string methodName) returns GraphqlResourceConfig? = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
} external;
