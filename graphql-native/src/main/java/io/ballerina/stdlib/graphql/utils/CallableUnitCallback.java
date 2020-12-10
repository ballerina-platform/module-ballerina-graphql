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

package io.ballerina.stdlib.graphql.utils;

import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;

import java.io.PrintStream;

/**
 * This class handles the notifications from Ballerina resource execution.
 */
public class CallableUnitCallback implements Callback {
    PrintStream console = System.out;

    private BMap<BString, Object> outputObject;
    private BMap<BString, Object> parentField;
    private BString fieldValue;

    public CallableUnitCallback(BMap<BString, Object> outputObject, BMap<BString, Object> parentField,
                                BString fieldValue) {
        this.outputObject = outputObject;
        this.parentField = parentField;
        this.fieldValue = fieldValue;
    }

    @Override
    public void notifySuccess(Object result) {
        this.parentField.put(this.fieldValue, result);
    }

    @Override
    public void notifyFailure(BError error) {
        this.outputObject.put(StringUtils.fromString("Error"), error);
        console.println(error.toString());
    }
}
