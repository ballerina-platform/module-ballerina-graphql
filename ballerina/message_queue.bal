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

import ballerina/jballerina.java;

// A generic blocking queue used to signal and wait across strands, shared by the client's
// subscription dispatch/keep-alive strands and the server's keep-alive strand. A `()` item marks
// the end of a stream when used to connect a dispatcher (producer) with a stream generator
// (consumer); when used purely as a signal, the enqueued value itself is never read.
isolated class MessageQueue {
    isolated function init() {
        self.externInit();
    }

    isolated function externInit() = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.queue.MessageQueue"
    } external;

    isolated function enqueue(any|error item) = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.queue.MessageQueue"
    } external;

    isolated function dequeue() returns any|error = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.queue.MessageQueue"
    } external;

    // Returns `()` when no item is received within the given timeout (in seconds).
    isolated function dequeueWithTimeout(decimal timeout) returns any|error = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.queue.MessageQueue"
    } external;
}
