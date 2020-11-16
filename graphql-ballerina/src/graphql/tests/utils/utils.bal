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

import ballerina/filepath;
import ballerina/io;
import ballerina/test;

function getDocumentWithComments() returns string {
    string resourcePath = checkpanic getResourcePath();
    return readFileAndGetString(DOCUMENT_WITH_COMMENTS);
}

function getDocumentWithParameters() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic filepath:build(documentsDirPath, DOCUMENT_WITH_PARAMTER);
    return readFileAndGetString(path);
}

function getDocumentWithTwoNamedOperations() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic filepath:build(documentsDirPath, DOCUMENT_TWO_NAMED_OPERATIONS);
    return readFileAndGetString(path);
}

function getDocumentForResourcesWithRecord() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic filepath:build(documentsDirPath, DOCUMENT_QUERY_FOR_RESOURCES_WITH_RECORD);
    return readFileAndGetString(path);
}

function getDocumentWithTwoAnonymousOperations() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic filepath:build(documentsDirPath, DOCUMENT_TWO_ANONYMOUS_OPERATIONS);
    return readFileAndGetString(path);
}

function getShorthandNotationDocument() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic filepath:build(documentsDirPath, DOCUMENT_SHORTHAND);
    return readFileAndGetString(path);
}

function getGeneralNotationDocument() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic filepath:build(documentsDirPath, DOCUMENT_GENERAL);
    return readFileAndGetString(path);
}

function getInvalidShorthandNotationDocument() returns string {
    return readFileAndGetString(DOCUMENT_SHORTHAND_INVALID);
}

function getAnonymousOperationDocument() returns string {
    return readFileAndGetString(DOCUMENT_ANONYMOUS);
}

function getNoCloseBraceDocument() returns string {
    return readFileAndGetString(DOCUMENT_NO_CLOSE_BRACE);
}

function getTextWithQuoteFile() returns string {
    string textDirPath = checkpanic getTextPath();
    string path = checkpanic filepath:build(textDirPath, TEXT_WITH_STRING);
    return readFileAndGetString(path);
}

function getTextWithUnterminatedStringFile() returns string {
    string textDirPath = checkpanic getTextPath();
    string path = checkpanic filepath:build(textDirPath, TEXT_WITH_UNTERMINATED_STRING);
    return readFileAndGetString(path);
}

function getParsedJsonForDocumentWithParameters() returns json {
    string jsonDirPath = checkpanic getJsonPath();
    string path = checkpanic filepath:build(jsonDirPath, JSON_WITH_PARAMETERS);
    return checkpanic <@untainted>readJson(path);
}

isolated function getDocumentsPath() returns string|error {
    string resourcePath = check getResourcePath();
    return filepath:build(resourcePath, DIR_DOCUMENTS);
}

isolated function getJsonPath() returns string|error {
    string resourcePath = check getResourcePath();
    return filepath:build(resourcePath, DIR_JSON);
}

isolated function getTextPath() returns string|error {
    string resourcePath = check getResourcePath();
    return filepath:build(resourcePath, DIR_TEXTS);
}

isolated function getResourcePath() returns string|error {
    return filepath:build("src", "graphql", "tests", "resources");
}

function readJson(string path) returns json|error {
    var result = io:fileReadJson(path);
    return <@untainted>result;
}

function readFileAndGetString(string filePath) returns string {
    var fileText = io:fileReadString(filePath);
    if (fileText is error) {
        logAndPanicError("Error occurred while reading the document", fileText);
    }
    return <@untainted string>fileText;
}

isolated function checkErrorRecord(Error err, int line, int column) {
    ErrorRecord expectedErrorRecord = {
        locations: [
            {
                line: line,
                column: column
            }
        ]
        };
    ErrorRecord errorRecord = <ErrorRecord>err.detail()[FIELD_ERROR_RECORD];
    test:assertEquals(errorRecord, expectedErrorRecord);
}
