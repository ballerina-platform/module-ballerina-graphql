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
    Token token = check lexer.next();

    Token expectedToken = getExpectedToken("John", T_WORD, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.next();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 1, 5);
    test:assertEquals(token, expectedToken);

    var next = lexer.next();
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
    Token token = check lexer.next();
    Token expectedToken = getExpectedToken(42, T_NUMERIC, 1, 1);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testFloatInput() returns error? {
    string s = "3.14159";
    Lexer lexer = new(s);
    Token token = check lexer.next();
    Token expectedToken = getExpectedToken(3.14159, T_NUMERIC, 1, 1);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testNegativeIntInput() returns error? {
    string s = "test integer -273";
    Lexer lexer = new(s);
    Token token = check lexer.nextLexicalToken(); // test
    token = check lexer.nextLexicalToken(); // integer
    token = check lexer.nextLexicalToken();
    Token expectedToken = getExpectedToken(-273, T_NUMERIC, 1, 14);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testPeek() returns error? {
    string s = "test integer -273";
    Lexer lexer = new(s);
    Token token = check lexer.peek(3); // test
    Token expectedToken = getExpectedToken("integer", T_WORD, 1, 6);
    test:assertEquals(token, expectedToken);

    token = check lexer.peek(5); // test
    expectedToken = getExpectedToken(-273, T_NUMERIC, 1, 14);
    test:assertEquals(token, expectedToken);

    token = check lexer.peek(2); // test
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 1, 5);
    test:assertEquals(token, expectedToken);

    token = check lexer.next(); // test
    expectedToken = getExpectedToken("test", T_WORD, 1, 1);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testPeekLexical() returns error? {
    string s = "test integer -273";
    Lexer lexer = new(s);
    Token token = check lexer.peekLexical(); // test
    Token expectedToken = getExpectedToken("test", T_WORD, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.peekLexical(); // test
    expectedToken = getExpectedToken("test", T_WORD, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.nextLexicalToken(); // test
    expectedToken = getExpectedToken("test", T_WORD, 1, 1);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testBooleanInput() returns error? {
    string s = "test false";
    Lexer lexer = new(s);
    Token token = check lexer.next();
    Token expectedToken = getExpectedToken("test", T_WORD, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.next(); // Space
    token = check lexer.next();
    expectedToken = getExpectedToken(false, T_BOOLEAN, 1, 6);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testStringInputWithLexicalTokenRetrieval() returns error? {
    string s = "test \"This is a test string\"";
    Lexer lexer = new(s);
    Token token = check lexer.nextLexicalToken();
    Token expectedToken = getExpectedToken("test", T_WORD, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.nextLexicalToken();
    expectedToken = getExpectedToken("This is a test string", T_STRING, 1, 6);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
function testStringWithQuote() returns error? {
    string s = getTextWithQuoteFile();
    Lexer lexer = new(s);
    Token token = check lexer.nextLexicalToken();
    Token expectedToken = getExpectedToken("test", T_WORD, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.nextLexicalToken();
    expectedToken = getExpectedToken("This is a \\\"test\\\" string",T_STRING, 1, 6);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
function testUnterminatedString() returns error? {
    string s = getTextWithUnterminatedStringFile();
    Lexer lexer = new(s);
    Token token = check lexer.nextLexicalToken();
    Token expectedToken = getExpectedToken("test", T_WORD, 1, 1);
    test:assertEquals(token, expectedToken);

    var result = lexer.nextLexicalToken();
    test:assertTrue(result is UnterminatedStringError);
    UnterminatedStringError err = <UnterminatedStringError>result;
    string expectedMessage = "Syntax Error: Unterminated string.";
    string message = err.message();
    test:assertEquals(message, expectedMessage);
    checkErrorRecord(err, 1, 6);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testLexicalTokenRetrieval() returns error? {
    string document = "\n\n\nquery getData {\n    picture(h: 128, w: 128)\n}";
    Lexer lexer = new(document);

    Token token = check lexer.nextLexicalToken();
    Token expectedToken = getExpectedToken("query", T_WORD, 4, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.nextLexicalToken();
    expectedToken = getExpectedToken("getData", T_WORD, 4, 7);
    test:assertEquals(token, expectedToken);

    token = check lexer.nextLexicalToken();
    expectedToken = getExpectedToken("{", T_OPEN_BRACE, 4, 15);
    test:assertEquals(token, expectedToken);

    token = check lexer.nextLexicalToken();
    expectedToken = getExpectedToken("picture", T_WORD, 5, 5);
    test:assertEquals(token, expectedToken);

    token = check lexer.nextLexicalToken();
    expectedToken = getExpectedToken("(", T_OPEN_PARENTHESES, 5, 12);
    test:assertEquals(token, expectedToken);

    token = check lexer.nextLexicalToken();
    expectedToken = getExpectedToken("h", T_WORD, 5, 13);
    test:assertEquals(token, expectedToken);

    token = check lexer.nextLexicalToken();
    expectedToken = getExpectedToken(":", T_COLON, 5, 14);
    test:assertEquals(token, expectedToken);

    token = check lexer.nextLexicalToken();
    expectedToken = getExpectedToken(128, T_NUMERIC, 5, 16);
    test:assertEquals(token, expectedToken);

    token = check lexer.nextLexicalToken();
    expectedToken = getExpectedToken(",", T_COMMA, 5, 19);
    test:assertEquals(token, expectedToken);
}

isolated function getExpectedToken(Scalar value, TokenType 'type, int line, int column) returns Token {
    return {
        value: value,
        'type: 'type,
        location: {
            line: line,
            column: column
        }
    };
}
