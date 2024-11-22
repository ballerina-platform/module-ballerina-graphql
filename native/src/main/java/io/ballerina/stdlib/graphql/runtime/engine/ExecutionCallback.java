/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import io.ballerina.runtime.api.values.BError;

import java.util.concurrent.CompletableFuture;

/**
 * Callback class for executing Ballerina dependently type methods.
 */
public class ExecutionCallback {
    private final CompletableFuture<Object> future;

    ExecutionCallback(CompletableFuture<Object> future) {
        this.future = future;
    }

    public void notifySuccess(Object o) {
        this.future.complete(o);
    }

    public void notifyFailure(BError bError) {
        bError.printStackTrace();
        // Service level `panic` is captured in this method.
        // Since, `panic` is due to a critical application bug or resource exhaustion we need to exit the application.
        // Please refer: https://github.com/ballerina-platform/ballerina-standard-library/issues/2714
        System.exit(1);
    }
}
