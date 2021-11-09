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
    groups: ["lexer"]
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
    groups: ["numeral", "lexer"]
}
isolated function testIntInput() returns error? {
    string s = "42";
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken(42, T_INT, 1, 1);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testFloatInput() returns error? {
    string s = "3.14159";
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken(3.14159, T_FLOAT, 1, 1);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testNegativeInput() returns error? {
    string s = "-3.14159";
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken(-3.14159, T_FLOAT, 1, 1);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["numeral", "lexer"]
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
    groups: ["lexer"]
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
    groups: ["lexer"]
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
    groups: ["lexer"]
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
    groups: ["lexer"]
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
    test:assertEquals(message, expectedMessage);
    test:assertEquals(line, 1);
    test:assertEquals(column, 32);
}

@test:Config {
    groups: ["lexer"]
}
isolated function testStringWithVariableDefinition() returns error? {
    string s = string`getName($name : String = "walter")`;
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken("getName", T_IDENTIFIER, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("(", T_OPEN_PARENTHESES, 1, 8);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("$", T_DOLLAR, 1, 9);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("name", T_IDENTIFIER, 1, 10);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();// Space
    token = check lexer.read();
    expectedToken = getExpectedToken(":", T_COLON, 1, 15);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();// Space
    token = check lexer.read();
    expectedToken = getExpectedToken("String", T_IDENTIFIER, 1, 17);
    test:assertEquals(token, expectedToken);

    token = check lexer.read(); // Space
    token = check lexer.read();
    expectedToken = getExpectedToken("=", T_EQUAL, 1, 24);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();// Space
    token = check lexer.read();
    expectedToken = getExpectedToken("walter", T_STRING, 1, 26);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer"]
}
isolated function testBlockString() returns error? {
    string document = check getGraphQLDocumentFromFile("block_string.graphql");
    Lexer lexer = new(document);
    Token token = check lexer.read();

    Token expectedToken = getExpectedToken("{", T_OPEN_BRACE, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("\n", T_IDENTIFIER, 1, 2);

    token = check lexer.read(); // Space
    token = check lexer.read(); // Space
    token = check lexer.read(); // Space
    token = check lexer.read(); // Space
    token = check lexer.read();
    expectedToken = getExpectedToken("greet", T_IDENTIFIER, 2, 5);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("(", T_OPEN_PARENTHESES, 2, 10);
    test:assertEquals(token, expectedToken);

    token = check lexer.read(); // Space
    expectedToken = getExpectedToken("msg", T_IDENTIFIER, 2, 11);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(":", T_COLON, 2, 14);
    test:assertEquals(token, expectedToken);

    token = check lexer.read(); // Space
    token = check lexer.read();
    string expectedValue = "Hello,\n    World!,\n\n        This is\n    GraphQL\nBlock String";
    expectedToken = getExpectedToken(expectedValue, T_STRING, 2, 16);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["lexer"]
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
isolated function testReadFragmentToken() returns error? {
    string s = "...friends { name }";
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken("...", T_ELLIPSIS, 1, 1);
    test:assertEquals(token, expectedToken);
    token = check lexer.read();
    expectedToken = getExpectedToken("friends", T_IDENTIFIER, 1, 4);
}

@test:Config {
    groups: ["fragments", "lexer"]
}
isolated function testReadFragmentTokenWithSpace() returns error? {
    string s = "... friends { name }";
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken("...", T_ELLIPSIS, 1, 1);
    test:assertEquals(token, expectedToken);
    token = check lexer.read();
    expectedToken = getExpectedToken("friends", T_IDENTIFIER, 1, 5);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testReadFloatWithSimplePowerCharacter() returns error? {
    string s = "4e45";
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken(4e45, T_FLOAT, 1, 1);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testReadFloatWithDeciamlPoint() returns error? {
    string s = "4.2e45";
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken(4.2e45, T_FLOAT, 1, 1);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testReadFloatWithCapitalPowerCharacter() returns error? {
    string s = "4e45";
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken(4e45, T_FLOAT, 1, 1);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testReadInvalidFloatDotAferExp() returns error? {
    string s = "4e45.1";
    Lexer lexer = new(s);
    Token|SyntaxError result = lexer.read();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Invalid number, expected digit but got: ".".`;
    string message = err.message();
    int line = err.detail()["line"];
    int column = err.detail()["column"];
    test:assertEquals(message, expectedMessage);
    test:assertEquals(line, 1);
    test:assertEquals(column, 5);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testReadInvalidFloatDashInMiddle() returns error? {
    string s = "4e451-";
    Lexer lexer = new(s);
    Token|SyntaxError result = lexer.read();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Invalid number, expected digit but got: "-".`;
    string message = err.message();
    int line = err.detail()["line"];
    int column = err.detail()["column"];
    test:assertEquals(message, expectedMessage);
    test:assertEquals(line, 1);
    test:assertEquals(column, 6);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testReadInvalidFloatNoValueAfterExp() returns error? {
    string s = "4e)";
    Lexer lexer = new(s);
    Token|SyntaxError result = lexer.read();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Invalid number, expected digit but got: ")".`;
    string message = err.message();
    int line = err.detail()["line"];
    int column = err.detail()["column"];
    test:assertEquals(message, expectedMessage);
    test:assertEquals(line, 1);
    test:assertEquals(column, 3);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testReadInvalidFloatNoValueAfterExp2() returns error? {
    string s = "4.5e)";
    Lexer lexer = new(s);
    Token|SyntaxError result = lexer.read();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Invalid number, expected digit but got: ")".`;
    string message = err.message();
    int line = err.detail()["line"];
    int column = err.detail()["column"];
    test:assertEquals(message, expectedMessage);
    test:assertEquals(line, 1);
    test:assertEquals(column, 5);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testReadInvalidFloatRepeatedExp() returns error? {
    string s = "4e451e";
    Lexer lexer = new(s);
    Token|SyntaxError result = lexer.read();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Invalid number, expected digit but got: "e".`;
    string message = err.message();
    int line = err.detail()["line"];
    int column = err.detail()["column"];
    test:assertEquals(message, expectedMessage);
    test:assertEquals(line, 1);
    test:assertEquals(column, 6);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testReadInvalidFloatRepeatedDecimalPoint() returns error? {
    string s = "4.451.34";
    Lexer lexer = new(s);
    Token|SyntaxError result = lexer.read();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Invalid number, expected digit but got: ".".`;
    string message = err.message();
    int line = err.detail()["line"];
    int column = err.detail()["column"];
    test:assertEquals(message, expectedMessage);
    test:assertEquals(line, 1);
    test:assertEquals(column, 6);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testReadInvalidFloatMissingDigitAfterDecimalPoint() returns error? {
    string s = "4.e45";
    Lexer lexer = new(s);
    Token|SyntaxError result = lexer.read();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Invalid number, expected digit but got: "e".`;
    string message = err.message();
    int line = err.detail()["line"];
    int column = err.detail()["column"];
    test:assertEquals(message, expectedMessage);
    test:assertEquals(line, 1);
    test:assertEquals(column, 3);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testReadInvalidFloatDecimalPointAfterExp() returns error? {
    string s = "4.3e.45";
    Lexer lexer = new(s);
    Token|SyntaxError result = lexer.read();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Invalid number, expected digit but got: ".".`;
    string message = err.message();
    int line = err.detail()["line"];
    int column = err.detail()["column"];
    test:assertEquals(message, expectedMessage);
    test:assertEquals(line, 1);
    test:assertEquals(column, 5);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testReadInvalidFloatDecimalPointAsExp() returns error? {
    string s = "4.3e2.45";
    Lexer lexer = new(s);
    Token|SyntaxError result = lexer.read();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Invalid number, expected digit but got: ".".`;
    string message = err.message();
    int line = err.detail()["line"];
    int column = err.detail()["column"];
    test:assertEquals(message, expectedMessage);
    test:assertEquals(line, 1);
    test:assertEquals(column, 6);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testReadFloatNegativeExp() returns error? {
    string s = "4.451e-34";
    Lexer lexer = new(s);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken(4.451e-34, T_FLOAT, 1, 1);
    test:assertEquals(token, expectedToken);
}

@test:Config {
    groups: ["numeral", "lexer"]
}
isolated function testReadIntInvalidCharacter() returns error? {
    string s = "431v";
    Lexer lexer = new(s);
    Token|SyntaxError result = lexer.read();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Invalid number, expected digit but got: "v".`;
    string message = err.message();
    int line = err.detail()["line"];
    int column = err.detail()["column"];
    test:assertEquals(message, expectedMessage);
    test:assertEquals(line, 1);
    test:assertEquals(column, 4);
}

@test:Config {
    groups: ["lexer"]
}
isolated function testReadCommentToken() returns error? {
    string document = check getGraphQLDocumentFromFile("read_comment_token.graphql");
    Lexer lexer = new(document);
    Token token = check lexer.read();
    Token expectedToken = getExpectedToken("{", T_OPEN_BRACE, 1, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("\n", T_NEW_LINE, 1, 2);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 2, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 2, 2);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 2, 3);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 2, 4);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("name", T_IDENTIFIER, 2, 5);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 2, 9);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("# Get Name", T_COMMENT, 2, 10);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("\n", T_NEW_LINE, 2, 20);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 3, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 3, 2);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 3, 3);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 3, 4);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("# New Line", T_COMMENT, 3, 5);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("\n", T_NEW_LINE, 3, 15);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 4, 1);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 4, 2);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 4, 3);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(" ", T_WHITE_SPACE, 4, 4);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("address", T_IDENTIFIER, 4, 5);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken(",", T_COMMA, 4, 12);
    test:assertEquals(token, expectedToken);

    token = check lexer.read();
    expectedToken = getExpectedToken("age", T_IDENTIFIER, 4, 13);
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
