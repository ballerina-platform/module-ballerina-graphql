// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

import ballerina/graphql_test_common as common;
import ballerina/http;
import ballerina/websocket;

const string MOCK_AUTH_TOKEN = "token-xyz";
const int MOCK_ABNORMAL_CLOSURE_STATUS_CODE = 4500;

listener websocket:Listener mockSubscriptionListener = new (9092);

isolated json recordedPongPayload = ();
isolated int mockDropConnectionCount = 0;
isolated int mockReconnectConnectionCount = 0;
isolated string[] mockReconnectSecondConnectionIds = [];
isolated int mockCloseReconnectConnectionCount = 0;
isolated boolean mockCloseReconnectDropped = false;
isolated int mockExhaustionConnectionCount = 0;
isolated int mockSelectiveConnectionCount = 0;
isolated string[] mockSelectiveSecondConnectionIds = [];

isolated function getRecordedPongPayload() returns json {
    lock {
        return recordedPongPayload.clone();
    }
}

isolated function getMockMessageType(json message) returns string {
    json|error messageType = message.'type;
    return messageType is string ? messageType : "";
}

isolated function getMockMessageId(json message) returns string {
    json|error id = message.id;
    return id is string ? id : "";
}

// Authenticates the connection using the `connection_init` message payload.
@websocket:ServiceConfig {
    subProtocols: [common:GRAPHQL_TRANSPORT_WS]
}
service /mock_init_auth on mockSubscriptionListener {
    isolated resource function get .() returns websocket:Service|websocket:UpgradeError {
        return new MockInitAuthWsService();
    }
}

isolated service class MockInitAuthWsService {
    *websocket:Service;

    isolated remote function onMessage(websocket:Caller caller, json message) returns websocket:Error? {
        string messageType = getMockMessageType(message);
        if messageType == common:WS_PING {
            check caller->writeMessage({'type: common:WS_PONG});
        } else if messageType == common:WS_INIT {
            json|error token = message.payload.token;
            if token is json && token == MOCK_AUTH_TOKEN {
                check caller->writeMessage({'type: common:WS_ACK});
            } else {
                check caller->close(4403, "Forbidden", timeout = 1);
            }
        } else if messageType == common:WS_SUBSCRIBE {
            check sendGreetingEvent(caller, getMockMessageId(message));
        }
    }
}

// Authenticates the connection using the WebSocket upgrade request headers.
@websocket:ServiceConfig {
    subProtocols: [common:GRAPHQL_TRANSPORT_WS]
}
service /mock_header_auth on mockSubscriptionListener {
    isolated resource function get .(http:Request request) returns websocket:Service|websocket:UpgradeError {
        string|error authHeader = request.getHeader("Authorization");
        if authHeader is string && authHeader == string `Bearer ${MOCK_AUTH_TOKEN}` {
            return new MockGreetingWsService();
        }
        return error("Unauthorized", code = 401);
    }
}

isolated service class MockGreetingWsService {
    *websocket:Service;

    isolated remote function onMessage(websocket:Caller caller, json message) returns websocket:Error? {
        string messageType = getMockMessageType(message);
        if messageType == common:WS_PING {
            check caller->writeMessage({'type: common:WS_PONG});
        } else if messageType == common:WS_INIT {
            check caller->writeMessage({'type: common:WS_ACK});
        } else if messageType == common:WS_SUBSCRIBE {
            check sendGreetingEvent(caller, getMockMessageId(message));
        }
    }
}

// Accepts the WebSocket connection, but never sends the `connection_ack` message.
@websocket:ServiceConfig {
    subProtocols: [common:GRAPHQL_TRANSPORT_WS]
}
service /mock_no_ack on mockSubscriptionListener {
    isolated resource function get .() returns websocket:Service|websocket:UpgradeError {
        return new MockNoAckWsService();
    }
}

isolated service class MockNoAckWsService {
    *websocket:Service;

    isolated remote function onMessage(websocket:Caller caller, json message) {
    }
}

// Sends a `ping` message with a payload on subscribe and sends the subscription event only
// after receiving a `pong` message, the payload of which is recorded.
@websocket:ServiceConfig {
    subProtocols: [common:GRAPHQL_TRANSPORT_WS]
}
service /mock_ping on mockSubscriptionListener {
    isolated resource function get .() returns websocket:Service|websocket:UpgradeError {
        return new MockPingWsService();
    }
}

isolated service class MockPingWsService {
    *websocket:Service;

    private string subscriptionId = "";

    isolated remote function onMessage(websocket:Caller caller, json message) returns websocket:Error? {
        string messageType = getMockMessageType(message);
        if messageType == common:WS_INIT {
            check caller->writeMessage({'type: common:WS_ACK});
        } else if messageType == common:WS_SUBSCRIBE {
            string id = getMockMessageId(message);
            lock {
                self.subscriptionId = id;
            }
            check caller->writeMessage({'type: common:WS_PING, payload: {seq: "1"}});
        } else if messageType == common:WS_PING {
            // The client's own keep-alive ping, distinct from the server-initiated one above.
            check caller->writeMessage({'type: common:WS_PONG});
        } else if messageType == common:WS_PONG {
            json|error payload = message.payload;
            json payloadValue = payload is error ? () : payload;
            lock {
                recordedPongPayload = payloadValue.clone();
            }
            string id;
            lock {
                id = self.subscriptionId;
            }
            check sendGreetingEvent(caller, id);
        }
    }
}

// Sends two `ping` messages followed by the subscription event on subscribe, without waiting
// for `pong` messages. Used to verify the resilience of the client ping message handler.
@websocket:ServiceConfig {
    subProtocols: [common:GRAPHQL_TRANSPORT_WS]
}
service /mock_ping_push on mockSubscriptionListener {
    isolated resource function get .() returns websocket:Service|websocket:UpgradeError {
        return new MockPingPushWsService();
    }
}

isolated service class MockPingPushWsService {
    *websocket:Service;

    isolated remote function onMessage(websocket:Caller caller, json message) returns websocket:Error? {
        string messageType = getMockMessageType(message);
        if messageType == common:WS_PING {
            // The client's own keep-alive ping, distinct from the server-initiated ones above.
            check caller->writeMessage({'type: common:WS_PONG});
        } else if messageType == common:WS_INIT {
            check caller->writeMessage({'type: common:WS_ACK});
        } else if messageType == common:WS_SUBSCRIBE {
            check caller->writeMessage({'type: common:WS_PING});
            check caller->writeMessage({'type: common:WS_PING});
            check sendGreetingEvent(caller, getMockMessageId(message));
        }
    }
}

// Closes the first connection abnormally after sending a single event; serves the subscription
// normally on subsequent connections.
@websocket:ServiceConfig {
    subProtocols: [common:GRAPHQL_TRANSPORT_WS]
}
service /mock_drop on mockSubscriptionListener {
    isolated resource function get .() returns websocket:Service|websocket:UpgradeError {
        int connectionNumber;
        lock {
            mockDropConnectionCount += 1;
            connectionNumber = mockDropConnectionCount;
        }
        return new MockDropWsService(connectionNumber);
    }
}

isolated service class MockDropWsService {
    *websocket:Service;

    private final int connectionNumber;

    isolated function init(int connectionNumber) {
        self.connectionNumber = connectionNumber;
    }

    isolated remote function onMessage(websocket:Caller caller, json message) returns websocket:Error? {
        string messageType = getMockMessageType(message);
        if messageType == common:WS_PING {
            check caller->writeMessage({'type: common:WS_PONG});
        } else if messageType == common:WS_INIT {
            check caller->writeMessage({'type: common:WS_ACK});
        } else if messageType == common:WS_SUBSCRIBE {
            string id = getMockMessageId(message);
            check caller->writeMessage({'type: common:WS_NEXT, id: id, payload: {data: {seq: self.connectionNumber}}});
            if self.connectionNumber == 1 {
                // The drop is intentionally abnormal, so the echo is not expected within the
                // short timeout; ignore the error rather than propagating it as onMessage's result.
                websocket:Error? closeResult = caller->close(MOCK_ABNORMAL_CLOSURE_STATUS_CODE,
                        "Connection dropped", timeout = 1);
            } else {
                check caller->writeMessage({'type: common:WS_COMPLETE, id: id});
            }
        }
    }
}

// Closes the first connection abnormally after both subscriptions receive their first event;
// resumes the subscriptions on the second connection.
@websocket:ServiceConfig {
    subProtocols: [common:GRAPHQL_TRANSPORT_WS]
}
service /mock_reconnect on mockSubscriptionListener {
    isolated resource function get .() returns websocket:Service|websocket:UpgradeError {
        int connectionNumber;
        lock {
            mockReconnectConnectionCount += 1;
            connectionNumber = mockReconnectConnectionCount;
        }
        return new MockReconnectWsService(connectionNumber);
    }
}

isolated service class MockReconnectWsService {
    *websocket:Service;

    private final int connectionNumber;
    private int subscriptionCount = 0;

    isolated function init(int connectionNumber) {
        self.connectionNumber = connectionNumber;
    }

    isolated remote function onMessage(websocket:Caller caller, json message) returns websocket:Error? {
        string messageType = getMockMessageType(message);
        if messageType == common:WS_PING {
            check caller->writeMessage({'type: common:WS_PONG});
            return;
        }
        if messageType != common:WS_INIT && messageType != common:WS_SUBSCRIBE {
            return;
        }
        if messageType == common:WS_INIT {
            check caller->writeMessage({'type: common:WS_ACK});
            return;
        }
        string id = getMockMessageId(message);
        int subscriptionCount;
        lock {
            self.subscriptionCount += 1;
            subscriptionCount = self.subscriptionCount;
        }
        if self.connectionNumber == 1 {
            check caller->writeMessage({'type: common:WS_NEXT, id: id, payload: {data: {seq: 1}}});
            if subscriptionCount == 2 {
                // The drop is intentionally abnormal; ignore the close-frame echo error, as above.
                websocket:Error? closeResult = caller->close(MOCK_ABNORMAL_CLOSURE_STATUS_CODE,
                        "Connection dropped", timeout = 1);
            }
        } else {
            lock {
                mockReconnectSecondConnectionIds.push(id);
            }
            check caller->writeMessage({'type: common:WS_NEXT, id: id, payload: {data: {seq: 2}}});
            check caller->writeMessage({'type: common:WS_COMPLETE, id: id});
        }
    }
}

// Closes every connection abnormally right after a subscribe message. Used to verify closing
// the client while a reconnection is in progress.
@websocket:ServiceConfig {
    subProtocols: [common:GRAPHQL_TRANSPORT_WS]
}
service /mock_close_reconnect on mockSubscriptionListener {
    isolated resource function get .() returns websocket:Service|websocket:UpgradeError {
        lock {
            mockCloseReconnectConnectionCount += 1;
        }
        return new MockCloseReconnectWsService();
    }
}

isolated service class MockCloseReconnectWsService {
    *websocket:Service;

    isolated remote function onMessage(websocket:Caller caller, json message) returns websocket:Error? {
        string messageType = getMockMessageType(message);
        if messageType == common:WS_PING {
            check caller->writeMessage({'type: common:WS_PONG});
        } else if messageType == common:WS_INIT {
            check caller->writeMessage({'type: common:WS_ACK});
        } else if messageType == common:WS_SUBSCRIBE {
            // Signal the drop only after the close has been initiated, so the test does not race
            // the server-side closure and trigger a close-frame code collision. The drop is
            // intentionally abnormal, so the echo error is ignored rather than propagated.
            websocket:Error? closeResult = caller->close(MOCK_ABNORMAL_CLOSURE_STATUS_CODE,
                    "Connection dropped", timeout = 1);
            lock {
                mockCloseReconnectDropped = true;
            }
        }
    }
}

isolated function isMockCloseReconnectDropped() returns boolean {
    lock {
        return mockCloseReconnectDropped;
    }
}

// Closes the first connection abnormally when a subscription is completed by the client;
// records the resubscribed operation IDs on the second connection.
@websocket:ServiceConfig {
    subProtocols: [common:GRAPHQL_TRANSPORT_WS]
}
service /mock_selective_reconnect on mockSubscriptionListener {
    isolated resource function get .() returns websocket:Service|websocket:UpgradeError {
        int connectionNumber;
        lock {
            mockSelectiveConnectionCount += 1;
            connectionNumber = mockSelectiveConnectionCount;
        }
        return new MockSelectiveReconnectWsService(connectionNumber);
    }
}

isolated service class MockSelectiveReconnectWsService {
    *websocket:Service;

    private final int connectionNumber;

    isolated function init(int connectionNumber) {
        self.connectionNumber = connectionNumber;
    }

    isolated remote function onMessage(websocket:Caller caller, json message) returns websocket:Error? {
        string messageType = getMockMessageType(message);
        string id = getMockMessageId(message);
        if messageType == common:WS_PING {
            check caller->writeMessage({'type: common:WS_PONG});
        } else if messageType == common:WS_INIT {
            check caller->writeMessage({'type: common:WS_ACK});
        } else if messageType == common:WS_SUBSCRIBE {
            if self.connectionNumber == 1 {
                check caller->writeMessage({'type: common:WS_NEXT, id: id, payload: {data: {seq: 1}}});
            } else {
                lock {
                    mockSelectiveSecondConnectionIds.push(id);
                }
                check caller->writeMessage({'type: common:WS_NEXT, id: id, payload: {data: {seq: 2}}});
                check caller->writeMessage({'type: common:WS_COMPLETE, id: id});
            }
        } else if messageType == common:WS_COMPLETE {
            if self.connectionNumber == 1 {
                // The drop is intentionally abnormal; ignore the close-frame echo error, as above.
                websocket:Error? closeResult = caller->close(MOCK_ABNORMAL_CLOSURE_STATUS_CODE,
                        "Connection dropped", timeout = 1);
            }
        }
    }
}

// Drops the first connection abnormally right after a subscribe message and rejects every
// subsequent connection upgrade. Used to verify the reconnection exhaustion.
@websocket:ServiceConfig {
    subProtocols: [common:GRAPHQL_TRANSPORT_WS]
}
service /mock_exhaustion on mockSubscriptionListener {
    isolated resource function get .() returns websocket:Service|websocket:UpgradeError {
        int connectionNumber;
        lock {
            mockExhaustionConnectionCount += 1;
            connectionNumber = mockExhaustionConnectionCount;
        }
        if connectionNumber > 1 {
            return error("Service unavailable", code = 503);
        }
        return new MockExhaustionWsService();
    }
}

isolated service class MockExhaustionWsService {
    *websocket:Service;

    isolated remote function onMessage(websocket:Caller caller, json message) returns websocket:Error? {
        string messageType = getMockMessageType(message);
        if messageType == common:WS_PING {
            check caller->writeMessage({'type: common:WS_PONG});
        } else if messageType == common:WS_INIT {
            check caller->writeMessage({'type: common:WS_ACK});
        } else if messageType == common:WS_SUBSCRIBE {
            // The drop is intentionally abnormal; ignore the close-frame echo error, as above.
            websocket:Error? closeResult = caller->close(MOCK_ABNORMAL_CLOSURE_STATUS_CODE,
                    "Connection dropped", timeout = 1);
        }
    }
}

// Acknowledges the connection and sends a single event, then stops responding entirely — including
// ignoring the client's `ping` messages — to simulate a server that has silently died. Used to
// verify the client keep-alive detects the unresponsive connection.
@websocket:ServiceConfig {
    subProtocols: [common:GRAPHQL_TRANSPORT_WS]
}
service /mock_keepalive_silent on mockSubscriptionListener {
    isolated resource function get .() returns websocket:Service|websocket:UpgradeError {
        return new MockKeepAliveSilentWsService();
    }
}

isolated service class MockKeepAliveSilentWsService {
    *websocket:Service;

    private string subscriptionId = "";

    isolated remote function onMessage(websocket:Caller caller, json message) returns websocket:Error? {
        string messageType = getMockMessageType(message);
        if messageType == common:WS_INIT {
            check caller->writeMessage({'type: common:WS_ACK});
        } else if messageType == common:WS_SUBSCRIBE {
            string id = getMockMessageId(message);
            lock {
                self.subscriptionId = id;
            }
            check caller->writeMessage({'type: common:WS_NEXT, id: id, payload: {data: {seq: 1}}});
        } else if messageType == common:WS_PING {
            string id;
            lock {
                id = self.subscriptionId;
            }
            check caller->writeMessage({'type: common:WS_NEXT, id: id, payload: {data: {seq: 2}}});
            check caller->writeMessage({'type: common:WS_COMPLETE, id: id});
        }
    }
}

isolated int mockKeepAliveRecoverConnectionCount = 0;

@websocket:ServiceConfig {
    subProtocols: [common:GRAPHQL_TRANSPORT_WS]
}
service /mock_keepalive_recover on mockSubscriptionListener {
    isolated resource function get .() returns websocket:Service|websocket:UpgradeError {
        int connectionNumber;
        lock {
            mockKeepAliveRecoverConnectionCount += 1;
            connectionNumber = mockKeepAliveRecoverConnectionCount;
        }
        return new MockKeepAliveRecoverWsService(connectionNumber);
    }
}

isolated service class MockKeepAliveRecoverWsService {
    *websocket:Service;

    private final int connectionNumber;

    isolated function init(int connectionNumber) {
        self.connectionNumber = connectionNumber;
    }

    isolated remote function onMessage(websocket:Caller caller, json message) returns websocket:Error? {
        string messageType = getMockMessageType(message);
        if messageType == common:WS_INIT {
            check caller->writeMessage({'type: common:WS_ACK});
        } else if messageType == common:WS_SUBSCRIBE {
            string id = getMockMessageId(message);
            check caller->writeMessage({'type: common:WS_NEXT, id: id, payload: {data: {seq: self.connectionNumber}}});
            if self.connectionNumber > 1 {
                check caller->writeMessage({'type: common:WS_COMPLETE, id: id});
            } else {
                // The drop is intentionally abnormal; ignore the close-frame echo error, as above.
                websocket:Error? closeResult = caller->close(MOCK_ABNORMAL_CLOSURE_STATUS_CODE,
                        "Connection dropped", timeout = 1);
            }
        } else if messageType == common:WS_PING && self.connectionNumber > 1 {
            check caller->writeMessage({'type: common:WS_PONG});
        }
    }
}

isolated function sendGreetingEvent(websocket:Caller caller, string id) returns websocket:Error? {
    check caller->writeMessage({'type: common:WS_NEXT, id: id, payload: {data: {greet: "Hello"}}});
    check caller->writeMessage({'type: common:WS_COMPLETE, id: id});
}
