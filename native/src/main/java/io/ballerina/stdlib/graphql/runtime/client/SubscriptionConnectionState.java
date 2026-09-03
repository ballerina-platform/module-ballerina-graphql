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

package io.ballerina.stdlib.graphql.runtime.client;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Semaphore;
import java.util.concurrent.atomic.AtomicReference;

/**
 * This class holds the shared, mutable state of a GraphQL client subscription connection using concurrent-safe data
 * structures: the active subscription operations, the connection's lifecycle state, and the current WebSocket
 * client. Compound state transitions are serialized through an ownerless lock exposed via the
 * {@code lockState}/{@code unlockState} functions (a strand may resume on a different thread, so a thread-owned lock
 * cannot be used).
 */
public final class SubscriptionConnectionState {
    private static final String NATIVE_STATE_KEY = "graphql.client.subscription.connection.state";

    private final ConcurrentHashMap<String, SubscriptionOperation> operations = new ConcurrentHashMap<>();
    private final AtomicReference<ConnectionLifecycleState> lifecycleState =
            new AtomicReference<>(ConnectionLifecycleState.DISCONNECTED);
    private final AtomicReference<Object> wsClient = new AtomicReference<>();
    private final Semaphore stateLock = new Semaphore(1);
    // Written once at init before the connection is used, then read-only. Held in an AtomicReference
    // (like wsClient) for cross-strand visibility and to keep the accessor from exposing a field directly.
    private final AtomicReference<BMap<BString, Object>> wsClientConfig = new AtomicReference<>();

    private SubscriptionConnectionState() {
    }

    /**
     * The lifecycle state of a subscription connection.
     *
     * <pre>
     *                 startConnecting()                markConnected()
     *   DISCONNECTED -------------------&gt; CONNECTING -------------------&gt; CONNECTED
     *        ^                                |                              |
     *        |             markDisconnected() |                              | startReconnecting()
     *        +----------------------------------------------------------+    v
     *                                                                    RECONNECTING
     *                                        markDisconnected()  &lt;----------+  |
     *                                                                          | markConnected()
     *                                                                          v
     *                                                                     CONNECTED
     *
     *   Any state ----------------------- markClosed() ------------------&gt; CLOSED (terminal)
     * </pre>
     *
     * {@code CLOSED} is a terminal, sticky state: once reached, every other transition below becomes a no-op (see
     * {@code transitionUnlessClosed}), matching {@code close()}'s "closing is permanent" contract in
     * {@code client_subscription_connection.bal}.
     */
    private enum ConnectionLifecycleState {
        /** No live connection and none being established; the initial state, and the state after a failed
         *  connection attempt or reconnection exhaustion. */
        DISCONNECTED,
        /** The very first connection attempt for this client is in flight. */
        CONNECTING,
        /** A live WebSocket connection is established and in use. */
        CONNECTED,
        /** A previously-established connection was lost and reconnection is being attempted. */
        RECONNECTING,
        /** The connection was closed by the user via {@code close()}. Terminal. */
        CLOSED
    }

    public static void initConnectionState(BObject connection) {
        connection.addNativeData(NATIVE_STATE_KEY, new SubscriptionConnectionState());
    }

    public static void storeWebSocketClientConfig(BObject connection, BMap<BString, Object> config) {
        getState(connection).wsClientConfig.set(config);
    }

    public static BMap<BString, Object> loadWebSocketClientConfig(BObject connection) {
        return getState(connection).wsClientConfig.get();
    }

    /**
     * Registers a subscription operation atomically. Returns false when an operation with the given ID already
     * exists, in which case the state remains unchanged.
     */
    public static boolean registerOperation(BObject connection, BString id, BObject queue, Object subscribeMessage) {
        return getState(connection).register(id.getValue(), new SubscriptionOperation(queue, subscribeMessage));
    }

    /**
     * Removes a subscription operation atomically. Returns the message queue of the removed operation, or null when
     * no operation with the given ID exists.
     */
    public static Object removeOperation(BObject connection, BString id) {
        SubscriptionOperation operation = getState(connection).remove(id.getValue());
        return operation == null ? null : operation.getQueue();
    }

    public static BArray getOperationIds(BObject connection) {
        return StringUtils.fromStringArray(getState(connection).getIds());
    }

    public static Object getQueue(BObject connection, BString id) {
        SubscriptionOperation operation = getState(connection).get(id.getValue());
        return operation == null ? null : operation.getQueue();
    }

    public static Object getSubscribeMessage(BObject connection, BString id) {
        SubscriptionOperation operation = getState(connection).get(id.getValue());
        return operation == null ? null : operation.getSubscribeMessage();
    }

    /**
     * Marks the connection as closed atomically, moving it to the terminal {@code CLOSED} state regardless of the
     * state it was in. Returns false when the connection was already closed, making a repeated closure a no-op.
     */
    public static boolean markClosed(BObject connection) {
        ConnectionLifecycleState previous =
                getState(connection).lifecycleState.getAndSet(ConnectionLifecycleState.CLOSED);
        return previous != ConnectionLifecycleState.CLOSED;
    }

    public static boolean isClosed(BObject connection) {
        return getState(connection).lifecycleState.get() == ConnectionLifecycleState.CLOSED;
    }

    /**
     * Acquires the lock serializing the compound state transitions of the connection. Every acquisition must be
     * paired with an {@code unlockState} call.
     */
    public static void lockState(Environment env, BObject connection) {
        Semaphore stateLock = getState(connection).stateLock;
        env.yieldAndRun(() -> {
            stateLock.acquireUninterruptibly();
            return null;
        });
    }

    public static void unlockState(BObject connection) {
        getState(connection).stateLock.release();
    }

    /**
     * Returns true while a connection establishment attempt -- the initial one or a reconnection -- is in flight,
     * i.e. the state is {@code CONNECTING} or {@code RECONNECTING}. Used by {@code subscribe()} to decide whether it
     * must establish the connection itself or whether one is already being established on its behalf.
     */
    public static boolean isConnecting(BObject connection) {
        ConnectionLifecycleState current = getState(connection).lifecycleState.get();
        return current == ConnectionLifecycleState.CONNECTING || current == ConnectionLifecycleState.RECONNECTING;
    }

    /** DISCONNECTED -&gt; CONNECTING: the initial connection attempt for this client starts. */
    public static void startConnecting(BObject connection) {
        getState(connection).transitionUnlessClosed(ConnectionLifecycleState.CONNECTING);
    }

    /** CONNECTED -&gt; RECONNECTING: a previously-live connection was lost and reconnection starts. */
    public static void startReconnecting(BObject connection) {
        getState(connection).transitionUnlessClosed(ConnectionLifecycleState.RECONNECTING);
    }

    /** CONNECTING|RECONNECTING -&gt; CONNECTED: a connection attempt succeeded. */
    public static void markConnected(BObject connection) {
        getState(connection).transitionUnlessClosed(ConnectionLifecycleState.CONNECTED);
    }

    /** CONNECTING|RECONNECTING -&gt; DISCONNECTED: a connection attempt failed, or reconnection was exhausted. */
    public static void markDisconnected(BObject connection) {
        getState(connection).transitionUnlessClosed(ConnectionLifecycleState.DISCONNECTED);
    }

    public static void storeWsClient(BObject connection, Object wsClient) {
        getState(connection).wsClient.set(wsClient);
    }

    public static Object loadWsClient(BObject connection) {
        return getState(connection).wsClient.get();
    }

    // CLOSED is terminal and sticky: once reached, every other transition is a no-op, so a background
    // connect/reconnect attempt racing with a concurrent close() can never move the state back out of CLOSED.
    private void transitionUnlessClosed(ConnectionLifecycleState newState) {
        this.lifecycleState.updateAndGet(
                current -> current == ConnectionLifecycleState.CLOSED ? current : newState);
    }

    private boolean register(String id, SubscriptionOperation operation) {
        return this.operations.putIfAbsent(id, operation) == null;
    }

    private SubscriptionOperation remove(String id) {
        return this.operations.remove(id);
    }

    private SubscriptionOperation get(String id) {
        return this.operations.get(id);
    }

    private String[] getIds() {
        return this.operations.keySet().toArray(new String[0]);
    }

    private static SubscriptionConnectionState getState(BObject connection) {
        return (SubscriptionConnectionState) connection.getNativeData(NATIVE_STATE_KEY);
    }

    /**
     * Represents an active subscription operation: the message queue connecting the dispatcher with the stream
     * generator, and the original subscribe message used to resubscribe on reconnection.
     */
    private static final class SubscriptionOperation {
        private final BObject queue;
        private final Object subscribeMessage;

        SubscriptionOperation(BObject queue, Object subscribeMessage) {
            this.queue = queue;
            this.subscribeMessage = subscribeMessage;
        }

        BObject getQueue() {
            return this.queue;
        }

        Object getSubscribeMessage() {
            return this.subscribeMessage;
        }
    }
}
