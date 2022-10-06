/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTable;
import io.ballerina.runtime.api.values.BValue;
import io.ballerina.stdlib.graphql.compiler.schema.types.TypeKind;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import static io.ballerina.stdlib.graphql.runtime.engine.Engine.executeResourceMethod;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ALIAS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ARGUMENTS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ERRORS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FRAGMENT_NODE;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.KEY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.KIND_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ON_TYPE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.POSSIBLE_TYPES_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SCHEMA_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SELECTIONS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.TYPENAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.TYPES_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VARIABLE_DEFINITION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VARIABLE_VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.copyAndUpdateResourcePathsList;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.createDataRecord;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.getErrorDetailRecord;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.getMemberTypes;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.getTypeFromTypeArray;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isEnum;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isScalarType;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.logError;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.updatePathSegments;

/**
 * Used to generate the response for a GraphQL request in Ballerina.
 */
public class ResponseGenerator {
    private ResponseGenerator() {
    }

    static synchronized void populateResponse(ExecutionContext executionContext, BObject node, Object result,
                                              BMap<BString, Object> data, List<Object> pathSegments) {
        if (TYPENAME_FIELD.equals(node.getStringValue(NAME_FIELD).getValue())) {
            data.put(node.getStringValue(ALIAS_FIELD), StringUtils.fromString(executionContext.getTypeName()));
        } else if (result instanceof BError) {
            data.put(node.getStringValue(ALIAS_FIELD), null);
            BError bError = (BError) result;
            appendErrorToVisitor(bError, executionContext, node, pathSegments);
        } else if (result instanceof BValue) {
            int tag = ((BValue) result).getType().getTag();
            if (tag < TypeTags.JSON_TAG) {
                data.put(node.getStringValue(ALIAS_FIELD), result);
            } else if (tag == TypeTags.RECORD_TYPE_TAG) {
                getDataFromRecord(executionContext, node, (BMap<BString, Object>) result, data, pathSegments);
            } else if (tag == TypeTags.MAP_TAG) {
                getDataFromMap(executionContext, node, (BMap<BString, Object>) result, data, pathSegments);
            } else if (tag == TypeTags.ARRAY_TAG) {
                getDataFromArray(executionContext, node, (BArray) result, data, pathSegments);
            } else if (tag == TypeTags.TABLE_TAG) {
                getDataFromTable(executionContext, node, (BTable) result, data, pathSegments);
            } else if (tag == TypeTags.SERVICE_TAG) {
                getDataFromService(executionContext, (BObject) result, node, data, new ArrayList<>(), pathSegments);
            } // Here, `else` should not be reached.
        } else {
            data.put(node.getStringValue(ALIAS_FIELD), result);
        }
    }

    static void getDataFromService(ExecutionContext executionContext, BObject service, BObject node,
                                   BMap<BString, Object> data, List<String> paths, List<Object> pathSegments) {
        ResourceCallback callback = new ResourceCallback(executionContext, node, createDataRecord(), pathSegments);
        executionContext.getCallbackHandler().addCallback(callback);
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        BMap<BString, Object> subData = createDataRecord();
        if (TYPENAME_FIELD.equals(node.getStringValue(NAME_FIELD).getValue())) {
            data.put(node.getStringValue(ALIAS_FIELD), StringUtils.fromString(executionContext.getTypeName()));
        } else {
            executionContext.setTypeName(service.getType().getName());
            for (int i = 0; i < selections.size(); i++) {
                BObject subNode = (BObject) selections.get(i);
                BString typeName = StringUtils.fromString(subNode.getType().getName());
                data.put(node.getStringValue(ALIAS_FIELD), subData);
                if (FRAGMENT_NODE.equals(typeName)) {
                    if (isValidOnType(executionContext, service, subNode)) {
                        executeResourceForFragmentNodes(executionContext, service, subNode, subData, paths,
                                                        pathSegments);
                    }
                } else {
                    executeResourceWithPath(executionContext, subNode, service, subData, paths, pathSegments);
                }
            }
        }
        executionContext.getCallbackHandler().markComplete(callback);
    }

    static void getDataFromRecord(ExecutionContext executionContext, BObject node, BMap<BString, Object> record,
                                  BMap<BString, Object> data, List<Object> pathSegments) {
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        String recordTypeName = getTypeNameFromRecordValue((RecordType) record.getType());
        executionContext.setTypeName(recordTypeName);
        BMap<BString, Object> subData = createDataRecord();
        for (int i = 0; i < selections.size(); i++) {
            BObject subNode = (BObject) selections.get(i);
            BString typeName = StringUtils.fromString(subNode.getType().getName());
            if (FRAGMENT_NODE.equals(typeName)) {
                if (subNode.getStringValue(ON_TYPE_FIELD).getValue().equals(recordTypeName)) {
                    processFragmentNodes(executionContext, subNode, record, subData, pathSegments);
                }
            } else {
                BString fieldName = subNode.getStringValue(NAME_FIELD);
                Object fieldValue = record.get(fieldName);
                List<Object> updatedPathSegments =
                        updatePathSegments(pathSegments, node.getStringValue(NAME_FIELD).getValue());
                populateResponse(executionContext, subNode, fieldValue, subData, updatedPathSegments);
            }
        }
        data.put(node.getStringValue(ALIAS_FIELD), subData);
    }

    static void getDataFromMap(ExecutionContext executionContext, BObject node, BMap<BString, Object> map,
                               BMap<BString, Object> data, List<Object> pathSegments) {
        BArray argumentArray = node.getArrayValue(ARGUMENTS_FIELD);
        for (int i = 0; i < argumentArray.size(); i++) {
            BObject argumentNode = (BObject) argumentArray.get(i);
            if (Objects.equals(StringUtils.fromString(KEY), argumentNode.getStringValue(NAME_FIELD))) {
                if (argumentNode.getBooleanValue(VARIABLE_DEFINITION)) {
                    BString key = argumentNode.getStringValue(VARIABLE_VALUE_FIELD);
                    Object result = map.get(key);
                    populateResponse(executionContext, node, result, data, pathSegments);
                } else {
                    BString key = argumentNode.getStringValue(VALUE_FIELD);
                    Object result = map.get(key);
                    populateResponse(executionContext, node, result, data, pathSegments);
                }
            }
        }
    }

    static void getDataFromArray(ExecutionContext executionContext, BObject node, BArray result,
                                 BMap<BString, Object> data, List<Object> pathSegments) {
        BArray resultArray = ValueCreator.createArrayValue(getArrayType(result.getElementType()));
        for (int i = 0; i < result.size(); i++) {
            List<Object> updatedPathSegments = updatePathSegments(pathSegments, i);
            if (isScalarType(result.getElementType())) {
                if (result.get(i) instanceof BError) {
                    resultArray.append(null);
                    BError bError = (BError) result.get(i);
                    appendErrorToVisitor(bError, executionContext, node, updatedPathSegments);
                } else {
                    resultArray.append(result.get(i));
                }
            } else {
                Object resultElement = result.get(i);
                BMap<BString, Object> subData = createDataRecord();
                populateResponse(executionContext, node, resultElement, subData, updatedPathSegments);
                if (result.get(i) instanceof BError) {
                    BMap<BString, Object> subField = createDataRecord();
                    subField.put(node.getStringValue(NAME_FIELD), null);
                    resultArray.append(subField);
                } else {
                    resultArray.append(subData.get(node.getStringValue(NAME_FIELD)));
                }
            }
        }
        data.put(node.getStringValue(ALIAS_FIELD), resultArray);
    }

    private static void getDataFromTable(ExecutionContext executionContext, BObject node, BTable table,
                                         BMap<BString, Object> data, List<Object> pathSegments) {
        Object[] valueArray = table.values().toArray();
        ArrayType arrayType = TypeCreator.createArrayType(((BValue) valueArray[0]).getType());
        BArray valueBArray = ValueCreator.createArrayValue(valueArray, arrayType);
        populateResponse(executionContext, node, valueBArray, data, pathSegments);
    }

    static void processFragmentNodes(ExecutionContext executionContext, BObject node, BMap<BString, Object> record,
                                     BMap<BString, Object> data, List<Object> pathSegments) {
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        for (int i = 0; i < selections.size(); i++) {
            BObject subNode = (BObject) selections.get(i);
            BString typeName = StringUtils.fromString(subNode.getType().getName());
            if (FRAGMENT_NODE.equals(typeName)) {
                processFragmentNodes(executionContext, subNode, record, data, pathSegments);
            } else {
                BString fieldName = subNode.getStringValue(NAME_FIELD);
                Object fieldValue = record.get(fieldName);
                List<Object> updatedPathSegments = updatePathSegments(pathSegments,
                                                                      node.getStringValue(NAME_FIELD).getValue());
                populateResponse(executionContext, subNode, fieldValue, data, updatedPathSegments);
            }
        }
    }

    private static void executeResourceForFragmentNodes(ExecutionContext executionContext, BObject service,
                                                        BObject node, BMap<BString, Object> data, List<String> paths,
                                                        List<Object> pathSegments) {
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        for (int i = 0; i < selections.size(); i++) {
            BObject subNode = (BObject) selections.get(i);
            BString typeName = StringUtils.fromString(subNode.getType().getName());
            if (FRAGMENT_NODE.equals(typeName)) {
                executeResourceForFragmentNodes(executionContext, service, subNode, data, paths, pathSegments);
            } else {
                executeResourceWithPath(executionContext, subNode, service, data, paths, pathSegments);
            }
        }
    }

    private static void executeResourceWithPath(ExecutionContext executionContext, BObject node, BObject service,
                                                BMap<BString, Object> data, List<String> paths,
                                                List<Object> pathSegments) {
        List<String> updatedPaths = copyAndUpdateResourcePathsList(paths, node);
        List<Object> updatedPathSegments = updatePathSegments(pathSegments, node.getStringValue(NAME_FIELD).getValue());
        executeResourceMethod(executionContext, service, node, data, updatedPaths, updatedPathSegments);
    }

    private static ArrayType getArrayType(Type elementType) {
        UnionType arrayType;
        if (isScalarType(elementType)) {
            int tag = elementType.getTag();
            if (tag == TypeTags.UNION_TAG) {
                if (isEnum((UnionType) elementType)) {
                    arrayType = TypeCreator.createUnionType(PredefinedTypes.TYPE_NULL, elementType);
                } else {
                    List<Type> memberTypes = getMemberTypes((UnionType) elementType);
                    memberTypes.add(PredefinedTypes.TYPE_NULL);
                    arrayType = TypeCreator.createUnionType(memberTypes);
                }
            } else {
                arrayType = TypeCreator.createUnionType(PredefinedTypes.TYPE_NULL, elementType);
            }
        } else {
            BMap<BString, Object> data = createDataRecord();
            arrayType = TypeCreator.createUnionType(PredefinedTypes.TYPE_NULL, data.getType());
        }
        return TypeCreator.createArrayType(arrayType);
    }

    static void appendErrorToVisitor(BError bError, ExecutionContext executionContext, BObject node,
                                     List<Object> pathSegments) {
        BArray errors = executionContext.getVisitor().getArrayValue(ERRORS_FIELD);
        errors.append(getErrorDetailRecord(bError, node, pathSegments));
        logError(executionContext, bError);
    }

    private static String getTypeNameFromRecordValue(RecordType recordType) {
        if (recordType.getName().contains("&") && recordType.getIntersectionType().isPresent()) {
            for (Type constituentType : recordType.getIntersectionType().get().getConstituentTypes()) {
                if (constituentType.getTag() != TypeTags.READONLY_TAG) {
                    return constituentType.getName();
                }
            }
        }
        return recordType.getName();
    }

    @SuppressWarnings("unchecked")
    private static boolean isValidOnType(ExecutionContext executionContext, BObject service, BObject node) {
        String typeName = service.getType().getName();
        BString onTypeName = node.getStringValue(ON_TYPE_FIELD);
        if (typeName.equals(onTypeName.getValue())) {
            return true;
        }
        BMap<BString, Object> schema = executionContext.getVisitor().getMapValue(SCHEMA_FIELD);
        BArray types = schema.getArrayValue(TYPES_FIELD);
        BMap<BString, Object> onType = getTypeFromTypeArray(onTypeName.getValue(), types);
        if (onType == null) {
            return false;
        }
        if (!TypeKind.INTERFACE.toString().equals(onType.getStringValue(KIND_FIELD).getValue())) {
            return false;
        }
        BArray possibleTypes = onType.getArrayValue(POSSIBLE_TYPES_FIELD);
        if (possibleTypes == null) {
            return false;
        }
        BMap<BString, Object> possibleType = getTypeFromTypeArray(typeName, possibleTypes);
        return possibleType != null;
    }
}
