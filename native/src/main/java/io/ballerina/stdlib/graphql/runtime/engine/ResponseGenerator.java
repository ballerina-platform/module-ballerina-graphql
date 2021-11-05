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

import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTable;
import io.ballerina.runtime.api.values.BValue;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.stdlib.graphql.runtime.engine.Engine.executeResourceMethod;
import static io.ballerina.stdlib.graphql.runtime.engine.Engine.getArgumentsFromField;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ALIAS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ERRORS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FRAGMENT_NODE;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.KEY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ON_TYPE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SELECTIONS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.TYPENAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.copyAndUpdateResourcePathsList;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.createDataRecord;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.getErrorDetailRecord;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isScalarType;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.updatePathSegments;

/**
 * Used to generate the response for a GraphQL request in Ballerina.
 */
public class ResponseGenerator {
    private ResponseGenerator() {
    }

    static void populateResponse(ExecutionContext executionContext, BObject node, Object result,
                                 BMap<BString, Object> data, List<Object> pathSegments) {
        if (TYPENAME_FIELD.equals(node.getStringValue(NAME_FIELD).getValue())) {
            data.put(node.getStringValue(ALIAS_FIELD), StringUtils.fromString(executionContext.getTypeName()));
        } else if (result instanceof BError) {
            data.put(node.getStringValue(ALIAS_FIELD), null);
            BError bError = (BError) result;
            appendErrorToVisitor(bError, executionContext.getVisitor(), node, pathSegments);
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
                if (FRAGMENT_NODE.equals(typeName)) {
                    if (service.getType().getName().equals(subNode.getStringValue(ON_TYPE_FIELD).getValue())) {
                        executeResourceForFragmentNodes(executionContext, service, subNode, subData, paths,
                                                        pathSegments);
                    }
                } else {
                    executeResourceWithPath(executionContext, subNode, service, subData, paths, pathSegments);
                }
                data.put(node.getStringValue(ALIAS_FIELD), subData);
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
        BMap<BString, Object> arguments = getArgumentsFromField(node);
        BString key = arguments.getStringValue(StringUtils.fromString(KEY));
        Object result = map.get(key);
        populateResponse(executionContext, node, result, data, pathSegments);
    }

    static void getDataFromArray(ExecutionContext executionContext, BObject node, BArray result,
                                 BMap<BString, Object> data, List<Object> pathSegments) {
        if (isScalarType(result.getElementType())) {
            data.put(node.getStringValue(ALIAS_FIELD), result);
        } else {
            BArray resultArray = ValueCreator.createArrayValue(getDataRecordArrayType());
            for (int i = 0; i < result.size(); i++) {
                List<Object> updatedPathSegments = updatePathSegments(pathSegments, i);
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
            data.put(node.getStringValue(ALIAS_FIELD), resultArray);
        }
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

    private static ArrayType getDataRecordArrayType() {
        BMap<BString, Object> data = createDataRecord();
        return TypeCreator.createArrayType(data.getType());
    }

    static void appendErrorToVisitor(BError bError, BObject visitor, BObject node, List<Object> pathSegments) {
        BArray errors = visitor.getArrayValue(ERRORS_FIELD);
        errors.append(getErrorDetailRecord(bError, node, pathSegments));
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
}
