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

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testInvalidCharacter() returns error? {
    string name = "John D<oe";
    Lexer lexer = new(name);
    Token? token = check lexer.getNext();
    test:assertTrue(token is Token);

    Token expectedToken = {
        value: "John",
        'type: T_WORD,
        location: {
            line: 1,
            column: 1
        }
    };
    test:assertEquals(token, expectedToken);

    token = check lexer.getNext();
    test:assertTrue(token is Token);
    expectedToken = {
        value: "<T>",
        'type: T_WHITE_SPACE,
        location: {
            line: 1,
            column: 5
        }
    };
    test:assertEquals(token, expectedToken);

    var next = lexer.getNext();
    test:assertTrue(next is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>next;
    string message = err.message();
    string expectedMessage = "Syntax Error: Cannot parse the unexpected character \"<\".";
    test:assertEquals(message, expectedMessage);
    checkErrorRecord(err, 1, 7);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testIntInput() returns error? {
    string s = "42";
    Lexer lexer = new(s);
    Token? token = check lexer.getNext();
    test:assertTrue(token is Token);
    Token expectedToken = {
        value: 42,
        'type: T_NUMERIC,
        location: {
            line: 1,
            column: 1
        }
    };
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testFloatInput() returns error? {
    string s = "3.14159";
    Lexer lexer = new(s);
    Token? token = check lexer.getNext();
    test:assertTrue(token is Token);
    Token expectedToken = {
        value: 3.14159,
        'type: T_NUMERIC,
        location: {
            line: 1,
            column: 1
        }
    };
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testNegativeIntInput() returns error? {
    string s = "test integer -273";
    Lexer lexer = new(s);
    Token? token = check lexer.getNextNonWhiteSpaceToken(); // test
    token = check lexer.getNextNonWhiteSpaceToken(); // integer
    token = check lexer.getNextNonWhiteSpaceToken();
    test:assertTrue(token is Token);
    Token expectedToken = {
        value: -273,
        'type: T_NUMERIC,
        location: {
            line: 1,
            column: 14
        }
    };
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testBooleanInput() returns error? {
    string s = "test false";
    Lexer lexer = new(s);
    Token? token = check lexer.getNext();
    test:assertTrue(token is Token);
    Token expectedToken = {
        value: "test",
        'type: T_WORD,
        location: {
            line: 1,
            column: 1
        }
    };
    test:assertEquals(token, expectedToken);

    token = check lexer.getNext(); // Space
    token = check lexer.getNext();
    test:assertTrue(token is Token);
    expectedToken = {
        value: false,
        'type: T_BOOLEAN,
        location: {
            line: 1,
            column: 6
        }
    };
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testStringInputWithNonWhiteSpaceTokenRetrieval() returns error? {
    string s = "test \"This is a test string\"";
    Lexer lexer = new(s);
    Token? token = check lexer.getNextNonWhiteSpaceToken();
    test:assertTrue(token is Token);
    Token expectedToken = {
        value: "test",
        'type: T_WORD,
        location: {
            line: 1,
            column: 1
        }
    };
    test:assertEquals(token, expectedToken);

    token = check lexer.getNextNonWhiteSpaceToken();
    test:assertTrue(token is Token);
    expectedToken = {
        value: "This is a test string",
        'type: T_STRING,
        location: {
            line: 1,
            column: 6
        }
    };
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
function testStringWithQuote() returns error? {
    string s = getTextWithQuoteFile();
    Lexer lexer = new(s);
    Token? token = check lexer.getNextNonWhiteSpaceToken();
    test:assertTrue(token is Token);
    Token expectedToken = {
        value: "test",
        'type: T_WORD,
        location: {
            line: 1,
            column: 1
        }
    };
    test:assertEquals(token, expectedToken);

    token = check lexer.getNextNonWhiteSpaceToken();
    test:assertTrue(token is Token);
    expectedToken = {
        value: "This is a \\\"test\\\" string",
        'type: T_STRING,
        location: {
            line: 1,
            column: 6
        }
    };
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
function testUnterminatedString() returns error? {
    string s = getTextWithUnterminatedStringFile();
    Lexer lexer = new(s);
    Token? token = check lexer.getNextNonWhiteSpaceToken();
    test:assertTrue(token is Token);
    Token expectedToken = {
        value: "test",
        'type: T_WORD,
        location: {
            line: 1,
            column: 1
        }
    };
    test:assertEquals(token, expectedToken);

    var result = lexer.getNextNonWhiteSpaceToken();
    test:assertTrue(result is UnterminatedStringError);
    UnterminatedStringError err = <UnterminatedStringError>result;
    string expectedMessage = "Syntax Error: Unterminated string.";
    string message = err.message();
    test:assertEquals(message, expectedMessage);
    checkErrorRecord(err, 1, 6);
}
