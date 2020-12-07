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
import ballerina/io;

import graphql.parser;

const DOCUMENT_TWO_ANONYMOUS_OPERATIONS = "two_anonymous_operations.txt";
const DIR_DOCUMENTS = "documents";

function getDocumentWithTwoAnonymousOperations() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic file:joinPath(documentsDirPath, DOCUMENT_TWO_ANONYMOUS_OPERATIONS);
    return readFileAndGetString(path);
}

function getInvalidShorthandNotationDocument() returns string {
    string documentsDirPath = checkpanic getDocumentsPath();
    string path = checkpanic file:joinPath(documentsDirPath, DOCUMENT_SHORTHAND_INVALID);
    return readFileAndGetString(path);
}

function getDocumentsPath() returns string|error {
    string resourcePath = check getResourcePath();
    return file:joinPath(resourcePath, DIR_DOCUMENTS);
}

function getResourcePath() returns string|error {
    return file:joinPath("tests", "resources");
}

function readFileAndGetString(string filePath) returns string {
    var fileText = io:fileReadString(filePath);
    if (fileText is error) {
        parser:logAndPanicError("Error occurred while reading the document", fileText);
    }
    return <@untainted string>fileText;
}
