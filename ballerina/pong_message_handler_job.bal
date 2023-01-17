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
import ballerina/task;
import ballerina/time;

class PongMessageHandlerJob {
    *task:Job;
    private final websocket:Caller caller;
    private task:JobId? id = ();
    private boolean pongReceived = false;

    isolated function init(websocket:Caller caller) {
        self.caller = caller;
    }

    public isolated function execute() {
        self.checkForPongMessages();
    }

    public isolated function setPongMessageReceived() {
        lock {
            self.pongReceived = true;
        }
    }

    public isolated function schedule() {
        time:Civil startTime = time:utcToCivil(time:utcAddSeconds(time:utcNow(), PONG_MESSAGE_HANDLER_SCHEDULE_INTERVAL));
        task:JobId|error id = task:scheduleJobRecurByFrequency(self, PONG_MESSAGE_HANDLER_SCHEDULE_INTERVAL, startTime = startTime);
        if id is error {
            return logError("Failed to schedule PongMessageHandlerJob", id);
        }
        self.id = id;
    }

    private isolated function checkForPongMessages() {
        do {
            lock {
                task:JobId? id = self.id;
                if id is () {
                    return;
                }
                if !self.caller.isOpen() {
                    check task:unscheduleJob(id);
                    self.id = ();
                    return;
                }
                if self.caller.isOpen() && !self.pongReceived {
                    SubscriptionError err = error("Request timeout", code = 4408);
                    closeConnection(self.caller, err, timeout = 0);
                }
                self.pongReceived = false;
            }
        } on fail error cause {
            string message = "Filed to unschedule PingMessageJob";
            logError(message, cause);
        }
    }
}
