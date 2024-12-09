/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org).
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

import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import java.util.concurrent.ConcurrentHashMap;

import static io.ballerina.stdlib.graphql.runtime.utils.ModuleUtils.getModule;

/**
 * This class provides native implementations of the Ballerina ExecutorVisitor class.
 */
public class ExecutorVisitor {
    private static final String DATA_MAP = "dataMap";
    private static final String DATA_RECORD_NAME = "Data";
    private static final Object NullObject = new Object();
    private final ConcurrentHashMap<BString, Object> dataMap = new ConcurrentHashMap<>();

    private ExecutorVisitor() {
    }

    public static void initializeDataMap(BObject executorVisitor) {
        executorVisitor.addNativeData(DATA_MAP, new ExecutorVisitor());
    }

    public static void addData(BObject executorVisitor, BString key, Object value) {
        ExecutorVisitor visitor = (ExecutorVisitor) executorVisitor.getNativeData(DATA_MAP);
        visitor.addData(key, value);
    }

    public static BMap<BString, Object> getDataMap(BObject executorVisitor) {
        ExecutorVisitor visitor = (ExecutorVisitor) executorVisitor.getNativeData(DATA_MAP);
        return visitor.getDataMap();
    }

    private void addData(BString key, Object value) {
        dataMap.put(key, value == null ? NullObject : value);
    }

    private BMap<BString, Object> getDataMap() {
        BMap<BString, Object> data = ValueCreator.createRecordValue(getModule(), DATA_RECORD_NAME);
        dataMap.forEach((key, value) -> data.put(key, value.equals(NullObject) ? null : value));
        return data;
    }
}
