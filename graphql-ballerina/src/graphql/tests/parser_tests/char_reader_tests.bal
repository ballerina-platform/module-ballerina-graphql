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
    groups: ["char_reader", "parser", "unit"]
}
isolated function testCharReaderForSimpleString() {
    string s = "Hello";
    CharReader reader = new(s);
    Char? c = reader.next();
    test:assertTrue(c is Char);
    Char expectedToken = {
        value: "H",
        location: {
            line: 1,
            column: 1
        }
    };
    test:assertEquals(c, expectedToken);

    c = reader.next();
    expectedToken = {
        value: "e",
        location: {
            line: 1,
            column: 2
        }
    };
    test:assertEquals(c, expectedToken);

    c = reader.next();
    expectedToken = {
        value: "l",
        location: {
            line: 1,
            column: 3
        }
    };
    test:assertEquals(c, expectedToken);

    c = reader.next();
    expectedToken = {
        value: "l",
        location: {
            line: 1,
            column: 4
        }
    };
    test:assertEquals(c, expectedToken);

    c = reader.next();
    expectedToken = {
        value: "o",
        location: {
            line: 1,
            column: 5
        }
    };
    test:assertEquals(c, expectedToken);

    c = reader.next();
    expectedToken = {
        value: "",
        location: {
            line: 1,
            column: 6
        }
    };
    test:assertEquals(c, expectedToken);
}

@test:Config {
    groups: ["char_reader", "parser", "unit"]
}
isolated function testCharReaderForEof() {
    string s = "";
    CharReader reader = new(s);
    Char? c = reader.next();
    test:assertTrue(c is Char);
    Char expectedToken = {
        value: EOF,
        location: {
            line: 1,
            column: 1
        }
    };
    test:assertEquals(c, expectedToken);
}

@test:Config {
    groups: ["char_reader", "parser", "unit"]
}
isolated function testCharReaderForAfterEof() {
    string s = "";
    CharReader reader = new(s);
    test:assertFalse(reader.isEof());
    Char? c = reader.next();
    test:assertTrue(reader.isEof());
}

@test:Config {
    groups: ["char_reader", "parser", "unit"]
}
isolated function testCharReaderForNewLine() {
    string s = "\n\n\n";
    CharReader reader = new(s);
    Char? c = reader.next();
    c = reader.next();
    c = reader.next();
    test:assertTrue(c is Char);
    Char expectedToken = {
        value: "\n",
        location: {
            line: 3,
            column: 1
        }
    };
    test:assertEquals(c, expectedToken);
}
