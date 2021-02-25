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
import ballerina/test;
import ballerina/io;

service /graphql on new Listener(9104) {
    isolated resource function get foo/bar/baz() returns string {
        return "Sherlock";
    }

    isolated resource function get foo/bar/baf() returns string {
        return "Holmes";
    }

    isolated resource function get foo/daz() returns int {
        return 40;
    }
}

@test:Config {
    groups: ["test", "hierarchicalPaths", "unit"]
}
function testHierarchicalResourcePaths() returns error? {
    string document = "{ foo { bar { baf } } }";
    json payload = {
        query: document
    };
    http:Client httpClient = check new("http://localhost:9104/graphql");
    http:Request request = new;
    request.setPayload(payload);

    json expectedPayload = {
        data: {
            profile: {
                name: {
                    first: "Sherlock"
                }
            }
        }
    };

    json actualPayload = <json> check httpClient->post("/", request, json);
    io:println(actualPayload);

    test:assertEquals(actualPayload, expectedPayload);
}
