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
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.RemoteMethodType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BValue;
import io.ballerina.stdlib.graphql.runtime.schema.FieldFinder;
import io.ballerina.stdlib.graphql.runtime.schema.SchemaRecordGenerator;
import io.ballerina.stdlib.graphql.runtime.schema.TypeFinder;
import io.ballerina.stdlib.graphql.runtime.schema.types.Schema;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.DATA_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ENGINE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.GET_ACCESSOR;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.GRAPHQL_SERVICE_OBJECT;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.MUTATION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.QUERY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SCHEMA_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SUBSCRIBE_ACCESSOR;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SUBSCRIPTION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isPathsMatching;
import static io.ballerina.stdlib.graphql.runtime.engine.ResponseGenerator.getDataFromService;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.ERROR_TYPE;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.REMOTE_STRAND_METADATA;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.RESOURCE_STRAND_METADATA;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.createError;

/**
 * This handles Ballerina GraphQL Engine.
 */
public class Engine {
    private Engine() {
    }

    public static Object createSchema(BObject service) {
        try {
            ServiceType serviceType = (ServiceType) service.getType();
            TypeFinder typeFinder = new TypeFinder(serviceType);
            typeFinder.populateTypes();

            FieldFinder fieldFinder = new FieldFinder(typeFinder.getTypeMap());
            fieldFinder.populateFields();
            Schema schema = new Schema(fieldFinder.getTypeMap());

            SchemaRecordGenerator schemaRecordGenerator = new SchemaRecordGenerator(schema);
            return schemaRecordGenerator.getSchemaRecord();
        } catch (BError e) {
            return createError("Error occurred while creating the schema", ERROR_TYPE, e);
        }
    }

    public static void attachServiceToEngine(BObject service, BObject engine) {
        engine.addNativeData(GRAPHQL_SERVICE_OBJECT, service);
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

    public static void executeIntrospection(Environment environment, BObject visitor, BObject node, BValue result) {
        Future future = environment.markAsync();
        BMap<BString, Object> data = visitor.getMapValue(DATA_FIELD);
        List<Object> pathSegments = new ArrayList<>();
        pathSegments.add(StringUtils.fromString(node.getStringValue(NAME_FIELD).getValue()));
        CallbackHandler callbackHandler = new CallbackHandler(future);
        ExecutionContext executionContext = new ExecutionContext(environment, visitor, callbackHandler, SCHEMA_RECORD);
        ResourceCallback resourceCallback = new ResourceCallback(executionContext, node, data, pathSegments);
        callbackHandler.addCallback(resourceCallback);
        resourceCallback.notifySuccess(result);
    }

    static void executeResourceMethod(ExecutionContext executionContext, BObject service, BObject node,
                                      BMap<BString, Object> data, List<String> paths, List<Object> pathSegments) {
        ServiceType serviceType = (ServiceType) service.getType();
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            if (isPathsMatching(resourceMethod, paths) &&
                Objects.equals(resourceMethod.getAccessor(), GET_ACCESSOR)) {
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
            if (Objects.equals(String.valueOf(fieldName), resourceMethod.getResourcePath()[0]) &&
                Objects.equals(resourceMethod.getAccessor(), SUBSCRIBE_ACCESSOR)) {
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
}
