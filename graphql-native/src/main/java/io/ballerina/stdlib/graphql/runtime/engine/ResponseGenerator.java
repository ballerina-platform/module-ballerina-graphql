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

import io.ballerina.runtime.api.Environment;
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

import static io.ballerina.stdlib.graphql.runtime.engine.Engine.executeResource;
import static io.ballerina.stdlib.graphql.runtime.engine.Engine.getArgumentsFromField;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ERRORS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.IS_FRAGMENT_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.KEY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NODE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ON_TYPE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SELECTIONS_FIELD;
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

    static void populateResponse(Environment environment, BObject visitor, BObject node, Object result,
                                 BMap<BString, Object> data, List<Object> pathSegments,
                                 CallbackHandler callbackHandler) {
        if (result instanceof BError) {
            BError bError = (BError) result;
            appendErrorToVisitor(bError, visitor, node, pathSegments);
        } else if (result instanceof BValue) {
            int tag = ((BValue) result).getType().getTag();
            if (tag < TypeTags.JSON_TAG) {
                data.put(node.getStringValue(NAME_FIELD), result);
            } else if (tag == TypeTags.RECORD_TYPE_TAG) {
                getDataFromRecord(environment, visitor, node, (BMap<BString, Object>) result, data, pathSegments,
                                  callbackHandler);
            } else if (tag == TypeTags.MAP_TAG) {
                getDataFromMap(environment, visitor, node, (BMap<BString, Object>) result, data, pathSegments,
                               callbackHandler);
            } else if (tag == TypeTags.ARRAY_TAG) {
                getDataFromArray(environment, visitor, node, (BArray) result, data, pathSegments, callbackHandler);
            } else if (tag == TypeTags.TABLE_TAG) {
                getDataFromTable(environment, visitor, node, (BTable) result, data, pathSegments, callbackHandler);
            } else if (tag == TypeTags.SERVICE_TAG) {
                getDataFromService(environment, (BObject) result, visitor, node, data, new ArrayList<>(),
                                   pathSegments, callbackHandler);
            } // Here, `else` should not be reached.
        } else {
            data.put(node.getStringValue(NAME_FIELD), result);
        }
    }


    static void getDataFromService(Environment environment, BObject service, BObject visitor, BObject node,
                                   BMap<BString, Object> data, List<String> paths, List<Object> pathSegments,
                                   CallbackHandler handler) {
        ResourceCallback callback =
                new ResourceCallback(environment, visitor, node, createDataRecord(), handler, pathSegments);
        handler.addCallback(callback);
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        BMap<BString, Object> subData = createDataRecord();
        for (int i = 0; i < selections.size(); i++) {
            BMap<BString, Object> selection = (BMap<BString, Object>) selections.get(i);
            boolean isFragment = selection.getBooleanValue(IS_FRAGMENT_FIELD);
            BObject subNode = selection.getObjectValue(NODE_FIELD);
            if (isFragment) {
                if (service.getType().getName().equals(subNode.getStringValue(ON_TYPE_FIELD).getValue())) {
                    executeResourceForFragmentNodes(environment, service, visitor, subNode, subData, paths,
                                                    pathSegments, handler);
                }
            } else {
                executeResourceWithPath(environment, visitor, subNode, service, subData, paths, pathSegments,
                                        handler, i);
            }
            data.put(node.getStringValue(NAME_FIELD), subData);
        }
        handler.markComplete(callback);
    }

    static void getDataFromRecord(Environment environment, BObject visitor, BObject node, BMap<BString, Object> record,
                                  BMap<BString, Object> data, List<Object> pathSegments,
                                  CallbackHandler callbackHandler) {
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        BMap<BString, Object> subData = createDataRecord();
        for (int i = 0; i < selections.size(); i++) {
            BMap<BString, Object> selection = (BMap<BString, Object>) selections.get(i);
            boolean isFragment = selection.getBooleanValue(IS_FRAGMENT_FIELD);
            BObject subNode = selection.getObjectValue(NODE_FIELD);
            if (isFragment) {
                if (subNode.getStringValue(ON_TYPE_FIELD).getValue().equals(getNameFromRecordTypeMap(record))) {
                    processFragmentNodes(environment, visitor, subNode, record, subData, pathSegments, callbackHandler);
                }
            } else {
                BString fieldName = subNode.getStringValue(NAME_FIELD);
                Object fieldValue = record.get(fieldName);
                List<Object> updatedPathSegments =
                        updatePathSegments(pathSegments, node.getStringValue(NAME_FIELD).getValue());
                populateResponse(environment, visitor, subNode, fieldValue, subData, updatedPathSegments,
                                 callbackHandler);
            }
        }
        data.put(node.getStringValue(NAME_FIELD), subData);
    }

    static void getDataFromMap(Environment environment, BObject visitor, BObject node, BMap<BString, Object> map,
                               BMap<BString, Object> data, List<Object> pathSegments,
                               CallbackHandler callbackHandler) {
        BMap<BString, Object> arguments = getArgumentsFromField(node);
        BString key = arguments.getStringValue(StringUtils.fromString(KEY));
        Object result = map.get(key);
        populateResponse(environment, visitor, node, result, data, pathSegments, callbackHandler);
    }

    static void getDataFromArray(Environment environment, BObject visitor, BObject node, BArray result,
                                 BMap<BString, Object> data, List<Object> pathSegments,
                                 CallbackHandler callbackHandler) {
        if (isScalarType(result.getElementType())) {
            data.put(node.getStringValue(NAME_FIELD), result);
        } else {
            BArray resultArray = ValueCreator.createArrayValue(getDataRecordArrayType());
            for (int i = 0; i < result.size(); i++) {
                List<Object> updatedPathSegments = updatePathSegments(pathSegments, i);
                Object resultElement = result.get(i);
                BMap<BString, Object> subData = createDataRecord();
                populateResponse(environment, visitor, node, resultElement, subData, updatedPathSegments,
                                 callbackHandler);
                resultArray.append(subData.get(node.getStringValue(NAME_FIELD)));
            }
            data.put(node.getStringValue(NAME_FIELD), resultArray);
        }
    }

    private static void getDataFromTable(Environment environment, BObject visitor, BObject node, BTable table,
                                         BMap<BString, Object> data, List<Object> pathSegments,
                                         CallbackHandler callbackHandler) {
        Object[] valueArray = table.values().toArray();
        ArrayType arrayType = TypeCreator.createArrayType(((BValue) valueArray[0]).getType());
        BArray valueBArray = ValueCreator.createArrayValue(valueArray, arrayType);
        populateResponse(environment, visitor, node, valueBArray, data, pathSegments, callbackHandler);
    }

    static void processFragmentNodes(Environment environment, BObject visitor, BObject node,
                                     BMap<BString, Object> record, BMap<BString, Object> data,
                                     List<Object> pathSegments,
                                     CallbackHandler callbackHandler) {
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        for (int i = 0; i < selections.size(); i++) {
            BMap<BString, Object> selection = (BMap<BString, Object>) selections.get(i);
            boolean isFragment = selection.getBooleanValue(IS_FRAGMENT_FIELD);
            BObject subNode = selection.getObjectValue(NODE_FIELD);
            if (isFragment) {
                processFragmentNodes(environment, visitor, subNode, record, data, pathSegments, callbackHandler);
            } else {
                BString fieldName = subNode.getStringValue(NAME_FIELD);
                Object fieldValue = record.get(fieldName);
                List<Object> updatedPathSegments =
                        updatePathSegments(pathSegments, node.getStringValue(NAME_FIELD).getValue());
                populateResponse(environment, visitor, subNode, fieldValue, data, updatedPathSegments,
                                 callbackHandler);
            }
        }
    }

    private static void executeResourceForFragmentNodes(Environment environment, BObject service, BObject visitor,
                                                        BObject node, BMap<BString, Object> data, List<String> paths,
                                                        List<Object> pathSegments, CallbackHandler callbackHandler) {
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        for (int i = 0; i < selections.size(); i++) {
            BMap<BString, Object> selection = (BMap<BString, Object>) selections.get(i);
            boolean isFragment = selection.getBooleanValue(IS_FRAGMENT_FIELD);
            BObject subNode = selection.getObjectValue(NODE_FIELD);
            if (isFragment) {
                executeResourceForFragmentNodes(environment, service, visitor, subNode, data, paths, pathSegments,
                                                callbackHandler);
            } else {
                executeResourceWithPath(environment, visitor, subNode, service, data, paths, pathSegments,
                                        callbackHandler, i);
            }
        }
    }

    private static void executeResourceWithPath(Environment environment, BObject visitor, BObject node, BObject service,
                                                BMap<BString, Object> data, List<String> paths,
                                                List<Object> pathSegments, CallbackHandler callbackHandler, int index) {
        List<String> updatedPaths = copyAndUpdateResourcePathsList(paths, node);
        List<Object> updatedPathSegments = updatePathSegments(pathSegments, node.getStringValue(NAME_FIELD).getValue());
        executeResource(environment, service, visitor, node, data, updatedPaths, updatedPathSegments, callbackHandler);
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
