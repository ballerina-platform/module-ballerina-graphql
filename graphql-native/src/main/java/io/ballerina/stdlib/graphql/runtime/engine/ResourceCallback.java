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
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import java.util.concurrent.CountDownLatch;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ERRORS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.getErrorDetailRecord;
import static io.ballerina.stdlib.graphql.runtime.engine.ResponseGenerator.getDataFromResult;

/**
 * Callback class for the async invocation of the Ballerina resources.
 */
public class ResourceCallback implements Callback {
    private final Environment environment;
    private final CountDownLatch latch;
    private final BObject visitor;
    private final BObject node;
    private final BMap<BString, Object> data;

    public ResourceCallback(Environment environment, CountDownLatch latch, BObject visitor, BObject node,
                            BMap<BString, Object> data) {
        this.environment = environment;
        this.latch = latch;
        this.visitor = visitor;
        this.node = node;
        this.data = data;
    }

    @Override
    public void notifySuccess(Object result) {
        if (result instanceof BError) {
            BError bError = (BError) result;
            appendErrorToVisitor(bError);
        } else {
            getDataFromResult(this.environment, this.visitor, this.node, result, this.data);
        }
        this.latch.countDown();
    }

    @Override
    public void notifyFailure(BError bError) {
        appendErrorToVisitor(bError);
        this.latch.countDown();
    }

    private void appendErrorToVisitor(BError bError) {
        BArray errors = this.visitor.getArrayValue(ERRORS_FIELD);
        errors.append(getErrorDetailRecord(bError, this.node));
    }
}
