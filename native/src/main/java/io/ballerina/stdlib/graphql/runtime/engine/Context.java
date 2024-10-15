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

import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BValue;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * This class provides native implementations of the Ballerina Context class.
 */
public class Context {
    private final ConcurrentHashMap<BString, Object> attributes = new ConcurrentHashMap<>();
    // Provides mapping between user defined id and DataLoader
    private final ConcurrentHashMap<BString, BObject> idDataLoaderMap = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<BString, BObject> uuidPlaceholderMap = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<BString, BObject> unResolvedPlaceholders = new ConcurrentHashMap<>();
    private final AtomicBoolean containPlaceholders = new AtomicBoolean(false);
    // Tracks the number of Placeholders needs to be resolved
    private final AtomicInteger unResolvedPlaceholderCount = new AtomicInteger(0);
    private final AtomicInteger unResolvedPlaceholderNodeCount = new AtomicInteger(0);
    private static final String CONTEXT = "context";

    private Context() {
    }

    public static void initializeContext(BObject context) {
        context.addNativeData(CONTEXT, new Context());
    }

    public static void registerDataLoader(BObject object, BString key, BObject dataLoader) {
        Context context = (Context) object.getNativeData(CONTEXT);
        context.registerDataLoader(key, dataLoader);
    }

    public static void setAttribute(BObject object, BString key, Object value) {
        Context context = (Context) object.getNativeData(CONTEXT);
        context.setAttribute(key, value);
    }

    public static Object getAttribute(BObject object, BString key) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.getAttribute(key);
    }

    public static Object removeAttribute(BObject object, BString key) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.removeAttribute(key);
    }

    public static BObject getDataLoader(BObject object, BString key) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.getDataLoader(key);
    }

    public static BArray getDataLoaderIds(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.getDataLoaderIds();
    }

    public static BArray getUnresolvedPlaceholders(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.getUnresolvedPlaceholders();
    }

    public static void removeAllUnresolvedPlaceholders(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        context.removeAllUnresolvedPlaceholders();
    }

    public static BObject getPlaceholder(BObject object, BString uuid) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.getPlaceholder(uuid);
    }

    public static int getUnresolvedPlaceholderCount(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.getUnresolvedPlaceholderCount();
    }

    public static int getUnresolvedPlaceholderNodeCount(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.getUnresolvedPlaceholderNodeCount();
    }

    public static void decrementUnresolvedPlaceholderNodeCount(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        context.decrementUnresolvedPlaceholderNodeCount();
    }

    public static void decrementUnresolvedPlaceholderCount(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        context.decrementUnresolvedPlaceholderCount();
    }

    public static void addUnresolvedPlaceholder(BObject object, BString uuid, BObject placeholder) {
        Context context = (Context) object.getNativeData(CONTEXT);
        context.addUnresolvedPlaceholder(uuid, placeholder);
    }

    public static boolean hasPlaceholders(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.hasPlaceholders();
    }

    public static void clearPlaceholders(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        context.clearPlaceholders();
    }

    private void setAttribute(BString key, Object value) {
        this.attributes.put(key, value);
    }

    private Object getAttribute(BString key) {
        return this.attributes.get(key);
    }

    private Object removeAttribute(BString key) {
        return this.attributes.remove(key);
    }

    private void registerDataLoader(BString key, BObject dataLoader) {
        this.idDataLoaderMap.put(key, dataLoader);
    }

    private BObject getDataLoader(BString key) {
        return this.idDataLoaderMap.get(key);
    }

    private BArray getDataLoaderIds() {
        BArray values = ValueCreator.createArrayValue(TypeCreator.createArrayType(PredefinedTypes.TYPE_STRING));
        this.idDataLoaderMap.forEach((key, value) -> values.append(key));
        return values;
    }

    private BArray getUnresolvedPlaceholders() {
        Object[] valueArray = this.unResolvedPlaceholders.values().toArray();
        ArrayType arrayType = TypeCreator.createArrayType(((BValue) valueArray[0]).getType());
        return ValueCreator.createArrayValue(valueArray, arrayType);
    }

    private void removeAllUnresolvedPlaceholders() {
        this.unResolvedPlaceholders.clear();
    }

    private BObject getPlaceholder(BString uuid) {
        return this.uuidPlaceholderMap.remove(uuid);
    }

    private int getUnresolvedPlaceholderCount() {
        return this.unResolvedPlaceholderCount.get();
    }

    private int getUnresolvedPlaceholderNodeCount() {
        return this.unResolvedPlaceholderNodeCount.get();
    }

    private void decrementUnresolvedPlaceholderNodeCount() {
        this.unResolvedPlaceholderNodeCount.decrementAndGet();
    }

    private void decrementUnresolvedPlaceholderCount() {
        this.unResolvedPlaceholderCount.decrementAndGet();
    }

    private void addUnresolvedPlaceholder(BString uuid, BObject placeholder) {
        this.containPlaceholders.set(true);
        this.uuidPlaceholderMap.put(uuid, placeholder);
        this.unResolvedPlaceholders.put(uuid, placeholder);
        this.unResolvedPlaceholderCount.incrementAndGet();
        this.unResolvedPlaceholderNodeCount.incrementAndGet();
    }

    private boolean hasPlaceholders() {
        return this.containPlaceholders.get();
    }

    private void clearPlaceholders() {
        this.unResolvedPlaceholders.clear();
        this.uuidPlaceholderMap.clear();
        this.containPlaceholders.set(false);
    }
}
