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
import io.ballerina.runtime.api.values.BArray;
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

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.CONTEXT_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.DATA_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ENGINE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.GET_ACCESSOR;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SUBSCRIBE_ACCESSOR;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SUBSCRIPTION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.getService;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isPathsMatching;
import static io.ballerina.stdlib.graphql.runtime.engine.ResponseGenerator.getDataFromService;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.ERROR_TYPE;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.REMOTE_EXECUTION_STRAND;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.RESOURCE_EXECUTION_STRAND;
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

    private static void getExecutionResult(ExecutionContext executionContext, BObject service, BObject node,
                                           MethodType method, BMap<BString, Object> data, List<Object> pathSegments,
                                           StrandMetadata strandMetadata) {
        ArgumentHandler argumentHandler = new ArgumentHandler(method, executionContext.getVisitor()
                .getObjectValue(CONTEXT_FIELD));
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
        BObject service = getService(engine);
        ServiceType serviceType = (ServiceType) service.getType();
        UnionType typeUnion = TypeCreator.createUnionType(PredefinedTypes.TYPE_STREAM, PredefinedTypes.TYPE_ERROR);
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            if (SUBSCRIBE_ACCESSOR.equals(resourceMethod.getAccessor()) &&
                    fieldName.getValue().equals(resourceMethod.getResourcePath()[0])) {
                ArgumentHandler argumentHandler = new ArgumentHandler(resourceMethod, executionContext.getVisitor()
                        .getObjectValue(CONTEXT_FIELD));
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

    public static Object executeQueryResource(Environment environment, BObject context, BObject service,
                                              ResourceMethodType resourceMethod, BObject fieldNode) {
        Future future = environment.markAsync();
        ExecutionCallback executionCallback = new ExecutionCallback(future);
        ServiceType serviceType = (ServiceType) service.getType();
        Type returnType = TypeCreator.createUnionType(PredefinedTypes.TYPE_ANY, PredefinedTypes.TYPE_NULL);
        if (resourceMethod != null) {
            ArgumentHandler argumentHandler = new ArgumentHandler(resourceMethod, context);
            Object[] arguments = argumentHandler.getArguments(fieldNode);
            if (serviceType.isIsolated() && serviceType.isIsolated(resourceMethod.getName())) {
                environment.getRuntime().invokeMethodAsyncConcurrently(service, resourceMethod.getName(), null,
                                                                       RESOURCE_EXECUTION_STRAND, executionCallback,
                                                                       null, returnType, arguments);
            } else {
                environment.getRuntime().invokeMethodAsyncSequentially(service, resourceMethod.getName(), null,
                                                                       RESOURCE_EXECUTION_STRAND, executionCallback,
                                                                       null, returnType, arguments);
            }
        }
        return null;
    }

    public static Object executeMutationMethod(Environment environment, BObject context, BObject service,
                                               BObject fieldNode) {
        Future future = environment.markAsync();
        ExecutionCallback executionCallback = new ExecutionCallback(future);
        ServiceType serviceType = (ServiceType) service.getType();
        Type returnType = TypeCreator.createUnionType(PredefinedTypes.TYPE_ANY, PredefinedTypes.TYPE_NULL);
        for (RemoteMethodType remoteMethod : serviceType.getRemoteMethods()) {
            if (remoteMethod.getName().equals(fieldNode.getStringValue(NAME_FIELD).getValue())) {
                ArgumentHandler argumentHandler = new ArgumentHandler(remoteMethod, context);
                Object[] arguments = argumentHandler.getArguments(fieldNode);
                if (serviceType.isIsolated() && serviceType.isIsolated(remoteMethod.getName())) {
                    environment.getRuntime().invokeMethodAsyncConcurrently(service, remoteMethod.getName(), null,
                                                                           REMOTE_EXECUTION_STRAND, executionCallback,
                                                                           null, returnType, arguments);
                } else {
                    environment.getRuntime().invokeMethodAsyncSequentially(service, remoteMethod.getName(), null,
                                                                           REMOTE_EXECUTION_STRAND, executionCallback,
                                                                           null, returnType, arguments);
                }
            }
        }
        return null;
    }

    public static Object getResourceMethod(BObject service, BArray path) {
        ServiceType serviceType = (ServiceType) service.getType();
        List<String> pathList = getPathList(path);
        return getResourceMethod(serviceType, pathList, GET_ACCESSOR);
    }

    private static ResourceMethodType getResourceMethod(ServiceType serviceType, List<String> path, String accessor) {
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            if (accessor.equals(resourceMethod.getAccessor()) && isPathsMatching(resourceMethod, path)) {
                return resourceMethod;
            }
        }
        return null;
    }

    private static List<String> getPathList(BArray pathArray) {
        List<String> result = new ArrayList<>();
        for (int i = 0; i < pathArray.size(); i++) {
            BString pathSegment = (BString) pathArray.get(i);
            result.add(pathSegment.getValue());
        }
        return result;
    }
}
