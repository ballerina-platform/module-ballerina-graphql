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

import ballerina/test;

Token[] fields = [
    {
        value: "name",
        line: 2,
        column: 5
    },
    {
        value: "id",
        line: 3,
        column: 5
    },
    {
        value: "birthDate",
        line: 4,
        column: 5
    }
];

@test:Config{}
function testParseShorthandDocument() returns error? {
    string document = getShorthandNotationDocument();
    Document parsedDocument = check parse(document);
    Document expectedDocument = {
        operations: [
            {
                'type: "query",
                fields: fields
            }
        ]
    };
    test:assertEquals(parsedDocument, expectedDocument);
}

@test:Config{}
function testParseGeneralNotationDocument() returns error? {
    string document = getGeneralNotationDocument();
    Document parsedDocument = check parse(document);
    Operation expectedOperation = {
        'type: "query",
        name: "getData",
        fields: fields
    };
    Document expectedDocument = {
        operations: [expectedOperation]
    };
    test:assertEquals(parsedDocument, expectedDocument);
}

@test:Config{}
function testParseAnonymousOperation() returns error? {
    string document = getAnonymousOperationDocument();
    Document result = check parse(document);
    Document expected = {
        operations: [
            {
                'type: "query",
                fields: fields
            }
        ]
    };
    test:assertEquals(result, expected);
}

@test:Config{}
function testParseDocumentWithNoCloseBrace() returns error? {
    string document = getNoCloseBraceDocument();
    Document|Error result = parse(document);
    if (result is Document) {
        test:assertFail("Expected error, received document");
    } else {
        test:assertEquals(result.message(), "Syntax Error: Expected Name, found \\\"<EOF>\\\".");
    }
}
