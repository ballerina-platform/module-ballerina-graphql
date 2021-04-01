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
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTable;
import io.ballerina.runtime.api.values.BValue;

import java.util.concurrent.CountDownLatch;

import static io.ballerina.stdlib.graphql.runtime.engine.Engine.executeResource;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.DATA_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ERRORS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SELECTIONS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.getErrorDetailRecord;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isScalarType;
import static io.ballerina.stdlib.graphql.runtime.utils.ModuleUtils.getModule;

/**
 * This class is used as a callback class for Ballerina resource execution.
 */
public class CallableUnitCallback implements Callback {
    private final Environment environment;
    private final CountDownLatch latch;
    private Object result;
    private final BObject visitor;
    private final BObject fieldNode;

    public CallableUnitCallback(Environment environment, CountDownLatch latch, BObject visitor, BObject fieldNode) {
        this.environment = environment;
        this.latch = latch;
        this.visitor = visitor;
        this.fieldNode = fieldNode;
    }

    public Object getResult() {
        return this.result;
    }

    @Override
    public void notifySuccess(Object o) {
        if (o instanceof BError) {
            BError bError = (BError) o;
            appendErrorToVisitor(bError);
            this.result = bError;
        } else if (o instanceof BObject) {
            this.result = getDataFromService(this.environment, (BObject) o, this.visitor, this.fieldNode);
        } else {
            this.result = getDataFromResult(this.fieldNode, o);
        }
        this.latch.countDown();
    }

    @Override
    public void notifyFailure(BError bError) {
        appendErrorToVisitor(bError);
        this.result = bError;
        this.latch.countDown();
    }

    private static Object getDataFromResult(BObject fieldNode, Object result) {
        if (result instanceof BMap) {
            return getDataFromRecord(fieldNode, (BMap<BString, Object>) result);
        } else if (result instanceof BArray) {
            return getDataFromArray(fieldNode, (BArray) result);
        } else if (result instanceof BTable) {
            return getDataFromTable(fieldNode, (BTable) result);
        } else {
            return result;
        }
    }

    static BMap<BString, Object> getDataFromService(Environment environment, BObject service, BObject visitor,
                                                            BObject fieldNode) {
        BArray selections = fieldNode.getArrayValue(SELECTIONS_FIELD);
        BMap<BString, Object> data = createDataRecord();
        for (int i = 0; i < selections.size(); i++) {
            BObject subField = (BObject) selections.get(i);
            Object subFieldValue = executeResource(environment, service, visitor, subField);
            data.put(subField.getStringValue(NAME_FIELD), subFieldValue);
        }
        return data;
    }

    static BArray getDataFromArray(BObject fieldNode, BArray result) {
        if (isScalarType(result.getElementType())) {
            return result;
        } else {
            BArray resultArray = ValueCreator.createArrayValue(getDataRecordArrayType());
            for (int i = 0; i < result.size(); i++) {
                Object resultRecord = result.get(i);
                Object arrayField = getDataFromResult(fieldNode, resultRecord);
                resultArray.append(arrayField);
            }
            return resultArray;
        }
    }

    static BMap<BString, Object> getDataFromRecord(BObject fieldNode, BMap<BString, Object> record) {
        BArray selections = fieldNode.getArrayValue(SELECTIONS_FIELD);
        BMap<BString, Object> data = createDataRecord();
        for (int i = 0; i < selections.size(); i++) {
            BObject subfieldNode = (BObject) selections.get(i);
            BString fieldName = subfieldNode.getStringValue(NAME_FIELD);
            Object fieldValue = record.get(fieldName);
            data.put(fieldName, getDataFromResult(subfieldNode, fieldValue));
        }
        return data;
    }

    private static BArray getDataFromTable(BObject fieldNode, BTable table) {
        Object[] valueArray = table.values().toArray();
        ArrayType arrayType = TypeCreator.createArrayType(((BValue) valueArray[0]).getType());
        BArray valueBArray = ValueCreator.createArrayValue(valueArray, arrayType);
        return getDataFromArray(fieldNode, valueBArray);
    }

    private void appendErrorToVisitor(BError bError) {
        BArray errors = this.visitor.getArrayValue(ERRORS_FIELD);
        errors.append(getErrorDetailRecord(bError, this.fieldNode));
    }

    private static ArrayType getDataRecordArrayType() {
        BMap<BString, Object> data = createDataRecord();
        return TypeCreator.createArrayType(data.getType());
    }

    private static BMap<BString, Object> createDataRecord() {
        return ValueCreator.createRecordValue(getModule(), DATA_RECORD);
    }
}
