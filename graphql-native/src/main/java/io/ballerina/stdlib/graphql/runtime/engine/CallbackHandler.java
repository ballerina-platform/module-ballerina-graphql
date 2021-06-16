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

import io.ballerina.runtime.api.Future;

import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * This class keeps track of the all the async calls done in a single process and returns when all the calls completed.
 */

public class CallbackHandler {
    private final Future future;
    private List<ResourceCallback> callbackList;
    private boolean isExecuting;
    private static PrintStream out = System.out;

    public CallbackHandler(Future future) {
        this.future = future;
        this.callbackList = Collections.synchronizedList(new ArrayList<>());
        this.isExecuting = true;
    }

    public synchronized void addCallback(ResourceCallback callback) {
        this.callbackList.add(callback);
    }

    public synchronized void markComplete(ResourceCallback callback) {
        this.callbackList.remove(callback);
        // TODO: Improve this to find the exact time to complete without `isExecuting`
        if (this.isExecuting && this.callbackList.size() == 0) {
            this.future.complete(null);
            this.isExecuting = false;
        } else if (!this.isExecuting && this.callbackList.size() == 0) {
            for (StackTraceElement element : Thread.currentThread().getStackTrace()) {
                out.println(element);
            }
        }
    }
}
