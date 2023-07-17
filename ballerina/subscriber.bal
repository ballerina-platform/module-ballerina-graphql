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

import ballerina/lang.runtime;
import ballerina/websocket;

# The Subscriber class serves as a client for handling a specific subscription operation.
# It stores the stream associated with the subscription and offers methods for accessing
# the subscription stream and unsubscribing from the subscription.
public distinct isolated client class Subscriber {
    private final string id;
    private final websocket:Client wsClient;
    private final SubscriberMessage[] messages = [];
    private typedesc<stream<GenericResponseWithErrors|record{}|json>> databindType;
    private boolean unsubscribed = false;
    private boolean streamConsumed = false;

    isolated function init(string id, websocket:Client wsClient, typedesc<stream<GenericResponseWithErrors|record{}|json>> targetType) {
        self.id = id;
        self.wsClient = wsClient;
        self.databindType = targetType;
    }

    private isolated function blockUntilMessagesNotEmptyOrUnsubscribed() {
        while true {
            runtime:sleep(1);
            lock {
                if self.messages.length() > 0 || self.unsubscribed || !self.wsClient.isOpen() {
                    break;
                }
            }
        }
    }

    isolated function addMessage(SubscriberMessage message) {
        lock {
            if self.unsubscribed {
                return;
            }
            self.messages.push(message.clone());
        }
    }

    # Unsubscribes from the subscription operation by sending a complete message via the graphql-transport-ws protocol.
    # + return - `graphql:ClientError` on failure, nil otherwise;
    isolated remote function unsubscribe() returns ClientError? {
        lock {
            if self.unsubscribed {
                return;
            }
            CompleteMessage message = {'type: WS_COMPLETE, id: self.id};
            websocket:Error? response = self.wsClient->writeMessage(message);
            if response is websocket:Error {
                return error ClientError(string `Failed to unsubscribe: ${response.message()}`, response.cause());
            }
            self.unsubscribed = true;
        }
    }

    isolated function getStream() returns stream<GenericResponseWithErrors|record{}|json> {
        stream<GenericResponseWithErrors|record{}|json> subscription = new (self);
        return subscription;
    }

    public isolated function next() returns record{|json value;|}? {
        self.blockUntilMessagesNotEmptyOrUnsubscribed();
        lock {
            if self.unsubscribed || !self.wsClient.isOpen() {
                return ();
            }
            SubscriberMessage message = self.messages.shift();
            if message is CompleteMessage {
                self.unsubscribed = true;
                return ();
            }
            json payload = message.payload;
            return {value: payload.clone()};
        }
    }
}
