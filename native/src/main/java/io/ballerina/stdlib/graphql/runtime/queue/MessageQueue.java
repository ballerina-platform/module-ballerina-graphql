/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.graphql.runtime.queue;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.values.BDecimal;
import io.ballerina.runtime.api.values.BObject;

import java.math.BigDecimal;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

/**
 * This class provides the native implementation of a generic blocking message queue, used to signal and wait
 * across strands in the GraphQL client and server subscription connection handling.
 */
public final class MessageQueue {
    private static final String NATIVE_QUEUE_KEY = "graphql.subscription.message.queue";

    // A nil item cannot be inserted into the queue; this sentinel represents it. Dequeuing it produces nil,
    // which marks the end of a subscription stream.
    private static final Object NIL_ITEM = new Object();

    private MessageQueue() {
    }

    public static void externInit(BObject queueObject) {
        queueObject.addNativeData(NATIVE_QUEUE_KEY, new LinkedBlockingQueue<>());
    }

    public static void enqueue(BObject queueObject, Object item) {
        // The queue is unbounded; add never rejects an item.
        getQueue(queueObject).add(item == null ? NIL_ITEM : item);
    }

    public static Object dequeue(Environment env, BObject queueObject) {
        return env.yieldAndRun(() -> {
            try {
                Object item = getQueue(queueObject).take();
                return item == NIL_ITEM ? null : item;
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return null;
            }
        });
    }

    public static Object dequeueWithTimeout(Environment env, BObject queueObject, BDecimal timeout) {
        long timeoutInMillis = timeout.decimalValue().multiply(BigDecimal.valueOf(1000)).longValue();
        return env.yieldAndRun(() -> {
            try {
                Object item = getQueue(queueObject).poll(timeoutInMillis, TimeUnit.MILLISECONDS);
                return item == NIL_ITEM ? null : item;
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return null;
            }
        });
    }

    @SuppressWarnings("unchecked")
    private static LinkedBlockingQueue<Object> getQueue(BObject queueObject) {
        return (LinkedBlockingQueue<Object>) queueObject.getNativeData(NATIVE_QUEUE_KEY);
    }
}
