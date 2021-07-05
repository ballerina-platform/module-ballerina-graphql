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

import ballerina/test;

@test:Config {
    groups: ["validation"]
}
isolated function testRequestSubtypeFromPrimitiveType() returns error? {
    string graphqlUrl = "http://localhost:9091/validation";
    string document = "{ name { first } }";
    json actualPayload = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    string expectedMessage = string`Field "name" must not have a selection since type "String" has no subfields.`;
    json expectedPayload = {
        errors: [
            {
                message: expectedMessage,
                locations: [
                    {
                        line: 1,
                        column: 10
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}


@test:Config {
    groups: ["validation"]
}
isolated function testDocumentWithSyntaxError() returns error? {
    string graphqlUrl = "http://localhost:9091/validation";
    string document = "{ name (id: ) }";
    json actualPayload = check getJsonPayloadFromBadRequest(graphqlUrl, document);
    string expectedMessage = string`Syntax Error: Unexpected ")".`;
    json expectedPayload = {
        errors: [
            {
                message: expectedMessage,
                locations: [
                    {
                        line: 1,
                        column: 13
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
