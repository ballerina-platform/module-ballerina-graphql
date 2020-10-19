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

listener Listener gqlListener = new(9091);

@test:Config {
    groups: ["listener", "unit"]
}
function testShortHandQueryResult() returns @tainted error? {
    string document = getShorthandNotationDocument();
    var result = gqlListener.__attach(gqlService1);
    json payload = {
        query: document
    };
    json expectedPayload = {
        data: {
            name: "John Doe",
            birthdate: "01-01-1980"
        }
    };
    http:Client httpClient = new("http://localhost:9091/bakerstreet");
    http:Request request = new;
    request.setPayload(payload);

    json actualPayload = <json> check httpClient->post("/", request, json);
    test:assertEquals(actualPayload, expectedPayload);
    var stopResult = gqlListener.__immediateStop();
}

@test:Config{
    groups: ["listener", "unit"]
}
function testInvalidShorthandQuery() returns @tainted error? {
    string document = getInvalidShorthandNotationDocument();
    var result = gqlListener.__attach(gqlService2);
    json payload = {
        query: document
    };
    json expectedPayload = {
        errors: [
            {
                message: "Cannot query field \"id\" on type \"Query\".",
                locations: [
                    {
                        line: 3,
                        column: 5
                    }
                ]
            }
        ]
    };
    http:Client httpClient = new("http://localhost:9091/bakerstreet");
    http:Request request = new;
    request.setPayload(payload);

    json actualPayload = <json> check httpClient->post("/", request, json);
    test:assertEquals(actualPayload, expectedPayload);
    var stopResult = gqlListener.__immediateStop();
}

service gqlService1 =
@ServiceConfiguration {
    basePath: "bakerstreet"
}
service {
    isolated resource function name() returns string {
        return "John Doe";
    }

    isolated resource function birthdate() returns string {
        return "01-01-1980";
    }
};

service gqlService2 =
@ServiceConfiguration {
    basePath: "graphql"
}
service {
    isolated resource function name() returns string {
        return "John Doe";
    }

    isolated resource function birthdate() returns string {
        return "01-01-1980";
    }
};
