// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/file;
import ballerina/io;
import graphql.parser;

isolated function getGraphQLDocumentFromFile(string fileName) returns string|error {
    string path = check file:joinPath("tests", "resources", "documents", fileName);
    return io:fileReadString(path);
}

isolated function getJsonContentFromFile(string fileName) returns json|error {
    string path = check file:joinPath("tests", "resources", "expected_results", fileName);
    return io:fileReadJson(path);
}

isolated function getDocumentNode(string documentString) returns parser:DocumentNode|parser:Error {
    parser:Parser parser = new (documentString);
    return parser.parse();
}

isolated function appendGraphqlExtension(string fileName) returns string {
    return string `${fileName}.graphql`;
}

isolated function appendJsonExtension(string fileName) returns string {
    return string `${fileName}.json`;
}
