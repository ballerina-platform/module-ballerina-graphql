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

// Special Characters
const QUOTE = "\"";
const BACK_SLASH = "\\";
const DECIMAL = ".";

const HASH = "#";

const COMMA = ",";

// Punctuators
const EXCLAMATION = "!";
const DOLLAR = "$";
const OPEN_PARENTHESES = "(";
const CLOSE_PARENTHESES = ")";
const TRIPLE_DOT = "...";
const COLON = ":";
const EQUAL = "=";
const AT = "@";
const OPEN_SQUARE_BRACKET = "[";
const CLOSE_SQUARE_BRACKET = "]";
const OPEN_BRACE = "{";
const PIPE = "|";
const CLOSE_BRACE = "}";


const TRUE = "true";
const FALSE = "false";

// Token Types
const T_EOF = 0;
const T_WORD = 1;
const T_STRING = 2;
const T_NUMERIC = 3;
const T_BOOLEAN = 4;
const T_COMMENT = 5;
const T_OPEN_BRACE = 6;
const T_CLOSE_BRACE = 7;
const T_OPEN_PARENTHESES = 8;
const T_CLOSE_PARENTHESES = 9;
const T_COLON = 10;
const T_COMMA = 11;
const T_NEW_LINE = 12;
const T_WHITE_SPACE = 13;

const VALID_CHAR_REGEX = "^[_0-9a-zA-Z]$";
const VALID_FIRST_CHAR_REGEX = "^[_a-zA-Z]$";
