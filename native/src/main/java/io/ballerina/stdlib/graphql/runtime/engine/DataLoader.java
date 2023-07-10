/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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
import io.ballerina.runtime.api.Future;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.types.ObjectType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BTypedesc;

import static io.ballerina.runtime.api.PredefinedTypes.TYPE_ANYDATA;
import static io.ballerina.runtime.api.PredefinedTypes.TYPE_ERROR;

/**
 *  This class provides native implementations of the Ballerina DataLoader class.
 */
public class DataLoader {
    private static final String DATA_LOADER_PROCESSES_GET_METHOD_NAME = "processGet";

    private DataLoader() {
    }

    public static Object get(Environment env, BObject dataLoader, Object key, BTypedesc typedesc) {
        Future balFuture = env.markAsync();
        ObjectType clientType = (ObjectType) TypeUtils.getReferredType(TypeUtils.getType(dataLoader));
        Object[] paramFeed = getProcessGetMethodParams(key, typedesc);
        Callback executionCallback = new ExecutionCallback(balFuture);
        Type returnType = TypeCreator.createUnionType(TYPE_ANYDATA, TYPE_ERROR);
        if (clientType.isIsolated() && clientType.isIsolated(DATA_LOADER_PROCESSES_GET_METHOD_NAME)) {
            env.getRuntime()
                    .invokeMethodAsyncConcurrently(dataLoader, DATA_LOADER_PROCESSES_GET_METHOD_NAME, null, null,
                                                   executionCallback, null, returnType, paramFeed);
            return null;
        }
        env.getRuntime().invokeMethodAsyncSequentially(dataLoader, DATA_LOADER_PROCESSES_GET_METHOD_NAME, null, null,
                                                       executionCallback, null, returnType, paramFeed);
        return null;
    }

    private static Object[] getProcessGetMethodParams(Object key, BTypedesc typedesc) {
        return new Object[]{key, true, typedesc, true};
    }
}
