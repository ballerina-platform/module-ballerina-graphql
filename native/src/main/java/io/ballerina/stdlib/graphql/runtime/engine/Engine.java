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
import io.ballerina.runtime.api.Parameter;
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.RemoteMethodType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.graphql.runtime.schema.FieldFinder;
import io.ballerina.stdlib.graphql.runtime.schema.SchemaRecordGenerator;
import io.ballerina.stdlib.graphql.runtime.schema.TypeFinder;
import io.ballerina.stdlib.graphql.runtime.schema.types.Schema;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ARGUMENTS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.DATA_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ENGINE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.GRAPHQL_SERVICE_OBJECT;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SCHEMA_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VARIABLE_DEFINITION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VARIABLE_VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isPathsMatching;
import static io.ballerina.stdlib.graphql.runtime.engine.ResponseGenerator.getDataFromService;
import static io.ballerina.stdlib.graphql.runtime.engine.ResponseGenerator.populateResponse;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.REMOTE_STRAND_METADATA;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.RESOURCE_STRAND_METADATA;

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
            return e;
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
        executeResourceMethod(environment, service, visitor, node, data, paths, pathSegments, callbackHandler);
    }

    public static void executeMutation(Environment environment, BObject visitor, BObject node) {
        BObject engine = visitor.getObjectValue(ENGINE_FIELD);
        BMap<BString, Object> data = visitor.getMapValue(DATA_FIELD);
        Future future = environment.markAsync();
        BObject service = (BObject) engine.getNativeData(GRAPHQL_SERVICE_OBJECT);
        String fieldName = node.getStringValue(NAME_FIELD).getValue();
        CallbackHandler callbackHandler = new CallbackHandler(future);
        List<Object> pathSegments = new ArrayList<>();
        pathSegments.add(fieldName);
        executeRemoteMethod(environment, service, visitor, node, data, pathSegments, callbackHandler);
    }

    public static void executeIntrospection(Environment environment, BObject visitor, BObject node) {
        BMap<BString, Object> schemaRecord = visitor.getMapValue(SCHEMA_FIELD);
        BMap<BString, Object> data = visitor.getMapValue(DATA_FIELD);
        List<Object> pathSegments = new ArrayList<>();
        pathSegments.add(StringUtils.fromString(node.getStringValue(NAME_FIELD).getValue()));
        populateResponse(environment, visitor, node, schemaRecord, data, pathSegments, null);
    }

    static void executeResourceMethod(Environment environment, BObject service, BObject visitor, BObject node,
                                      BMap<BString, Object> data, List<String> paths, List<Object> pathSegments,
                                      CallbackHandler callbackHandler) {
        ServiceType serviceType = (ServiceType) service.getType();
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            if (isPathsMatching(resourceMethod, paths)) {
                getExecutionResult(environment, service, visitor, node, resourceMethod, data, callbackHandler,
                                   pathSegments);
                return;
            }
        }
        // The resource not found. This should be a resource with hierarchical paths
        getDataFromService(environment, service, visitor, node, data, paths, pathSegments, callbackHandler);
    }

    static void executeRemoteMethod(Environment environment, BObject service, BObject visitor, BObject node,
                                    BMap<BString, Object> data, List<Object> pathSegments,
                                    CallbackHandler callbackHandler) {
        ServiceType serviceType = (ServiceType) service.getType();
        BString fieldName = node.getStringValue(NAME_FIELD);
        for (RemoteMethodType remoteMethod : serviceType.getRemoteMethods()) {
            if (remoteMethod.getName().equals(fieldName.getValue())) {
                getExecutionResult(environment, service, visitor, node, remoteMethod, data, callbackHandler,
                                   pathSegments);
                return;
            }
        }
    }

    private static void getExecutionResult(Environment environment, BObject service, BObject visitor, BObject node,
                                           ResourceMethodType resourceMethod, BMap<BString, Object> data,
                                           CallbackHandler callbackHandler, List<Object> pathSegments) {
        BMap<BString, Object> arguments = getArgumentsFromField(node);
        Object[] args = getArgsForMethod(resourceMethod.getParameters(), resourceMethod.getParameterTypes(), arguments);
        ResourceCallback callback =
                new ResourceCallback(environment, visitor, node, data, callbackHandler, pathSegments);
        callbackHandler.addCallback(callback);
        environment.getRuntime().invokeMethodAsync(service, resourceMethod.getName(), null, RESOURCE_STRAND_METADATA,
                                                   callback, args);
    }

    private static void getExecutionResult(Environment environment, BObject service, BObject visitor, BObject node,
                                           RemoteMethodType remoteMethod, BMap<BString, Object> data,
                                           CallbackHandler callbackHandler, List<Object> pathSegments) {
        BMap<BString, Object> arguments = getArgumentsFromField(node);
        Object[] args = getArgsForMethod(remoteMethod.getParameters(), remoteMethod.getParameterTypes(), arguments);
        ResourceCallback callback =
                new ResourceCallback(environment, visitor, node, data, callbackHandler, pathSegments);
        callbackHandler.addCallback(callback);
        environment.getRuntime().invokeMethodAsync(service, remoteMethod.getName(), null, REMOTE_STRAND_METADATA,
                                                   callback, args);
    }

    public static BMap<BString, Object> getArgumentsFromField(BObject node) {
        BMap<BString, Object> argumentsMap = ValueCreator.createMapValue();
        getScalarTypeArgument(node, argumentsMap);
        return argumentsMap;
    }

    public static void getScalarTypeArgument(BObject node, BMap<BString, Object> argumentsMap) {
        BArray argumentArray = node.getArrayValue(ARGUMENTS_FIELD);
        for (int i = 0; i < argumentArray.size(); i++) {
            BObject argumentNode = (BObject) argumentArray.get(i);
            BString argName = argumentNode.getStringValue(NAME_FIELD);
            BMap<BString, Object> objectFields = argumentNode.getMapValue(VALUE_FIELD);
            if (objectFields.isEmpty()) {
                if (argumentNode.getBooleanValue(VARIABLE_DEFINITION)) {
                    Object value = argumentNode.get(VARIABLE_VALUE_FIELD);
                    argumentsMap.put(argName, value);
                }
            } else {
                if (objectFields.getType().getTag() == TypeTags.RECORD_TYPE_TAG) {
                    Object argValue = objectFields.get(VALUE_FIELD);
                    argumentsMap.put(argName, argValue);
                } else {
                    BMap<BString, Object> inputObjectFieldMap = ValueCreator.createMapValue();
                    getInputObjectTypeArgument(objectFields, inputObjectFieldMap);
                    argumentsMap.put(argName, inputObjectFieldMap);
                }
            }
        }
    }

    public static void getInputObjectTypeArgument(BMap<BString, Object> objectFields,
                                                  BMap<BString, Object> inputObjectMap) {
        for (Map.Entry<BString, Object> entry : objectFields.entrySet()) {
            BString fieldName = entry.getKey();
            if (entry.getValue() instanceof BMap) {
                BMap<BString, Object> argumentValueRecord = (BMap<BString, Object>) entry.getValue();
                Object argValue = argumentValueRecord.get(VALUE_FIELD);
                inputObjectMap.put(fieldName, argValue);
            } else {
                BObject value = (BObject) entry.getValue();
                BMap<BString, Object> nestedInputObjectFieldMap = ValueCreator.createMapValue();
                BMap<BString, Object> nestedObjectFields = value.getMapValue(VALUE_FIELD);
                if (nestedObjectFields.isEmpty()) {
                    if (value.getBooleanValue(VARIABLE_DEFINITION)) {
                        Object fieldValue = value.get(VARIABLE_VALUE_FIELD);
                        inputObjectMap.put(fieldName, fieldValue);
                    }
                } else if (nestedObjectFields.getType().getTag() == TypeTags.RECORD_TYPE_TAG) {
                    Object argValue = objectFields.get(VALUE_FIELD);
                    inputObjectMap.put(fieldName, argValue);
                } else {
                    getInputObjectTypeArgument(nestedObjectFields, nestedInputObjectFieldMap);
                    inputObjectMap.put(fieldName, nestedInputObjectFieldMap);
                }
            }
        }
    }

    private static Object[] getArgsForMethod(Parameter[] parameters, Type[] types, BMap<BString, Object> arguments) {
        Object[] result = new Object[parameters.length * 2];
        for (int i = 0, j = 0; i < parameters.length; i += 1, j += 2) {
            if (arguments.get(StringUtils.fromString(parameters[i].name)) == null) {
                result[j] = types[i].getZeroValue();
                result[j + 1] = false;
            } else {
                result[j] = arguments.get(StringUtils.fromString(parameters[i].name));
                result[j + 1] = true;
            }
        }
        return result;
    }
}
