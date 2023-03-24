// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/test;
import ballerina/websocket;

const WS_INIT = "connection_init";
const WS_ACK = "connection_ack";
const WS_SUBSCRIBE = "subscribe";
const WS_NEXT = "next";
const WS_PING = "ping";
const WS_PONG = "pong";

isolated function validateConnectionAckMessage(websocket:Client wsClient) returns websocket:Error? {
    json response = check wsClient->readMessage();
    test:assertEquals(response.'type, WS_ACK);
}

isolated function sendConnectionInitMessage(websocket:Client wsClient) returns websocket:Error? {
    check wsClient->writeMessage({'type: WS_INIT});
}

isolated function initiateGraphqlWsConnection(websocket:Client wsClient) returns websocket:Error? {
    check sendConnectionInitMessage(wsClient);
    check validateConnectionAckMessage(wsClient);
}

isolated function sendSubscriptionMessage(websocket:Client wsClient, string document, string id = "1",
        json? variables = {}, string? operationName = ()) returns websocket:Error? {
    json payload = {query: document, variables: variables, operationName: operationName};
    json wsPayload = {'type: WS_SUBSCRIBE, id: id, payload: payload};
    return wsClient->writeMessage(wsPayload);
}

isolated function validateNextMessage(websocket:Client wsClient, json expectedMsgPayload, string id = "1")
returns websocket:Error? {
    json expectedPayload = {'type: WS_NEXT, id, payload: expectedMsgPayload};
    json actualPayload = check readMessageExcludingPingMessages(wsClient);
    test:assertEquals(actualPayload, expectedPayload);
}

isolated function readMessageExcludingPingMessages(websocket:Client wsClient) returns json|websocket:Error {
    json message = null;
    foreach int i in 0..<10 {
        message = check wsClient->readMessage();
        if message == null {
            continue;
        }
        if message.'type == WS_PING {
            check sendPongMessage(wsClient);
            continue;
        }
        return message;
    }
}

isolated function sendPongMessage(websocket:Client wsClient) returns websocket:Error? {
    json message = {'type: WS_PONG};
    check wsClient->writeMessage(message);
}

isolated function closeConnection(websocket:Client wsClient, string id = "1") returns websocket:Error? {
    check wsClient->writeMessage({'type: "complete", id});
    check wsClient->close();
}
