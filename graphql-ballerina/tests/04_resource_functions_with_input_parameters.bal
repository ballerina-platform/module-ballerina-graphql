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

import ballerina/test;

listener Listener functionWithArgumentsListener = new(9093);

service /graphql on functionWithArgumentsListener {
    isolated resource function get greet(string name) returns string {
        return "Hello, " + name;
    }

    isolated resource function get isLegal(int age) returns boolean {
        if (age < 21) {
            return false;
        }
        return true;
    }
}

@test:Config {
    groups: ["input_types", "unit"]
}
isolated function testFunctionsWithInputParameter() returns error? {
    string document = string
    `{
    greet (name: "Thisaru")
}`;
    string url = "http://localhost:9093/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            greet: "Hello, Thisaru"
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["input_types", "unit"]
}
isolated function testInputParameterTypeNotPresentInReturnTypes() returns error? {
    string document = "{ isLegal(age: 21) }";
    string url = "http://localhost:9093/graphql";
    json actualPayload = check getJsonPayloadFromService(url, document);

    json expectedPayload = {
        data: {
            isLegal: true
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}
