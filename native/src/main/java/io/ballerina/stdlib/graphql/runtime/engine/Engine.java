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
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.async.StrandMetadata;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.Parameter;
import io.ballerina.runtime.api.types.RecordType;
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
import io.ballerina.runtime.api.values.BValue;
import io.ballerina.stdlib.graphql.runtime.schema.FieldFinder;
import io.ballerina.stdlib.graphql.runtime.schema.SchemaRecordGenerator;
import io.ballerina.stdlib.graphql.runtime.schema.TypeFinder;
import io.ballerina.stdlib.graphql.runtime.schema.types.Schema;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ARGUMENTS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.CONTEXT_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.DATA_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ENGINE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.GRAPHQL_SERVICE_OBJECT;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.KIND_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.MUTATION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.QUERY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SCHEMA_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.T_INPUT_OBJECT;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.T_LIST;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VARIABLE_DEFINITION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VARIABLE_VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isPathsMatching;
import static io.ballerina.stdlib.graphql.runtime.engine.ResponseGenerator.getDataFromService;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.getMemberTypes;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.ERROR_TYPE;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.REMOTE_STRAND_METADATA;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.RESOURCE_STRAND_METADATA;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.createError;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.isContext;

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
            if (isPathsMatching(resourceMethod, paths)) {
                getExecutionResult(executionContext, service, node, resourceMethod, data, pathSegments,
                                   RESOURCE_STRAND_METADATA);
                return;
            }
        }
        // The resource not found. This should be a either a resource with hierarchical paths or introspection query
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
        BMap<BString, Object> arguments = getArgumentsFromField(node, method);
        Object[] args = getArgsForMethod(method, arguments, executionContext);
        ResourceCallback callback =
                new ResourceCallback(executionContext, node, data, pathSegments);
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

    public static BMap<BString, Object> getArgumentsFromField(BObject node, MethodType method) {
        BMap<BString, Object> argumentsMap = ValueCreator.createMapValue();
        getArgument(node, argumentsMap, method);
        return argumentsMap;
    }

    public static void getArgument(BObject node, BMap<BString, Object> argumentsMap, MethodType method) {
        BArray argumentArray = node.getArrayValue(ARGUMENTS_FIELD);
        for (int i = 0; i < argumentArray.size(); i++) {
            BObject argumentNode = (BObject) argumentArray.get(i);
            BString argName = argumentNode.getStringValue(NAME_FIELD);
            Type argType  = getArgumentTypeFromMethod(argName, method);
            if (argumentNode.getBooleanValue(VARIABLE_DEFINITION)) {
                addInputObjectFieldsFromVariableValue(argumentNode, argumentsMap, getNonNullType(argType));
            } else if (argumentNode.getIntValue(KIND_FIELD) == T_INPUT_OBJECT) {
                BArray objectFields = argumentNode.getArrayValue(VALUE_FIELD);
                BMap<BString, Object> inputObjectRecord = ValueCreator.createMapValue(argType);
                addInputObjectTypeArgumentFromNode(objectFields, inputObjectRecord, (RecordType) argType);
                argumentsMap.put(argName, inputObjectRecord);
            } else if (argumentNode.getIntValue(KIND_FIELD) == T_LIST) {
                BArray values = argumentNode.getArrayValue(VALUE_FIELD);
                BArray valueArray = ValueCreator.createArrayValue(getArrayType(argType));
                addListTypeArgumentFromNode(values, valueArray, argType);
                argumentsMap.put(argName, valueArray);
            } else {
                Object argValue = argumentNode.get(VALUE_FIELD);;
                argumentsMap.put(argName, argValue);
            }
        }
    }

    public static void addInputObjectTypeArgumentFromNode(BArray objectFields, BMap<BString, Object> inputObjectRecord,
                                                          RecordType argType) {
        for (int i = 0; i < objectFields.size(); i++) {
            BObject objectFieldNode = (BObject) objectFields.get(i);
            BString fieldName = objectFieldNode.getStringValue(NAME_FIELD);
            Map<String, Field> fields = argType.getFields();
            Type fieldType = fields.get(fieldName.getValue()).getFieldType();
            if (objectFieldNode.getBooleanValue(VARIABLE_DEFINITION)) {
                addInputObjectFieldsFromVariableValue(objectFieldNode, inputObjectRecord, getNonNullType(fieldType));
            } else if (objectFieldNode.getIntValue(KIND_FIELD) == T_INPUT_OBJECT) {
                BArray nestedObjectFields = objectFieldNode.getArrayValue(VALUE_FIELD);
                BMap<BString, Object> nestedInputObjectRecord = ValueCreator.createMapValue(fieldType);
                addInputObjectTypeArgumentFromNode(nestedObjectFields, nestedInputObjectRecord, (RecordType) fieldType);
                inputObjectRecord.put(fieldName, nestedInputObjectRecord);
            } else if (objectFieldNode.getIntValue(KIND_FIELD) == T_LIST) {
                BArray values = objectFieldNode.getArrayValue(VALUE_FIELD);
                BArray valueArray = ValueCreator.createArrayValue(getArrayType(fieldType));
                addListTypeArgumentFromNode(values, valueArray, fieldType);
                inputObjectRecord.put(fieldName, valueArray);
            } else {
                Object argValue = objectFieldNode.get(VALUE_FIELD);
                inputObjectRecord.put(fieldName, argValue);
            }
        }
    }

    public static void addListTypeArgumentFromNode(BArray listItems, BArray valueArray, Type argType) {
        for (int i = 0; i < listItems.size(); i++) {
            BObject listItem = (BObject) listItems.get(i);
            ArrayType arrayType = getArrayType(argType);
            Type elementType = arrayType.getElementType();
            if (listItem.getBooleanValue(VARIABLE_DEFINITION)) {
                addListMembersFromVariableValue(listItem, valueArray, getNonNullType(elementType));
            } else if (listItem.getIntValue(KIND_FIELD) == T_INPUT_OBJECT) {
                BArray inputObjectFields = listItem.getArrayValue(VALUE_FIELD);
                BMap<BString, Object> inputObjectRecord = ValueCreator.createMapValue(elementType);
                addInputObjectTypeArgumentFromNode(inputObjectFields, inputObjectRecord, (RecordType) elementType);
                valueArray.append(inputObjectRecord);
            } else if (listItem.getIntValue(KIND_FIELD) == T_LIST) {
                BArray values = listItem.getArrayValue(VALUE_FIELD);
                BArray nestedValueArray = ValueCreator.createArrayValue(getArrayType(elementType));
                addListTypeArgumentFromNode(values, nestedValueArray, elementType);
                valueArray.append(nestedValueArray);
            } else {
                Object argValue = listItem.get(VALUE_FIELD);
                valueArray.append(argValue);
            }
        }
    }

    public static void addInputObjectFieldsFromVariableValue(BObject argumentNode, BMap<BString, Object> argumentsMap,
                                                             Type argType) {
        BString argName = argumentNode.getStringValue(NAME_FIELD);
        if (argType.getTag() == TypeTags.RECORD_TYPE_TAG) {
            BMap<BString, Object> inputObjectFields = argumentNode.getMapValue(VARIABLE_VALUE_FIELD);
            BMap<BString, Object> inputObjectRecord = ValueCreator.createMapValue(argType);
            visitInputObjectTypeVariableValue(inputObjectFields, inputObjectRecord, (RecordType) argType);
            argumentsMap.put(argName, inputObjectRecord);
        } else if (argType.getTag() == TypeTags.ARRAY_TAG) {
            BArray values = argumentNode.getArrayValue(VARIABLE_VALUE_FIELD);
            BArray valueArray = ValueCreator.createArrayValue(getArrayType(argType));
            visitListTypeVariableValue(values, valueArray, argType);
            argumentsMap.put(argName, valueArray);
        } else {
            Object value = argumentNode.get(VARIABLE_VALUE_FIELD);
            argumentsMap.put(argName, value);
        }
    }

    public static void addListMembersFromVariableValue(BObject listItem, BArray valueArray, Type argType) {
        if (argType.getTag() == TypeTags.RECORD_TYPE_TAG) {
            BMap<BString, Object> inputObjectFields = listItem.getMapValue(VARIABLE_VALUE_FIELD);
            BMap<BString, Object> inputObjectRecord = ValueCreator.createMapValue(argType);
            visitInputObjectTypeVariableValue(inputObjectFields, inputObjectRecord, (RecordType) argType);
            valueArray.append(inputObjectRecord);
        } else if (argType.getTag() == TypeTags.ARRAY_TAG) {
            BArray values = listItem.getArrayValue(VARIABLE_VALUE_FIELD);
            BArray nestedValueArray = ValueCreator.createArrayValue(getArrayType(argType));
            visitListTypeVariableValue(values, nestedValueArray, argType);
            valueArray.append(nestedValueArray);
        } else {
            Object value = listItem.get(VARIABLE_VALUE_FIELD);
            valueArray.append(value);
        }
    }

    public static void visitInputObjectTypeVariableValue(BMap<BString, Object> objectFields,
                                                         BMap<BString, Object> inputObjectRecord, RecordType argType) {
        Map<String, Field> fields = argType.getFields();
        for (Map.Entry<String, Field> stringFieldEntry : fields.entrySet()) {
            BString fieldName = StringUtils.fromString(stringFieldEntry.getKey());
            Type fieldType = stringFieldEntry.getValue().getFieldType();
            if (objectFields.containsKey(fieldName)) {
                if (fieldType.getTag() == TypeTags.RECORD_TYPE_TAG) {
                    BMap<BString, Object> nestedFields = (BMap<BString, Object>) objectFields.getMapValue(fieldName);
                    BMap<BString, Object> nestedInputObjectRecord = ValueCreator.createMapValue(fieldType);
                    visitInputObjectTypeVariableValue(nestedFields, nestedInputObjectRecord, (RecordType) fieldType);
                    inputObjectRecord.put(fieldName, nestedInputObjectRecord);
                } else if (fieldType.getTag() == TypeTags.ARRAY_TAG) {
                    BArray values = objectFields.getArrayValue(fieldName);
                    BArray valueArray = ValueCreator.createArrayValue(getArrayType(fieldType));
                    visitListTypeVariableValue(values, valueArray, fieldType);
                    inputObjectRecord.put(fieldName, valueArray);
                } else {
                    Object argValue = objectFields.get(fieldName);
                    inputObjectRecord.put(fieldName, argValue);
                }
            }
        }
    }

    public static void visitListTypeVariableValue(BArray argumentsArray, BArray valueArray, Type argType) {
        ArrayType arrayType = getArrayType(argType);
        Type elementType = arrayType.getElementType();
        for (int i = 0; i < argumentsArray.size(); i++) {
            if (elementType.getTag() == TypeTags.RECORD_TYPE_TAG) {
                BMap<BString, Object> objectFields = (BMap<BString, Object>) argumentsArray.get(i);
                BMap<BString, Object> inputObjectRecord = ValueCreator.createMapValue(elementType);
                visitInputObjectTypeVariableValue(objectFields, inputObjectRecord, (RecordType) elementType);
                valueArray.append(inputObjectRecord);
            } else if (elementType.getTag() == TypeTags.ARRAY_TAG) {
                BArray values = (BArray) argumentsArray.get(i);
                BArray nestedValueArray = ValueCreator.createArrayValue(getArrayType(elementType));
                visitListTypeVariableValue(values, nestedValueArray, elementType);
                valueArray.append(nestedValueArray);
            } else {
                Object argValue = argumentsArray.get(i);
                valueArray.append(argValue);
            }
        }
    }

    private static Object[] getArgsForMethod(MethodType method, BMap<BString, Object> arguments,
                                             ExecutionContext executionContext) {
        Parameter[] parameters = method.getParameters();
        Object[] result = new Object[parameters.length * 2];
        for (int i = 0, j = 0; i < parameters.length; i += 1, j += 2) {
            if (i == 0 && isContext(parameters[i].type)) {
                result[i] = executionContext.getVisitor().getObjectValue(CONTEXT_FIELD);
                result[j + 1] = true;
                continue;
            }
            if (arguments.get(StringUtils.fromString(parameters[i].name)) == null) {
                result[j] = parameters[i].type.getZeroValue();
                result[j + 1] = false;
            } else {
                result[j] = arguments.get(StringUtils.fromString(parameters[i].name));
                result[j + 1] = true;
            }
        }
        return result;
    }

    private static Type getNonNullType(Type argType) {
        Type nonNullType = argType;
        if (argType.getTag() == TypeTags.UNION_TAG) {
            List<Type> originalMembers = ((UnionType) argType).getOriginalMemberTypes();
            for (Type type : originalMembers) {
                if (type.getTag() != TypeTags.ERROR_TAG || type.getTag() != TypeTags.NULL_TAG) {
                    nonNullType = type;
                    break;
                }
            }
        }
        return nonNullType;
    }

    private static Type getArgumentTypeFromMethod(BString paramName, MethodType method) {
        Parameter[] parameters = method.getParameters();
        Type paramType = TypeCreator.createArrayType(PredefinedTypes.TYPE_NULL);
        for (int i = 0; i < parameters.length; i++) {
            if (parameters[i].name.equals(paramName.getValue())) {
                paramType = parameters[i].type;
            }
        }
        return paramType;
    }

    private static ArrayType getArrayType(Type type) {
        if (type.getTag() == TypeTags.UNION_TAG) {
            List<Type> memberTypes = getMemberTypes((UnionType) type);
            for (Type member : memberTypes) {
                if (member.getTag() == TypeTags.ARRAY_TAG) {
                    return (ArrayType) member;
                }
            }
            return TypeCreator.createArrayType(TypeCreator.createUnionType(memberTypes));
        } else if (type.getTag() == TypeTags.ARRAY_TAG) {
            return (ArrayType) type;
        } else {
            return TypeCreator.createArrayType(type);
        }
    }
}
