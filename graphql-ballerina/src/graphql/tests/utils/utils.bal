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

import ballerina/io;
import ballerina/log;
import ballerina/test;

function getDocumentWithComments() returns string {
    return readFileAndGetString(DOCUMENT_WITH_COMMENTS, 98);
}

function getDocumentWithParameters() returns string {
    return readFileAndGetString(DOCUMENT_WITH_PARAMTER, 115);
}

function getShorthandNotationDocument() returns string {
    return readFileAndGetString(DOCUMENT_SHORTHAND, 27);
}

function getGeneralNotationDocument() returns string {
    return readFileAndGetString(DOCUMENT_GENERAL, 47);
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

function readFileAndGetString(string fileName, int length) returns string {
    var fileText = readFile(RESOURCE_PATH + fileName, length);
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

function checkErrorRecord(Error err, int line, int column) {
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

function printTokens(Token[] tokens) {
    foreach Token token in tokens {
        io:println(token);
    }
}
