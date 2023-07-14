// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

import ballerina/websocket;

public distinct isolated client class Subscriber {
    private final string id;
    private final websocket:Client wsClient;
    // todo: databinding
    private typedesc<stream<GenericResponseWithErrors|record {}|json>> targetType;
    private boolean unsubscribed = false;

    isolated function init(string id, websocket:Client wsClient, typedesc<stream<GenericResponseWithErrors|record {}|json>> targetType) {
        self.id = id;
        self.wsClient = wsClient;
        self.targetType = targetType;
    }

    isolated function getStream() returns stream<json, ClientError?> {
        stream<json, ClientError?> subscription = new (self);
        return subscription;
    }

    // Stream generator functionality is handled in Subscriber itself. 
    public isolated function next() returns record {|json value;|}? {
        lock {
            if self.unsubscribed || !self.wsClient.isOpen() {
                return ();
            }
            SubscriberMessage? message = checkpanic readEvent(self.wsClient);
            // todo: Add timeout
            while (message is ()) {
                message = checkpanic readEvent(self.wsClient);
            }

            if message is () {
                return ();
            } else {
                if message is CompleteMessage {
                    self.unsubscribed = true;
                    return ();
                }
                json payload = message.payload;
                return {value: payload.clone()};
            }
        }
    }
}

isolated function readEvent(websocket:Client wsClient) returns SubscriberMessage?|error {
    ClientInboundMessage message = check wsClient->readMessage();
    if message is PingMessage {
        PongMessage pong = {'type: WS_PONG};
        check wsClient->writeMessage(pong);
    }

    if message is SubscriberMessage {
        return message;
    }
    return ();
}
