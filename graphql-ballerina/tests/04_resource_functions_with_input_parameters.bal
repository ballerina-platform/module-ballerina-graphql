// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/test;

listener Listener functionWithArgumentsListener = new(9093);

service /graphql on functionWithArgumentsListener {
    isolated resource function query greet(string name) returns string {
        return "Hello, " + name;
    }
}


@test:Config {
    groups: ["listener", "unit"]
}
function testFunctionsWithInputParameter() returns @tainted error? {
    string document = getGreetingQueryDocument();
    json payload = {
        query: document
    };
    json expectedPayload = {
        data: {
            greet: "Hello, Thisaru"
        }
    };
    http:Client httpClient = new("http://localhost:9093/graphql");
    http:Request request = new;
    request.setPayload(payload);

    json actualPayload = <json> check httpClient->post("/", request, json);
    test:assertEquals(actualPayload, expectedPayload);
}

