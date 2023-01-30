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

class PingMessageJob {
    *task:Job;
    private final websocket:Caller caller;
    private task:JobId? id = ();

    isolated function init(websocket:Caller caller) {
        self.caller = caller;
    }

    public isolated function execute() {
        self.sendPeriodicPingMessageRequests();
    }

    public isolated function schedule() {
        task:JobId|error id = task:scheduleJobRecurByFrequency(self, PING_MESSAGE_SCHEDULE_INTERVAL);
        if id is error {
            return logError("Failed to schedule PingMessageJob", id);
        }
        self.id = id;
    }

    public isolated function unschedule() returns error? {
        task:JobId? id = self.id;
        if id is () {
            return;
        }
        check task:unscheduleJob(id);
        self.id = ();
    }

    private isolated function sendPeriodicPingMessageRequests() {
        do {
            lock {
                task:JobId? id = self.id;
                if id is () {
                    return;
                }
                if !self.caller.isOpen() {
                    check self.unschedule();
                    return;
                }
                PingMessage message = {'type: WS_PING};
                check writeMessage(self.caller, message);
            }
        } on fail error cause {
            string message = cause is websocket:Error ? "Failed to send ping message: "
                : "Failed to unschedule PingMessageJob: ";
            message += cause.message();
            logError(message, cause);
        }
    }
}
