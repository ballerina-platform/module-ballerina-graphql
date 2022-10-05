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

import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import java.util.List;

import static io.ballerina.stdlib.graphql.runtime.engine.ResponseGenerator.appendErrorToVisitor;
import static io.ballerina.stdlib.graphql.runtime.engine.ResponseGenerator.populateResponse;

/**
 * Callback class for the async invocation of the Ballerina resources.
 */
public class ResourceCallback implements Callback {
    private final ExecutionContext executionContext;
    private final BObject node;
    private final BMap<BString, Object> data;
    private final List<Object> pathSegments;

    public ResourceCallback(ExecutionContext executionContext, BObject node, BMap<BString, Object> data,
                            List<Object> pathSegments) {
        this.executionContext = executionContext;
        this.node = node;
        this.data = data;
        this.pathSegments = pathSegments;
    }

    @Override
    public void notifySuccess(Object result) {
        populateResponse(this.executionContext, this.node, result, this.data, this.pathSegments);
        markComplete();
    }

    @Override
    public void notifyFailure(BError bError) {
        appendErrorToVisitor(bError, executionContext, this.node, this.pathSegments);
        markComplete();
    }

    private void markComplete() {
        this.executionContext.getCallbackHandler().markComplete(this);
    }
}
