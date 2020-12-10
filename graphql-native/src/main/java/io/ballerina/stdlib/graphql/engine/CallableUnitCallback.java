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

package io.ballerina.stdlib.graphql.engine;

import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import static io.ballerina.stdlib.graphql.engine.Utils.DATA_FIELD;
import static io.ballerina.stdlib.graphql.engine.Utils.ERRORS_FIELD;
import static io.ballerina.stdlib.graphql.engine.Utils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.engine.Utils.OUTPUT_OBJECT_FIELD;
import static io.ballerina.stdlib.graphql.engine.Utils.getErrorDetailRecord;

/**
 * This class handles the notifications from Ballerina resource execution.
 */
public class CallableUnitCallback implements Callback {

    private BObject visitor;
    private BObject fieldNode;

    public CallableUnitCallback(BObject visitor, BObject fieldNode) {
        this.visitor = visitor;
        this.fieldNode = fieldNode;
    }

    @Override
    public void notifySuccess(Object result) {
        BMap<BString, Object> output = visitor.getMapValue(OUTPUT_OBJECT_FIELD);
        BMap<BString, Object> data = (BMap<BString, Object>) output.getMapValue(DATA_FIELD);
        data.put(this.fieldNode.getStringValue(NAME_FIELD), result);
    }

    @Override
    public void notifyFailure(BError error) {
        BMap<BString, Object> output = visitor.getMapValue(OUTPUT_OBJECT_FIELD);
        BArray errors = output.getArrayValue(ERRORS_FIELD);
        errors.append(getErrorDetailRecord(error.getErrorMessage(), this.fieldNode));
    }
}
