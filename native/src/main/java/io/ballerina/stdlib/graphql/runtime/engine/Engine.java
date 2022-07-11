/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.graphql.runtime.engine;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Future;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.async.StrandMetadata;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.RemoteMethodType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.graphql.compiler.schema.types.Schema;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.DATA_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ENGINE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.GET_ACCESSOR;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.GRAPHQL_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.GRAPHQL_SERVICE_OBJECT;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.INTERCEPTOR_EXECUTE;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.MUTATION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.QUERY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SUBSCRIBE_ACCESSOR;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SUBSCRIPTION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isPathsMatching;
import static io.ballerina.stdlib.graphql.runtime.engine.ResponseGenerator.getDataFromService;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.ERROR_TYPE;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.INTERCEPTOR_EXECUTION_STRAND;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.REMOTE_STRAND_METADATA;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.RESOURCE_STRAND_METADATA;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.createError;

/**
 * This handles Ballerina GraphQL Engine.
 */
public class Engine {
    private Engine() {
    }

    public static Object createSchema(BString schemaString) {
        try {
            Schema schema = getDecodedSchema(schemaString);
            SchemaRecordGenerator schemaRecordGenerator = new SchemaRecordGenerator(schema);
            return schemaRecordGenerator.getSchemaRecord();
        } catch (BError e) {
            return createError("Error occurred while creating the schema", ERROR_TYPE, e);
        } catch (NullPointerException e) {
            return createError("Failed to generate schema", ERROR_TYPE);
        }
    }

    public static void attachServiceToEngine(BObject service, BObject engine) {
        engine.addNativeData(GRAPHQL_SERVICE_OBJECT, service);
    }

    public static void attachFieldToEngine(BObject fieldNode, BObject engine) {
        engine.addNativeData(GRAPHQL_FIELD, fieldNode);
    }

    public static void executeQuery(Environment environment, BObject visitor, BObject node) {
        BObject engine = visitor.getObjectValue(ENGINE_FIELD);
        BMap<BString, Object> data = (BMap<BString, Object>) visitor.getMapValue(DATA_FIELD);
        Future future = environment.markAsync();
        BObject service = (BObject) engine.getNativeData(GRAPHQL_SERVICE_OBJECT);
        List<String> paths = new ArrayList<>();
        paths.add(node.getStringValue(NAME_FIELD).getValue());
        List<Object> pathSegments = new ArrayList<>();
        pathSegments.add(StringUtils.fromString(node.getStringValue(NAME_FIELD).getValue()));
        CallbackHandler callbackHandler = new CallbackHandler(future);
        ExecutionContext executionContext = new ExecutionContext(environment, visitor, callbackHandler, QUERY);
        executeResourceMethod(executionContext, service, node, data, paths, pathSegments);
    }

    public static void executeSubscription(Environment environment, BObject visitor, BObject node, Object result) {
        Future future = environment.markAsync();
        BMap<BString, Object> data = visitor.getMapValue(DATA_FIELD);
        List<Object> pathSegments = new ArrayList<>();
        pathSegments.add(StringUtils.fromString(node.getStringValue(NAME_FIELD).getValue()));
        CallbackHandler callbackHandler = new CallbackHandler(future);
        ExecutionContext executionContext = new ExecutionContext(environment, visitor, callbackHandler, SUBSCRIPTION);
        ResourceCallback resourceCallback = new ResourceCallback(executionContext, node, data, pathSegments);
        callbackHandler.addCallback(resourceCallback);
        resourceCallback.notifySuccess(result);
    }

    public static void executeMutation(Environment environment, BObject visitor, BObject node) {
        BObject engine = visitor.getObjectValue(ENGINE_FIELD);
        BMap<BString, Object> data = visitor.getMapValue(DATA_FIELD);
        Future future = environment.markAsync();
        BObject service = (BObject) engine.getNativeData(GRAPHQL_SERVICE_OBJECT);
        String fieldName = node.getStringValue(NAME_FIELD).getValue();
        CallbackHandler callbackHandler = new CallbackHandler(future);
        List<Object> pathSegments = new ArrayList<>();
        pathSegments.add(StringUtils.fromString(fieldName));
        ExecutionContext executionContext = new ExecutionContext(environment, visitor, callbackHandler, MUTATION);
        executeRemoteMethod(executionContext, service, node, data, pathSegments);
    }

    static void executeResourceMethod(ExecutionContext executionContext, BObject service, BObject node,
                                      BMap<BString, Object> data, List<String> paths, List<Object> pathSegments) {
        ServiceType serviceType = (ServiceType) service.getType();
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            if (GET_ACCESSOR.equals(resourceMethod.getAccessor()) && isPathsMatching(resourceMethod, paths)) {
                getExecutionResult(executionContext, service, node, resourceMethod, data, pathSegments,
                                   RESOURCE_STRAND_METADATA);
                return;
            }
        }
        // The resource not found. This should be either a resource with hierarchical paths or an introspection query
        getDataFromService(executionContext, service, node, data, paths, pathSegments);
    }

    static void executeRemoteMethod(ExecutionContext executionContext, BObject service, BObject node,
                                    BMap<BString, Object> data, List<Object> pathSegments) {
        ServiceType serviceType = (ServiceType) service.getType();
        BString fieldName = node.getStringValue(NAME_FIELD);
        for (RemoteMethodType remoteMethod : serviceType.getRemoteMethods()) {
            if (remoteMethod.getName().equals(fieldName.getValue())) {
                getExecutionResult(executionContext, service, node, remoteMethod, data, pathSegments,
                                   REMOTE_STRAND_METADATA);
                return;
            }
        }
    }

    private static void getExecutionResult(ExecutionContext executionContext, BObject service, BObject node,
                                           MethodType method, BMap<BString, Object> data, List<Object> pathSegments,
                                           StrandMetadata strandMetadata) {
        ArgumentHandler argumentHandler = new ArgumentHandler(executionContext, method);
        Object[] args = argumentHandler.getArguments(node);
        ResourceCallback callback = new ResourceCallback(executionContext, node, data, pathSegments);
        executionContext.getCallbackHandler().addCallback(callback);
        if (service.getType().isIsolated() && service.getType().isIsolated(method.getName())) {
            executionContext.getEnvironment().getRuntime()
                    .invokeMethodAsyncConcurrently(service, method.getName(), null,
                                                   strandMetadata, callback, null, PredefinedTypes.TYPE_NULL, args);
        } else {
            executionContext.getEnvironment().getRuntime()
                    .invokeMethodAsyncSequentially(service, method.getName(), null,
                                                   strandMetadata, callback, null, PredefinedTypes.TYPE_NULL, args);
        }
    }

    private static Schema getDecodedSchema(BString schemaBString) {
        if (schemaBString == null) {
            throw createError("Schema generation failed due to null schema string", ERROR_TYPE);
        }
        if (schemaBString.getValue().isBlank() || schemaBString.getValue().isEmpty()) {
            throw createError("Schema generation failed due to empty schema string", ERROR_TYPE);
        }
        String schemaString = schemaBString.getValue();
        byte[] decodedString = Base64.getDecoder().decode(schemaString.getBytes(StandardCharsets.UTF_8));
        try {
            ByteArrayInputStream byteStream = new ByteArrayInputStream(decodedString);
            ObjectInputStream inputStream = new ObjectInputStream(byteStream);
            return (Schema) inputStream.readObject();
        } catch (IOException | ClassNotFoundException e) {
            BError cause = ErrorCreator.createError(StringUtils.fromString(e.getMessage()));
            throw createError("Schema generation failed due to exception", ERROR_TYPE, cause);
        }
    }

    public static Object getSubscriptionResult(Environment env, BObject visitor, BObject node) {
        Future subscriptionFutureResult = env.markAsync();
        SubscriptionCallback subscriptionCallback = new SubscriptionCallback(subscriptionFutureResult);
        CallbackHandler callbackHandler = new CallbackHandler(subscriptionFutureResult);
        ExecutionContext executionContext = new ExecutionContext(env, visitor, callbackHandler, SUBSCRIPTION);
        BString fieldName = node.getStringValue(NAME_FIELD);
        BObject engine = visitor.getObjectValue(ENGINE_FIELD);
        BObject service = (BObject) engine.getNativeData(GRAPHQL_SERVICE_OBJECT);
        ServiceType serviceType = (ServiceType) service.getType();
        UnionType typeUnion = TypeCreator.createUnionType(PredefinedTypes.TYPE_STREAM, PredefinedTypes.TYPE_ERROR);
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            if (SUBSCRIBE_ACCESSOR.equals(resourceMethod.getAccessor()) &&
                fieldName.getValue().equals(resourceMethod.getResourcePath()[0])) {
                ArgumentHandler argumentHandler = new ArgumentHandler(executionContext, resourceMethod);
                Object[] args = argumentHandler.getArguments(node);
                if (service.getType().isIsolated() && service.getType().isIsolated(resourceMethod.getName())) {
                    env.getRuntime()
                            .invokeMethodAsyncConcurrently(service, resourceMethod.getName(), null,
                                                           null, subscriptionCallback, null, typeUnion, args);
                } else {
                    env.getRuntime()
                            .invokeMethodAsyncSequentially(service, resourceMethod.getName(), null,
                                                           null, subscriptionCallback, null, typeUnion, args);
                }
            }
        }
        return null;
    }

    public static Object executeResource(Environment environment, BObject service, BObject fieldNode, BObject context) {
        return null;
    }

    public static Object executeInterceptor(Environment environment, BObject interceptor, BObject field,
                                            BObject context) {
        Future future = environment.markAsync();
        ExecutionCallback executionCallback = new ExecutionCallback(future);
        ServiceType serviceType = (ServiceType) interceptor.getType();
        RemoteMethodType remoteMethod = getRemoteMethod(serviceType, INTERCEPTOR_EXECUTE);
        Type returnType = TypeCreator.createUnionType(PredefinedTypes.TYPE_ANY, PredefinedTypes.TYPE_ERROR);
        if (remoteMethod != null) {
            Object[] arguments = getInterceptorArguments(context, field);
            if (serviceType.isIsolated() && serviceType.isIsolated(remoteMethod.getName())) {
                environment.getRuntime().invokeMethodAsyncConcurrently(interceptor, remoteMethod.getName(), null,
                        INTERCEPTOR_EXECUTION_STRAND, executionCallback, null, returnType, arguments);
            } else {
                environment.getRuntime().invokeMethodAsyncSequentially(interceptor, remoteMethod.getName(), null,
                        INTERCEPTOR_EXECUTION_STRAND, executionCallback, null,
                        returnType, arguments);
            }
        }
        return null;
    }

    private static RemoteMethodType getRemoteMethod(ServiceType serviceType, String methodName) {
        for (RemoteMethodType remoteMethod : serviceType.getRemoteMethods()) {
            if (remoteMethod.getName().equals(methodName)) {
                return remoteMethod;
            }
        }
        return null;
    }

    private static Object[] getInterceptorArguments(BObject context, BObject field) {
        Object[] args = new Object[4];
        args[0] = context;
        args[1] = true;
        args[2] = field;
        args[3] = true;
        return args;
    }

    public static BString getInterceptorName(BObject interceptor) {
        ServiceType serviceType = (ServiceType) interceptor.getType();
        return StringUtils.fromString(serviceType.getName());
    }
}
