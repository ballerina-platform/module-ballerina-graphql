// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/time;

// The `graphql-transport-ws` keep-alive loop -- ping only when idle, tear down only after
// `KEEPALIVE_MAX_MISSED_PROBES` silent cycles -- is identical on both sides of a subscription
// connection; only *who* is pinged and *what happens on timeout* differs. `KeepAlivePeer`
// captures exactly that difference so `runKeepAliveLoop` below can be written once and shared by
// the GraphQL client (`client_subscription_connection.bal`, via `ClientKeepAlivePeer`) and the
// GraphQL server (`websocket_service.bal`, via `ServerKeepAlivePeer`).
type KeepAlivePeer isolated object {

    // Sends a single `ping` message to the peer. Returns `true` on success, `false` if the send
    // failed, in which case the loop stops immediately and leaves failure handling to whatever
    // already reacts to the underlying connection going down.
    isolated function sendPing() returns boolean;

    // Called once `KEEPALIVE_MAX_MISSED_PROBES` consecutive probes have gone unanswered. The loop
    // always stops right after calling this.
    isolated function onKeepAliveTimeout();

    // Reports any side-specific reason the loop should stop early, beyond the `KeepAliveMonitor`'s
    // own `stop()`. The GraphQL client has one: its connection-level `closed` state can become
    // true (via `close()`) without a live `KeepAliveMonitor` at hand to call `stop()` on, since a
    // fresh monitor is created for every connection attempt (see `ClientKeepAlivePeer` and
    // `SubscriptionConnection.dispatch()`). The server has none -- `WsService.onClose()` calls
    // `stop()` on its one, connection-lifetime monitor directly -- so `ServerKeepAlivePeer` always
    // returns `false` here.
    isolated function isExternallyStopped() returns boolean;
};

// Tracks the pong signal and stop flag shared between a keep-alive loop and whatever notifies it
// of an incoming `pong` or a reason to stop, matching the convention of the `graphql-ws` reference
// implementation (`enisdenjo/graphql-ws`): only an actual `pong` resets the timer, not other
// traffic. A fresh monitor accompanies each connection attempt on the client and each connection
// on the server; `keepAliveWait` below is the interruptible wait both drive it with.
isolated class KeepAliveMonitor {
    private boolean pongReceived = false;
    private boolean stopped = false;

    isolated function markPongReceived() {
        lock {
            self.pongReceived = true;
        }
    }

    isolated function resetPong() {
        lock {
            self.pongReceived = false;
        }
    }

    isolated function isPongReceived() returns boolean {
        lock {
            return self.pongReceived;
        }
    }

    isolated function stop() {
        lock {
            self.stopped = true;
        }
    }

    isolated function isStopped() returns boolean {
        lock {
            return self.stopped;
        }
    }
}

// Waits for up to `duration` seconds for a keep-alive-relevant signal, blocking on `signalQueue`
// rather than sleeping, so the wait ends the instant a signal arrives instead of only being
// noticed at the end of `duration`. The underlying strand is genuinely blocked while waiting (via
// `MessageQueue`'s native, timed queue take), not periodically polling.
//
// A signal that turns out not to be relevant to this particular wait (for example, a pong signal
// arriving while waiting out the ping interval, which does not care about pongs) is not treated as
// done: the actual state is re-checked and, if not yet resolved, the wait resumes for whatever
// duration remains, measured with a monotonic clock so an early wake-up does not reset the budget.
//
// Returns `true` if the caller must stop the keep-alive loop entirely (the monitor was stopped, or
// `peer.isExternallyStopped()` reports true); `false` if `stopOnPong` was set and a pong arrived in
// time.
isolated function keepAliveWait(KeepAliveMonitor monitor, MessageQueue signalQueue, decimal duration,
        boolean stopOnPong, KeepAlivePeer peer) returns boolean {
    decimal remaining = duration;
    while remaining > 0d {
        if monitor.isStopped() || peer.isExternallyStopped() {
            return true;
        }
        if stopOnPong && monitor.isPongReceived() {
            return false;
        }
        decimal waitStart = time:monotonicNow();
        any|error signal = signalQueue.dequeueWithTimeout(remaining);
        decimal elapsed = time:monotonicNow() - waitStart;
        remaining = elapsed < remaining ? remaining - elapsed : 0d;
    }
    return monitor.isStopped() || peer.isExternallyStopped();
}

// Runs the keep-alive loop shared by the GraphQL client and server: pings only when idle, and
// tears down only after `KEEPALIVE_MAX_MISSED_PROBES` silent cycles, tolerating isolated misses
// (see ballerina-library#8929).
isolated function runKeepAliveLoop(KeepAliveMonitor monitor, MessageQueue signalQueue, decimal pingInterval,
        decimal pongTimeout, KeepAlivePeer peer) {
    int missedProbes = 0;
    while true {
        monitor.resetPong();
        if keepAliveWait(monitor, signalQueue, pingInterval, false, peer) {
            return;
        }
        if monitor.isPongReceived() {
            missedProbes = 0;
            continue;
        }
        if !peer.sendPing() {
            // The connection is already going down; the caller handles the failure.
            return;
        }
        if keepAliveWait(monitor, signalQueue, pongTimeout, true, peer) {
            return;
        }
        if monitor.isPongReceived() {
            missedProbes = 0;
            continue;
        }
        // Tolerates isolated misses; see ballerina-library#8929.
        missedProbes += 1;
        if missedProbes >= KEEPALIVE_MAX_MISSED_PROBES {
            peer.onKeepAliveTimeout();
            return;
        }
    }
}
