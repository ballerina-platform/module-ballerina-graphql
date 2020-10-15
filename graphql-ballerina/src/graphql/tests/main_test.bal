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

@test:Config{}
function testSimpleGraphqlQuery() {
    string document = getShorthandNotationDocument();
    var result = gqlListener.__attach(gqlService);
    json payload = {
        query: document
    };
    json expectedJson = {
        errors: [
            {
                message: "Cannot query field \"id\" on type \"query\".",
                locations: [
                    {
                        line: 3,
                        column: 5
                    }
                ]
            }
        ],
        data: {
            name: "John Doe",
            birthDate: "01-01-1980"
        }
    };
    http:Client httpClient = new("http://localhost:9091/bakerstreet");
    http:Request request = new;
    request.setPayload(payload);

    var sendResult = httpClient->post("/", request);
    if (sendResult is error) {
        test:assertFail("Error response received for the HTTP call");
    } else {
        var responsePayload = sendResult.getJsonPayload();
        if (responsePayload is json) {
            test:assertEquals(responsePayload, expectedJson);
        }
    }
    var stopResult = gqlListener.__immediateStop();
}

service gqlService =
@ServiceConfiguration {
    basePath: "bakerstreet"
}
service {
    isolated resource function name() returns string {
        return "John Doe";
    }

    isolated resource function birthDate() returns string {
        return "01-01-1980";
    }
};
