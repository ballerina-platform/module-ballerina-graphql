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
import io.ballerina.runtime.api.async.Callback;
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

import java.util.concurrent.CountDownLatch;

import static io.ballerina.stdlib.graphql.runtime.engine.Engine.executeResource;
import static io.ballerina.stdlib.graphql.runtime.engine.Engine.getArgumentsFromField;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ERRORS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.IS_FRAGMENT_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.KEY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NODE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ON_TYPE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SELECTIONS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.createDataRecord;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.getErrorDetailRecord;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isScalarType;

/**
 * This class is used as a callback class for Ballerina resource execution.
 */
public class CallableUnitCallback implements Callback {
    private final Environment environment;
    private final CountDownLatch latch;
    private final BObject visitor;
    private final BObject node;
    private BMap<BString, Object> data;

    public CallableUnitCallback(Environment environment, CountDownLatch latch, BObject visitor, BObject node,
                                BMap<BString, Object> data) {
        this.environment = environment;
        this.latch = latch;
        this.visitor = visitor;
        this.node = node;
        this.data = data;
    }

    @Override
    public void notifySuccess(Object o) {
        if (o instanceof BError) {
            BError bError = (BError) o;
            appendErrorToVisitor(bError);
        } else if (o instanceof BObject) {
            getDataFromService(this.environment, (BObject) o, this.visitor, this.node, this.data);
        } else {
            getDataFromResult(this.environment, this.visitor, this.node, o, this.data);
        }
        this.latch.countDown();
    }

    @Override
    public void notifyFailure(BError bError) {
        appendErrorToVisitor(bError);
        this.latch.countDown();
    }

    private static void getDataFromResult(Environment environment, BObject visitor, BObject node, Object result,
                                          BMap<BString, Object> data) {
        if (result instanceof BMap) {
            BMap<BString, Object> map = (BMap<BString, Object>) result;
            if (map.getType().getTag() == TypeTags.RECORD_TYPE_TAG) {
                getDataFromRecord(environment, visitor, node, map, data);
            } else if (map.getType().getTag() == TypeTags.MAP_TAG) {
                getDataFromMap(environment, visitor, node, map, data);
            }
        } else if (result instanceof BArray) {
            getDataFromArray(environment, visitor, node, (BArray) result, data);
        } else if (result instanceof BTable) {
            getDataFromTable(environment, visitor, node, (BTable) result, data);
        } else if (result instanceof BObject) {
            getDataFromService(environment, (BObject) result, visitor, node, data);
        } else {
            data.put(node.getStringValue(NAME_FIELD), result);
        }
    }

    static void getDataFromService(Environment environment, BObject service, BObject visitor, BObject node,
                                   BMap<BString, Object> data) {
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        BMap<BString, Object> subData = createDataRecord();
        for (int i = 0; i < selections.size(); i++) {
            BMap<BString, Object> selection = (BMap<BString, Object>) selections.get(i);
            boolean isFragment = selection.getBooleanValue(IS_FRAGMENT_FIELD);
            BObject subNode = selection.getObjectValue(NODE_FIELD);
            if (isFragment) {
                executeResourceForFragmentNodes(environment, service, visitor, subNode, subData);
            } else {
                executeResource(environment, service, visitor, subNode, subData);
            }
            data.put(node.getStringValue(NAME_FIELD), subData);
        }
    }

    static void getDataFromArray(Environment environment, BObject visitor, BObject node, BArray result,
                                 BMap<BString, Object> data) {
        if (isScalarType(result.getElementType())) {
            data.put(node.getStringValue(NAME_FIELD), result);
        } else {
            BArray resultArray = ValueCreator.createArrayValue(getDataRecordArrayType());
            for (int i = 0; i < result.size(); i++) {
                Object resultElement = result.get(i);
                BMap<BString, Object> subData = createDataRecord();
                getDataFromResult(environment, visitor, node, resultElement, subData);
                resultArray.append(subData.get(node.getStringValue(NAME_FIELD)));
            }
            data.put(node.getStringValue(NAME_FIELD), resultArray);
        }
    }

    static void getDataFromRecord(Environment environment, BObject visitor, BObject node, BMap<BString, Object> record,
                                  BMap<BString, Object> data) {
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        BMap<BString, Object> subData = createDataRecord();
        for (int i = 0; i < selections.size(); i++) {
            BMap<BString, Object> selection = (BMap<BString, Object>) selections.get(i);
            boolean isFragment = selection.getBooleanValue(IS_FRAGMENT_FIELD);
            BObject subNode = selection.getObjectValue(NODE_FIELD);
            if (isFragment) {
                if (subNode.getStringValue(ON_TYPE_FIELD).getValue().equals(record.getType().getName())) {
                    processFragmentNodes(environment, visitor, subNode, record, subData);
                }
            } else {
                BString fieldName = subNode.getStringValue(NAME_FIELD);
                Object fieldValue = record.get(fieldName);
                getDataFromResult(environment, visitor, subNode, fieldValue, subData);
            }
        }
        data.put(node.getStringValue(NAME_FIELD), subData);
    }

    static void getDataFromMap(Environment environment, BObject visitor, BObject node, BMap<BString, Object> map,
                               BMap<BString, Object> data) {
        BMap<BString, Object> arguments = getArgumentsFromField(node);
        BString key = arguments.getStringValue(StringUtils.fromString(KEY));
        Object result = map.get(key);
        getDataFromResult(environment, visitor, node, result, data);
    }

    static void processFragmentNodes(Environment environment, BObject visitor, BObject node,
                                     BMap<BString, Object> record, BMap<BString, Object> data) {
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        for (int i = 0; i < selections.size(); i++) {
            BMap<BString, Object> selection = (BMap<BString, Object>) selections.get(i);
            boolean isFragment = selection.getBooleanValue(IS_FRAGMENT_FIELD);
            BObject subNode = selection.getObjectValue(NODE_FIELD);
            if (isFragment) {
                processFragmentNodes(environment, visitor, subNode, record, data);
            } else {
                BString fieldName = subNode.getStringValue(NAME_FIELD);
                Object fieldValue = record.get(fieldName);
                getDataFromResult(environment, visitor, subNode, fieldValue, data);
            }
        }
    }

    private static void executeResourceForFragmentNodes(Environment environment, BObject service, BObject visitor,
                                                        BObject node, BMap<BString, Object> data) {
        BArray selections = node.getArrayValue(SELECTIONS_FIELD);
        BMap<BString, Object> subData = createDataRecord();
        for (int i = 0; i < selections.size(); i++) {
            BMap<BString, Object> selection = (BMap<BString, Object>) selections.get(i);
            boolean isFragment = selection.getBooleanValue(IS_FRAGMENT_FIELD);
            BObject subNode = selection.getObjectValue(NODE_FIELD);
            if (isFragment) {
                executeResourceForFragmentNodes(environment, service, visitor, subNode, subData);
            } else {
                executeResource(environment, service, visitor, subNode, subData);
                data.put(subNode.getStringValue(NAME_FIELD), subData.get(subNode.getStringValue(NAME_FIELD)));
            }
        }
    }

    private static void getDataFromTable(Environment environment, BObject visitor, BObject node, BTable table,
                                         BMap<BString, Object> data) {
        Object[] valueArray = table.values().toArray();
        ArrayType arrayType = TypeCreator.createArrayType(((BValue) valueArray[0]).getType());
        BArray valueBArray = ValueCreator.createArrayValue(valueArray, arrayType);
        getDataFromArray(environment, visitor, node, valueBArray, data);
    }

    private void appendErrorToVisitor(BError bError) {
        BArray errors = this.visitor.getArrayValue(ERRORS_FIELD);
        errors.append(getErrorDetailRecord(bError, this.node));
    }

    private static ArrayType getDataRecordArrayType() {
        BMap<BString, Object> data = createDataRecord();
        return TypeCreator.createArrayType(data.getType());
    }
}
