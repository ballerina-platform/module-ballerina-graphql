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
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.types.ObjectType;
import io.ballerina.runtime.api.types.RemoteMethodType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.graphql.commons.types.Schema;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.GET_ACCESSOR;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.INTERCEPTOR_EXECUTE;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SUBSCRIBE_ACCESSOR;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isPathsMatching;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.ERROR_TYPE;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.INTERCEPTOR_EXECUTION_STRAND;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.INTERNAL_NODE;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.REMOTE_EXECUTION_STRAND;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.RESOURCE_EXECUTION_STRAND;
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

    public static Object executeSubscriptionResource(Environment env, BObject context, BObject service,
                                                     BObject fieldObject) {
        Future subscriptionFutureResult = env.markAsync();
        ExecutionCallback executionCallback = new ExecutionCallback(subscriptionFutureResult);
        BString fieldName = fieldObject.getObjectValue(INTERNAL_NODE).getStringValue(NAME_FIELD);
        ServiceType serviceType = (ServiceType) service.getType();
        UnionType typeUnion = TypeCreator.createUnionType(PredefinedTypes.TYPE_STREAM, PredefinedTypes.TYPE_ERROR);
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            if (SUBSCRIBE_ACCESSOR.equals(resourceMethod.getAccessor()) &&
                    fieldName.getValue().equals(resourceMethod.getResourcePath()[0])) {
                ArgumentHandler argumentHandler = new ArgumentHandler(resourceMethod, context, fieldObject);
                Object[] args = argumentHandler.getArguments();
                ObjectType objectType = (ObjectType) TypeUtils.getReferredType(service.getType());
                if (objectType.isIsolated() && objectType.isIsolated(resourceMethod.getName())) {
                    env.getRuntime()
                            .invokeMethodAsyncConcurrently(service, resourceMethod.getName(), null,
                                                           null, executionCallback, null, typeUnion, args);
                } else {
                    env.getRuntime()
                            .invokeMethodAsyncSequentially(service, resourceMethod.getName(), null,
                                                           null, executionCallback, null, typeUnion, args);
                }
            }
        }
        return null;
    }

    public static Object executeQueryResource(Environment environment, BObject context, BObject service,
                                              ResourceMethodType resourceMethod, BObject fieldObject) {
        Future future = environment.markAsync();
        ExecutionCallback executionCallback = new ExecutionCallback(future);
        ServiceType serviceType = (ServiceType) service.getType();
        Type returnType = TypeCreator.createUnionType(PredefinedTypes.TYPE_ANY, PredefinedTypes.TYPE_NULL);
        if (resourceMethod != null) {
            ArgumentHandler argumentHandler = new ArgumentHandler(resourceMethod, context, fieldObject);
            Object[] arguments = argumentHandler.getArguments();
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
                                               BObject fieldObject) {
        Future future = environment.markAsync();
        ExecutionCallback executionCallback = new ExecutionCallback(future);
        ServiceType serviceType = (ServiceType) service.getType();
        Type returnType = TypeCreator.createUnionType(PredefinedTypes.TYPE_ANY, PredefinedTypes.TYPE_NULL);
        for (RemoteMethodType remoteMethod : serviceType.getRemoteMethods()) {
            String fieldName = fieldObject.getObjectValue(INTERNAL_NODE).getStringValue(NAME_FIELD).getValue();
            if (remoteMethod.getName().equals(fieldName)) {
                ArgumentHandler argumentHandler = new ArgumentHandler(remoteMethod, context, fieldObject);
                Object[] arguments = argumentHandler.getArguments();
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

    public static Object executeInterceptor(Environment environment, BObject interceptor, BObject field,
                                            BObject context) {
        Future future = environment.markAsync();
        ExecutionCallback executionCallback = new ExecutionCallback(future);
        ServiceType serviceType = (ServiceType) interceptor.getType();
        RemoteMethodType remoteMethod = getRemoteMethod(serviceType, INTERCEPTOR_EXECUTE);
        Type returnType = TypeCreator.createUnionType(PredefinedTypes.TYPE_ANY, PredefinedTypes.TYPE_NULL);
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
