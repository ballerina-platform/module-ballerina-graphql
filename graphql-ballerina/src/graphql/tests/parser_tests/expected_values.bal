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

CharToken[] expectedCharTokens = [
    {
        'type: OPEN_BRACE,
        value: "{",
        location: { line: 1, column: 1 }
    },
    {
        'type: SPACE,
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
        'type: SPACE,
        value: " ",
        location: { line: 1, column: 7 }
    },
    {
        'type: CLOSE_BRACE,
        value: "}",
        location: { line: 1, column: 8 }
    },
    {
        'type: EOF,
        value: EOF,
        location: { line: 1, column: 9 }
    }
];

Token[] expectedWordTokens = [
    {
        'type: OPEN_BRACE,
        value: "{",
        location: { line: 1, column: 1 }
    },
    {
        'type: SPACE,
        value: " ",
        location: { line: 1, column: 2 }
    },
    {
        'type: WORD,
        value: "name",
        location: { line: 1, column: 3 }
    },
    {
        'type: SPACE,
        value: " ",
        location: { line: 1, column: 7 }
    },
    {
        'type: CLOSE_BRACE,
        value: "}",
        location: { line: 1, column: 8 }
    },
    {
        'type: EOF,
        value: EOF,
        location: { line: 1, column: 9 }
    }
];
