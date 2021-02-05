// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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

import ballerina/http;
import ballerina/lang.runtime;
import ballerina/test;

ListenerConfiguration configs = {
    timeoutInMillis: 1000,
    server: "TIMEOUT_SERVER"
};
listener Listener timeoutListener = new(9102, configs);

service /timeoutServer on timeoutListener {
    isolated resource function get greet() returns string {
        runtime:sleep(3);
        return "Hello";
    }
}

@test:Config {
    groups: ["listenerConfigs", "unit"]
}
function testTimeoutResponse() returns error? {
    string document = "{ greet }";
    json payload = {
        query: document
    };
    http:Client httpClient = check new("http://localhost:9102/timeoutServer");
    http:Request request = new;
    request.setPayload(payload);

    var response = check httpClient->post("/", request);
    if (response is http:Response) {
        int statusCode = response.statusCode;
        test:assertEquals(statusCode, 408, msg = "Unexpected status code received: " + statusCode.toString());

        var textPayload = response.getTextPayload();
        string expectedMessage = "Idle timeout triggered before initiating outbound response";
        string actualPaylaod = textPayload is error? textPayload.toString() : textPayload.toString();
        test:assertEquals(actualPaylaod, expectedMessage);
    }
}


