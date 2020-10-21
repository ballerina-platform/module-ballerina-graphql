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
//import ballerina/time;
//import ballerina/io;

@test:Config {
    groups: ["lexer", "parser", "unit"]
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
    CharToken[] tokens = check tokenizeCharacters(document);
    CharToken[] expectedTokens = [
        {
            'type: CHAR,
            value: "{",
            location: { line: 1, column: 1 }
        },
        {
            'type: WHITE_SPACE,
            value: " ",
            location: { line: 1, column: 2 }
        },
        {
            'type: CHAR,
            value: "n",
            location: { line: 1, column: 3 }
        },
        {
            'type: CHAR,
            value: "a",
            location: { line: 1, column: 4 }
        },
        {
            'type: CHAR,
            value: "m",
            location: { line: 1, column: 5 }
        },
        {
            'type: CHAR,
            value: "e",
            location: { line: 1, column: 6 }
        },
        {
            'type: WHITE_SPACE,
            value: " ",
            location: { line: 1, column: 7 }
        },
        {
            'type: CHAR,
            value: "}",
            location: { line: 1, column: 8 }
        },
        {
            'type: EOF_TOKEN,
            value: "<EOF>",
            location: { line: 1, column: 9 }
        }
    ];
    // Caution: Might give type cast error ,when assert fails.
    test:assertEquals(tokens, expectedTokens);
}
