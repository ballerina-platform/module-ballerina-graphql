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

import ballerina/file;
import ballerina/http;
import ballerina/io;

const SHORTHAND_DOCUMENT = "document_shorthand.txt";
const INVALID_SHORTHAND_DOCUMENT = "document_shorthand_invalid_query.txt";
const DOCUMENT_TWO_ANONYMOUS_OPERATIONS = "two_anonymous_operations.txt";
const DOCUMENT_GENERAL = "document_general.txt";
const GREETING_QUERY_DOCUMENT = "greeting_query.txt";
const DIR_DOCUMENTS = "documents";

isolated function getGreetingQueryDocument() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic file:joinPath(documentsDirPath, GREETING_QUERY_DOCUMENT);
    return readFileAndGetString(path);
}

isolated function getGeneralNotationDocument() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic file:joinPath(documentsDirPath, DOCUMENT_GENERAL);
    return readFileAndGetString(path);
}

isolated function getShorthandDocument() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic file:joinPath(documentsDirPath, SHORTHAND_DOCUMENT);
    return readFileAndGetString(path);
}

isolated function getShorthandDocumentWithInvalidQuery() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic file:joinPath(documentsDirPath, INVALID_SHORTHAND_DOCUMENT);
    return readFileAndGetString(path);
}

isolated function getDocumentWithTwoAnonymousOperations() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic file:joinPath(documentsDirPath, DOCUMENT_TWO_ANONYMOUS_OPERATIONS);
    return readFileAndGetString(path);
}

isolated function getInvalidShorthandNotationDocument() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic file:joinPath(documentsDirPath, DOCUMENT_SHORTHAND_INVALID);
    return readFileAndGetString(path);
}

isolated function getDocumentsPath() returns string|error {
    string resourcePath = check getResourcePath();
    return file:joinPath(resourcePath, DIR_DOCUMENTS);
}

isolated function getResourcePath() returns string|error {
    return file:joinPath("tests", "resources");
}

isolated function readFileAndGetString(string filePath) returns string {
    var fileText = io:fileReadString(filePath);
    if (fileText is error) {
        panic fileText;
    } else {
        return <@untainted>fileText;
    }
}

isolated function getJsonPayloadFromService(string url, string document) returns json|error {
    http:Client httpClient = check new(url);
    return check httpClient->post("/", { query: document }, targetType = json);
}
