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
import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.RemoteMethodType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.observability.ObserveUtils;
import io.ballerina.runtime.observability.ObserverContext;
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.runtime.exception.ConstraintValidationException;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.CompletableFuture;

import static io.ballerina.runtime.observability.ObservabilityConstants.KEY_OBSERVER_CONTEXT;
import static io.ballerina.stdlib.graphql.runtime.engine.ArgumentHandler.getEffectiveType;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.COLON;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.GET_ACCESSOR;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.INTERCEPTOR_EXECUTE;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.OPERATION_QUERY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.OPERATION_SUBSCRIPTION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.RESOURCE_CONFIG;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SUBSCRIBE_ACCESSOR;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isPathsMatching;
import static io.ballerina.stdlib.graphql.runtime.utils.ModuleUtils.getModule;
import static io.ballerina.stdlib.graphql.runtime.utils.ModuleUtils.getResult;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.ERROR_TYPE;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.INTERNAL_NODE;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.createError;

/**
 * This handles Ballerina GraphQL Engine.
 */
public class Engine {
    public static final String RESOURCE_MAP = "graphql.resourceMap";

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

    public static Schema getDecodedSchema(BString schemaBString) {
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

    public static Object executeSubscriptionResource(Environment environment, BObject context, BObject service,
                                                     BObject fieldObject, BObject responseGenerator,
                                                     boolean validation) {
        BString fieldName = fieldObject.getObjectValue(INTERNAL_NODE).getStringValue(NAME_FIELD);
        ServiceType serviceType = (ServiceType) TypeUtils.getType(service);
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            if (SUBSCRIBE_ACCESSOR.equals(resourceMethod.getAccessor()) &&
                    fieldName.getValue().equals(resourceMethod.getResourcePath()[0])) {
                ArgumentHandler argumentHandler =
                        new ArgumentHandler(resourceMethod, context, fieldObject, responseGenerator, validation);
                return getResultObject(environment, context, service, resourceMethod.getName(), argumentHandler);
            }
        }
        return null;
    }

    private static Object getResultObject(Environment environment, BObject context, BObject service,
                                          String methodName, ArgumentHandler argumentHandler) {
        try {
            argumentHandler.validateInputConstraint(environment);
        } catch (ConstraintValidationException e) {
            return null;
        }
        return environment.yieldAndRun(() -> {
            CompletableFuture<Object> subscriptionFutureResult = new CompletableFuture<>();
            ExecutionCallback executionCallback = new ExecutionCallback(subscriptionFutureResult);
            Object[] args = argumentHandler.getArguments();
            try {
                Object result = callResourceMethod(environment.getRuntime(), service, methodName, args);
                executionCallback.notifySuccess(result);
            } catch (BError bError) {
                executionCallback.notifyFailure(bError);
            }
            return getResult(subscriptionFutureResult);
        });
    }

    private static Object callResourceMethod(Runtime runtime, BObject service, String methodName, Object[] args) {
        return runtime.callMethod(service, methodName, null, args);
    }

    public static Object executeQueryResource(Environment environment, BObject context, BObject service,
                                              ResourceMethodType resourceMethod, BObject fieldObject,
                                              BObject responseGenerator, boolean validation) {
        if (resourceMethod == null) {
            return null;
        }
        ArgumentHandler argumentHandler =
                new ArgumentHandler(resourceMethod, context, fieldObject, responseGenerator, validation);
        return getResultObject(environment, context, service, resourceMethod.getName(), argumentHandler);
    }

    public static Object executeMutationMethod(Environment environment, BObject context, BObject service,
                                               BObject fieldObject, BObject responseGenerator, boolean validation) {
        ServiceType serviceType = (ServiceType) TypeUtils.getType(service);
        String fieldName = fieldObject.getObjectValue(INTERNAL_NODE).getStringValue(NAME_FIELD).getValue();
        for (RemoteMethodType remoteMethod : serviceType.getRemoteMethods()) {
            if (remoteMethod.getName().equals(fieldName)) {
                ArgumentHandler argumentHandler =
                        new ArgumentHandler(remoteMethod, context, fieldObject, responseGenerator, validation);
                return getResultObject(environment, context, service, remoteMethod.getName(), argumentHandler);
            }
        }
        return null;
    }

    public static Object executeInterceptor(Environment environment, BObject interceptor, BObject field,
                                            BObject context) {
        ServiceType serviceType = (ServiceType) TypeUtils.getType(interceptor);
        RemoteMethodType remoteMethod = getRemoteMethod(serviceType, INTERCEPTOR_EXECUTE);
        if (remoteMethod == null) {
            return null;
        }
        return environment.yieldAndRun(() -> {
            CompletableFuture<Object> future = new CompletableFuture<>();
            ExecutionCallback executionCallback = new ExecutionCallback(future);
            Object[] arguments = getInterceptorArguments(context, field);
            try {
                Object result = callResourceMethod(environment.getRuntime(), interceptor, remoteMethod.getName(),
                        arguments);
                executionCallback.notifySuccess(result);
            } catch (BError bError) {
                executionCallback.notifyFailure(bError);
            }
            return getResult(future);
        });
    }

    public static Object getResourceMethod(BObject service, BArray path) {
        ServiceType serviceType = (ServiceType) TypeUtils.getType(service);
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

    public static Object getMethod(BObject service, BString methodName) {
        ServiceType serviceType = (ServiceType) TypeUtils.getType(service);
        return getMethod(serviceType, methodName.getValue());
    }

    private static MethodType getMethod(ServiceType serviceType, String methodName) {
        for (MethodType serviceMethod : serviceType.getMethods()) {
            if (methodName.equals(serviceMethod.getName())) {
                return serviceMethod;
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
        Object[] args = new Object[2];
        args[0] = context;
        args[1] = field;
        return args;
    }

    public static BString getInterceptorName(BObject interceptor) {
        ServiceType serviceType = (ServiceType) TypeUtils.getType(interceptor);
        return StringUtils.fromString(serviceType.getName());
    }

    public static Object getResourceAnnotation(BObject service, BString operationType, BArray path,
                                               BString methodName) {
        ServiceType serviceType = (ServiceType) TypeUtils.getType(service);
        MethodType methodType;
        if (OPERATION_QUERY.equals(operationType.getValue())) {
            methodType = getResourceMethod(serviceType, getPathList(path), GET_ACCESSOR);
        } else if (OPERATION_SUBSCRIPTION.equals(operationType.getValue())) {
            methodType = getResourceMethod(serviceType, getPathList(path), SUBSCRIBE_ACCESSOR);
        } else {
            methodType = getRemoteMethod(serviceType, String.valueOf(methodName));
        }
        if (methodType != null) {
            BString identifier = StringUtils.fromString(getModule().toString() + COLON + RESOURCE_CONFIG);
            return methodType.getAnnotation(identifier);
        }
        return null;
    }

    public static boolean hasPrefetchMethod(BObject serviceObject, BString prefetchMethodName) {
        ServiceType serviceType = (ServiceType) serviceObject.getOriginalType();
        return Arrays.stream(serviceType.getMethods())
                .anyMatch(methodType -> methodType.getName().equals(prefetchMethodName.getValue()));
    }

    public static void executePrefetchMethod(Environment environment, BObject context, BObject service,
                                             MethodType resourceMethod, BObject fieldObject) {
        environment.yieldAndRun(() -> {
            CompletableFuture<Object> future = new CompletableFuture<>();
            ExecutionCallback executionCallback = new ExecutionCallback(future);
            ArgumentHandler argumentHandler = new ArgumentHandler(resourceMethod, context, fieldObject, null, false);
            Object[] arguments = argumentHandler.getArguments();
            try {
                Object result = callResourceMethod(environment.getRuntime(), service, resourceMethod.getName(),
                        arguments);
                executionCallback.notifySuccess(result);
            } catch (BError bError) {
                executionCallback.notifyFailure(bError);
            }
            return null;
        });
    }

    public static boolean hasRecordReturnType(BObject serviceObject, BArray path) {
        ResourceMethodType resourceMethod = (ResourceMethodType) getResourceMethod(serviceObject, path);
        if (resourceMethod == null) {
            return false;
        }
        return isRecordReturnType(resourceMethod.getType().getReturnType());
    }

    static boolean isRecordReturnType(Type returnType) {
        if (returnType.getTag() == TypeTags.UNION_TAG) {
            for (Type memberType : ((UnionType) returnType).getMemberTypes()) {
                if (isRecordReturnType(memberType)) {
                    return true;
                }
            }
        } else if (returnType.getTag() == TypeTags.INTERSECTION_TAG) {
            Type effectiveType = TypeUtils.getReferredType(getEffectiveType((IntersectionType) returnType));
            return isRecordReturnType(effectiveType);
        } else if (returnType.getTag() == TypeTags.TYPE_REFERENCED_TYPE_TAG) {
            return isRecordReturnType(TypeUtils.getReferredType(returnType));
        }
        return returnType.getTag() == TypeTags.RECORD_TYPE_TAG;
    }

    public static HashMap<String, Object> getPropertiesToPropagate(Environment environment, BObject context) {
        HashMap<String, Object> properties = new HashMap<>();
        ObserverContext observerContext = (ObserverContext) context.getNativeData(KEY_OBSERVER_CONTEXT);
        if (observerContext == null) {
            observerContext = ObserveUtils.getObserverContextOfCurrentFrame(environment);
        }
        if (observerContext != null) {
            properties.put(KEY_OBSERVER_CONTEXT, observerContext);
        }
        return properties;
    }
}
