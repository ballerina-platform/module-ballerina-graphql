// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/file;
import ballerina/http;
import ballerina/io;

final http:Client httpClient = check new("http://localhost:9090/graphql", httpVersion = "1.1");

function getJsonPayloadFromService(string document, json variables = {}, string? operationName = ()) returns json|error {
    if operationName is string {
        http:Response|error result = httpClient->post("/", { query: document, operationName: operationName, variables: variables });
        if result is http:Response {
            return result.getJsonPayload();
        } else {
            return result;
        }
    }
    return check httpClient->post("/", { query: document, variables: variables });
}

isolated function getGraphqlDocumentFromFile(string fileName) returns string|error {
    string gqlFileName = string `${fileName}.graphql`;
    string path = check file:joinPath("starwars", "tests", "resources", "documents", gqlFileName);
    return io:fileReadString(path);
}
