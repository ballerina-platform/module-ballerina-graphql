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
    groups: ["lexer", "parser", "unit"],
    enable: false
}
function testInvalidCharacter() {
    string name = "John Doe<";
    var result = tokenizeCharacters(name);
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    test:assertEquals(err.message(), "Syntax Error: Cannot parse the unexpected character \"<\".");
    checkErrorRecord(err, 1, 9);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
function testGetCharTokens() returns error? {
    string document = "{ name }";
    CharToken[] charTokens = check tokenizeCharacters(document);
    // Caution: Might give type cast error ,when assert fails.
    test:assertEquals(charTokens, expectedCharTokens);
}

@test:Config {
    groups: ["lexer", "parser", "unit"]
}
function testGetWordTokens() returns error? {
    Token[] tokens = check getWordTokens(expectedCharTokens);
    // Caution: Might give type cast error ,when assert fails.
    test:assertEquals(tokens, expectedWordTokens);
}
