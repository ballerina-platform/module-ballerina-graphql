// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com).
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

import ballerina/log;
import ballerinax/kafka;
import ballerina/uuid;

configurable decimal POLL_INTERVAL = 100.0;
final kafka:Producer producer = check new (kafka:DEFAULT_URL);

isolated function produceIssue(Issue newIssue, string repoName) returns error? {
    return producer->send({topic: repoName, value: newIssue});
}

isolated class IssueStream {
    private final string repoName;
    private final kafka:Consumer consumer;

    isolated function init(string repoName) returns error? {
        self.repoName = repoName;
        kafka:ConsumerConfiguration consumerConfiguration = {
            groupId: uuid:createType1AsString(),
            topics: repoName,
            maxPollRecords: 1
        };
        self.consumer = check new (kafka:DEFAULT_URL, consumerConfiguration);
    }

    public isolated function next() returns record {|Issue value;|}? {
        Issue[]|error issueRecords = self.consumer->pollPayload(POLL_INTERVAL);
        if issueRecords is error {
            log:printError("Failed to retrieve data from the Kafka server", issueRecords, id = self.repoName);
            return;
        }
        if issueRecords.length() < 1 {
            log:printWarn(string `No issues available in "${self.repoName}"`, id = self.repoName);
            return;
        }
        return {value: issueRecords[0]};
    }
}
