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
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.IS_FRAGMENT_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.KEY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NODE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ON_TYPE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SELECTIONS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.TYPENAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.copyAndUpdateResourcePathsList;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.createDataRecord;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.getErrorDetailRecord;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.getNameFromRecordTypeMap;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isScalarType;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.updatePathSegments;

/**
 * Used to generate the response for a GraphQL request in Ballerina.
 */
public class ResponseGenerator {
    private ResponseGenerator() {
    }

    static void populateResponse(ResultContext resultContext, BObject node, Object result,
                                 BMap<BString, Object> data, List<Object> pathSegments) {
        if (TYPENAME_FIELD.equals(node.getStringValue(NAME_FIELD).getValue())) {
            data.put(node.getStringValue(ALIAS_FIELD), StringUtils.fromString(resultContext.getTypeName()));
        } else if (result instanceof BError) {
            BError bError = (BError) result;
            appendErrorToVisitor(bError, resultContext.getVisitor(), node, pathSegments);
        } else if (result instanceof BValue) {
            int tag = ((BValue) result).getType().getTag();
            if (tag < TypeTags.JSON_TAG) {
                data.put(node.getStringValue(ALIAS_FIELD), result);
            } else if (tag == TypeTags.RECORD_TYPE_TAG) {
                getDataFromRecord(resultContext, node, (BMap<BString, Object>) result, data, pathSegments);
            } else if (tag == TypeTags.MAP_TAG) {
                getDataFromMap(resultContext, node, (BMap<BString, Object>) result, data, pathSegments);
            } else if (tag == TypeTags.ARRAY_TAG) {
                getDataFromArray(resultContext, node, (BArray) result, data, pathSegments);
            } else if (tag == TypeTags.TABLE_TAG) {
                getDataFromTable(resultContext, node, (BTable) result, data, pathSegments);
            } else if (tag == TypeTags.SERVICE_TAG) {
                getDataFromService(resultContext, (BObject) result, node, data, new ArrayList<>(), pathSegments);
            } // Here, `else` should not be reached.
        } else {
            data.put(node.getStringValue(ALIAS_FIELD), result);
        }
    }

    static void getDataFromService(ResultContext resultContext, BObject service, BObject node,
                                   BMap<BString, Object> data, List<String> paths, List<Object> pathSegments) {
        ResourceCallback callback = new ResourceCallback(resultContext, node, createDataRecord(), pathSegments);
        resultContext.getCallbackHandler().addCallback(callback);
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        BMap<BString, Object> subData = createDataRecord();
        if (TYPENAME_FIELD.equals(node.getStringValue(NAME_FIELD).getValue())) {
            data.put(node.getStringValue(ALIAS_FIELD), StringUtils.fromString(resultContext.getTypeName()));
        } else {
            resultContext.setTypeName(service.getType().getName());
            for (int i = 0; i < selections.size(); i++) {
                BMap<BString, Object> selection = (BMap<BString, Object>) selections.get(i);
                boolean isFragment = selection.getBooleanValue(IS_FRAGMENT_FIELD);
                BObject subNode = selection.getObjectValue(NODE_FIELD);
                if (isFragment) {
                    if (service.getType().getName().equals(subNode.getStringValue(ON_TYPE_FIELD).getValue())) {
                        executeResourceForFragmentNodes(resultContext, service, subNode, subData, paths, pathSegments);
                    }
                } else {
                    executeResourceWithPath(resultContext, subNode, service, subData, paths, pathSegments);
                }
                data.put(node.getStringValue(ALIAS_FIELD), subData);
            }
        }
        resultContext.getCallbackHandler().markComplete(callback);
    }

    static void getDataFromRecord(ResultContext resultContext, BObject node, BMap<BString, Object> record,
                                  BMap<BString, Object> data, List<Object> pathSegments) {
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        resultContext.setTypeName(record.getType().getName());
        BMap<BString, Object> subData = createDataRecord();
        for (int i = 0; i < selections.size(); i++) {
            BMap<BString, Object> selection = (BMap<BString, Object>) selections.get(i);
            boolean isFragment = selection.getBooleanValue(IS_FRAGMENT_FIELD);
            BObject subNode = selection.getObjectValue(NODE_FIELD);
            if (isFragment) {
                if (subNode.getStringValue(ON_TYPE_FIELD).getValue().equals(getNameFromRecordTypeMap(record))) {
                    processFragmentNodes(resultContext, subNode, record, subData, pathSegments);
                }
            } else {
                BString fieldName = subNode.getStringValue(NAME_FIELD);
                Object fieldValue = record.get(fieldName);
                List<Object> updatedPathSegments =
                        updatePathSegments(pathSegments, node.getStringValue(NAME_FIELD).getValue());
                populateResponse(resultContext, subNode, fieldValue, subData, updatedPathSegments);
            }
        }
        data.put(node.getStringValue(ALIAS_FIELD), subData);
    }

    static void getDataFromMap(ResultContext resultContext, BObject node, BMap<BString, Object> map,
                               BMap<BString, Object> data, List<Object> pathSegments) {
        BMap<BString, Object> arguments = getArgumentsFromField(node);
        BString key = arguments.getStringValue(StringUtils.fromString(KEY));
        Object result = map.get(key);
        populateResponse(resultContext, node, result, data, pathSegments);
    }

    static void getDataFromArray(ResultContext resultContext, BObject node, BArray result, BMap<BString, Object> data,
                                 List<Object> pathSegments) {
        if (isScalarType(result.getElementType())) {
            data.put(node.getStringValue(ALIAS_FIELD), result);
        } else {
            BArray resultArray = ValueCreator.createArrayValue(getDataRecordArrayType());
            for (int i = 0; i < result.size(); i++) {
                List<Object> updatedPathSegments = updatePathSegments(pathSegments, i);
                Object resultElement = result.get(i);
                BMap<BString, Object> subData = createDataRecord();
                populateResponse(resultContext, node, resultElement, subData, updatedPathSegments);
                resultArray.append(subData.get(node.getStringValue(NAME_FIELD)));
            }
            data.put(node.getStringValue(ALIAS_FIELD), resultArray);
        }
    }

    private static void getDataFromTable(ResultContext resultContext, BObject node, BTable table,
                                         BMap<BString, Object> data, List<Object> pathSegments) {
        Object[] valueArray = table.values().toArray();
        ArrayType arrayType = TypeCreator.createArrayType(((BValue) valueArray[0]).getType());
        BArray valueBArray = ValueCreator.createArrayValue(valueArray, arrayType);
        populateResponse(resultContext, node, valueBArray, data, pathSegments);
    }

    static void processFragmentNodes(ResultContext resultContext, BObject node, BMap<BString, Object> record,
                                     BMap<BString, Object> data, List<Object> pathSegments) {
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        for (int i = 0; i < selections.size(); i++) {
            BMap<BString, Object> selection = (BMap<BString, Object>) selections.get(i);
            boolean isFragment = selection.getBooleanValue(IS_FRAGMENT_FIELD);
            BObject subNode = selection.getObjectValue(NODE_FIELD);
            if (isFragment) {
                processFragmentNodes(resultContext, subNode, record, data, pathSegments);
            } else {
                BString fieldName = subNode.getStringValue(NAME_FIELD);
                Object fieldValue = record.get(fieldName);
                List<Object> updatedPathSegments = updatePathSegments(pathSegments,
                                                                      node.getStringValue(NAME_FIELD).getValue());
                populateResponse(resultContext, subNode, fieldValue, data, updatedPathSegments);
            }
        }
    }

    private static void executeResourceForFragmentNodes(ResultContext resultContext, BObject service,
                                                        BObject node, BMap<BString, Object> data, List<String> paths,
                                                        List<Object> pathSegments) {
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        for (int i = 0; i < selections.size(); i++) {
            BMap<BString, Object> selection = (BMap<BString, Object>) selections.get(i);
            boolean isFragment = selection.getBooleanValue(IS_FRAGMENT_FIELD);
            BObject subNode = selection.getObjectValue(NODE_FIELD);
            if (isFragment) {
                executeResourceForFragmentNodes(resultContext, service, subNode, data, paths, pathSegments);
            } else {
                executeResourceWithPath(resultContext, subNode, service, data, paths, pathSegments);
            }
        }
    }

    private static void executeResourceWithPath(ResultContext resultContext, BObject node, BObject service,
                                                BMap<BString, Object> data, List<String> paths,
                                                List<Object> pathSegments) {
        List<String> updatedPaths = copyAndUpdateResourcePathsList(paths, node);
        List<Object> updatedPathSegments = updatePathSegments(pathSegments, node.getStringValue(NAME_FIELD).getValue());
        executeResourceMethod(resultContext, service, node, data, updatedPaths, updatedPathSegments);
    }

    private static ArrayType getDataRecordArrayType() {
        BMap<BString, Object> data = createDataRecord();
        return TypeCreator.createArrayType(data.getType());
    }

    static void appendErrorToVisitor(BError bError, BObject visitor, BObject node, List<Object> pathSegments) {
        BArray errors = visitor.getArrayValue(ERRORS_FIELD);
        errors.append(getErrorDetailRecord(bError, node, pathSegments));
    }
}
