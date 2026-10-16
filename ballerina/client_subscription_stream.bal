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

// The generator of the streams returned by the `subscribe()` method of the GraphQL client.
// Consumes the events dispatched to the message queue of the subscription operation and data
// binds each event to the target type.
isolated class SubscriptionStreamGenerator {
    private final string id;
    private final MessageQueue queue;
    private final typedesc<GenericResponseWithErrors|record {}> targetType;
    private final SubscriptionConnection connection;
    // Set once a terminal value has actually been consumed from the queue, so that repeated
    // next() calls after the stream ends return immediately without blocking on dequeue().
    private boolean terminated = false;

    isolated function init(string id, MessageQueue queue,
            typedesc<GenericResponseWithErrors|record {}> targetType, SubscriptionConnection connection) {
        self.id = id;
        self.queue = queue;
        self.targetType = targetType;
        self.connection = connection;
    }

    public isolated function next() returns record {|anydata value;|}|ClientError? {
        lock {
            if self.terminated {
                return;
            }
        }
        // Do not short-circuit on the connection's closed state: close()/unsubscribe()/connection
        // failures always enqueue a terminal value per operation, so any payloads already buffered
        // in the queue must still be drained before the terminal `()` is observed here.
        any|error message = self.queue.dequeue();
        if message is () {
            self.markTerminated();
            return;
        }
        if message is ClientError {
            self.markTerminated();
            return message;
        }
        if message is error {
            self.markTerminated();
            return error SubscriptionError(message.message(), message, errors = ());
        }
        if message is json {
            GenericResponseWithErrors|record {}|PayloadBindingError response =
                performDataBindingWithErrors(self.targetType, message);
            if response is PayloadBindingError {
                // The binding failure terminates the stream; unsubscribe from the operation.
                self.markTerminated();
                ClientError? unsubscribeResult = self.connection.unsubscribe(self.id);
                if unsubscribeResult is ClientError {
                    logError("Failed to unsubscribe from the subscription operation", unsubscribeResult);
                }
                return response;
            }
            return {value: response};
        }
        self.markTerminated();
        return error SubscriptionError(INVALID_SUBSCRIPTION_MESSAGE, errors = ());
    }

    isolated function markTerminated() {
        lock {
            self.terminated = true;
        }
    }

    public isolated function close() returns ClientError? {
        return self.connection.unsubscribe(self.id);
    }
}
