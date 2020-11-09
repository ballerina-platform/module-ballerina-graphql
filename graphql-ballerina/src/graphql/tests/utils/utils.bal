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
import ballerina/log;
import ballerina/test;

function getDocumentWithComments() returns string {
    string resourcePath = checkpanic getResourcePath();
    return readFileAndGetString(DOCUMENT_WITH_COMMENTS, 98);
}

function getDocumentWithParameters() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic filepath:build(documentsDirPath, DOCUMENT_WITH_PARAMTER);
    return readFileAndGetString(path, 310);
}

function getDocumentWithTwoNamedOperations() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic filepath:build(documentsDirPath, DOCUMENT_TWO_NAMED_OPERATIONS);
    return readFileAndGetString(path, 65);
}

function getDocumentForResourcesWithRecord() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic filepath:build(documentsDirPath, DOCUMENT_QUERY_FOR_RESOURCES_WITH_RECORD);
    return readFileAndGetString(path, 87);
}

function getDocumentWithTwoAnonymousOperations() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic filepath:build(documentsDirPath, DOCUMENT_TWO_ANONYMOUS_OPERATIONS);
    return readFileAndGetString(path, 37);
}

function getShorthandNotationDocument() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic filepath:build(documentsDirPath, DOCUMENT_SHORTHAND);
    return readFileAndGetString(path, 27);
}

function getGeneralNotationDocument() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic filepath:build(documentsDirPath, DOCUMENT_GENERAL);
    return readFileAndGetString(path, 47);
}

function getInvalidShorthandNotationDocument() returns string {
    return readFileAndGetString(DOCUMENT_SHORTHAND_INVALID, 34);
}

function getAnonymousOperationDocument() returns string {
    return readFileAndGetString(DOCUMENT_ANONYMOUS, 39);
}

function getNoCloseBraceDocument() returns string {
    return readFileAndGetString(DOCUMENT_NO_CLOSE_BRACE, 38);
}

function getTextWithQuoteFile() returns string {
    string textDirPath = checkpanic getTextPath();
    string path = checkpanic filepath:build(textDirPath, TEXT_WITH_STRING);
    return readFileAndGetString(path, 48);
}

function getTextWithUnterminatedStringFile() returns string {
    string textDirPath = checkpanic getTextPath();
    string path = checkpanic filepath:build(textDirPath, TEXT_WITH_UNTERMINATED_STRING);
    return readFileAndGetString(path, 32);
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

function readJson(string path) returns @tainted json|error {
    io:ReadableByteChannel rbc = check io:openReadableFile(path);
    io:ReadableCharacterChannel rch = new (rbc, "UTF8");
    var result = rch.readJson();
    closeReadChannel(rch);
    return result;
}

function readFileAndGetString(string filePath, int length) returns string {
    var fileText = readFile(filePath, length);
    if (fileText is error) {
        logAndPanicError("Error occurred while reading the document", fileText);
    }
    return <string>fileText;
}

function readFile(string path, int count) returns string|error {
    io:ReadableByteChannel rbc = check <@untainted>io:openReadableFile(path);
    io:ReadableCharacterChannel rch = new (rbc, "UTF8");
    var result = <@untainted>rch.read(count);
    closeReadChannel(rch);
    return result;
}

function closeReadChannel(io:ReadableCharacterChannel rc) {
    var result = rc.close();
    if (result is error) {
        log:printError("Error occurred while closing character stream", result);
    }
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
