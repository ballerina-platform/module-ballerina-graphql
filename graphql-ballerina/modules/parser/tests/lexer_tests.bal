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
    Token token = check lexer.read();

    Token expectedToken = getExpectedToken("John", T_IDENTIFIER, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 1, 5);
    test:assertEquals(token, expectedToken);

    var next = lexer.read();
    test:assertTrue(next is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>next;
    string message = err.message();
    string expectedMessage = "Syntax Error: Cannot parse the unexpected character \"<\".";
    test:assertEquals(message, expectedMessage);
    int line = err.detail()["line"];
    int column = err.detail()["column"];
    test:assertEquals(line, 1);
    test:assertEquals(column, 7);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testIntInput() returns error? {
    string s = "42";
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken(42, T_INT, 1, 1);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testFloatInput() returns error? {
    string s = "3.14159";
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken(3.14159, T_FLOAT, 1, 1);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testNegativeInput() returns error? {
    string s = "-3.14159";
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken(-3.14159, T_FLOAT, 1, 1);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testPeek() returns error? {
    string s = "test integer -273";
    Lexer lexer = new(s);

    Token token = check lexer.peek();
    Token expectedToken = getExpectedToken("test", T_IDENTIFIER, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.peek(3);
    expectedToken = getExpectedToken("integer", T_IDENTIFIER, 1, 6);
    test:assertEquals(token, expectedToken);

    token = check lexer.peek(5);
    expectedToken = getExpectedToken(-273, T_INT, 1, 14);
    test:assertEquals(token, expectedToken);

    token = check lexer.peek(2);
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 1, 5);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("test", T_IDENTIFIER, 1, 1);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testBooleanInput() returns error? {
    string s = "test false";
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken("test", T_IDENTIFIER, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.read(); // Space
    token = check lexer.read();
    expectedToken = getExpectedToken(false, T_BOOLEAN, 1, 6);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testStringInStringInput() returns error? {
    string s = "test \"This is a test string\"";
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken("test", T_IDENTIFIER, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.read(); // Space
    token = check lexer.read();
    expectedToken = getExpectedToken("This is a test string", T_STRING, 1, 6);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testStringWithDoubleQuotes() returns error? {
    string s = string`test "This is a \"test\" string" inside a string`;
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken("test", T_IDENTIFIER, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.read(); // Space
    token = check lexer.read();
    expectedToken = getExpectedToken(string`This is a \"test\" string`, T_STRING, 1, 6);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testUnterminatedString() returns error? {
    string s = string
    `test "This is a \"test\" string
in multiple lines`;
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken("test", T_IDENTIFIER, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.read(); // Space
    var result = lexer.read();
    test:assertTrue(result is UnterminatedStringError);
    UnterminatedStringError err = <UnterminatedStringError>result;
    string expectedMessage = "Syntax Error: Unterminated string.";
    string message = err.message();
    int line = err.detail()["line"];
    int column = err.detail()["column"];
    test:assertEquals(line, 1);
    test:assertEquals(column, 32);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
isolated function testComplexString() returns error? {
    string document = "\n\n\nquery getData {\n    picture(h: 128,,, w: 248)\n}";
    Lexer lexer = new(document);

    Token token = check lexer.read();
    Token expectedToken = getExpectedToken("\n", T_NEW_LINE, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("\n", T_NEW_LINE, 2, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("\n", T_NEW_LINE, 3, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("query", T_IDENTIFIER, 4, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.read(); // Space
    token = check lexer.read();
    expectedToken = getExpectedToken("getData", T_IDENTIFIER, 4, 7);
    test:assertEquals(token, expectedToken);

    token = check lexer.read(); // Space
    token = check lexer.read();
    expectedToken = getExpectedToken("{", T_OPEN_BRACE, 4, 15);
    test:assertEquals(token, expectedToken);

    token = check lexer.read(); // New Line
    token = check lexer.read(); // Space
    token = check lexer.read(); // Space
    token = check lexer.read(); // Space
    token = check lexer.read(); // Space
    token = check lexer.read();
    expectedToken = getExpectedToken("picture", T_IDENTIFIER, 5, 5);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("(", T_OPEN_PARENTHESES, 5, 12);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("h", T_IDENTIFIER, 5, 13);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(":", T_COLON, 5, 14);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 5, 15);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(128, T_INT, 5, 16);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(",", T_COMMA, 5, 19);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(",", T_COMMA, 5, 20);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(",", T_COMMA, 5, 21);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    token = check lexer.read();
    token = check lexer.read();
    token = check lexer.read();
    token = check lexer.read();
    token = check lexer.read();
    token = check lexer.read();
    token = check lexer.read();
    token = check lexer.read();
    expectedToken = getExpectedToken("", T_EOF, 6, 2);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["fragments", "lexer"]
}
isolated function readFragmentToken() returns error? {
    string s = "...friends { name }";
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken("...", T_ELLIPSIS, 1, 1);
    test:assertEquals(token, expectedToken);
}

isolated function getExpectedToken(Scalar value, TokenType kind, int line, int column) returns Token {
    return {
        value: value,
        kind: kind,
        location: {
            line: line,
            column: column
        }
    };
}
