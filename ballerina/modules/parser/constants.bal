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
const DOUBLE_QUOTE = "\"";
const BACK_SLASH = "\\";
const DOT = ".";
const DASH = "-";

const HASH = "#";

const COMMA = ",";

// Punctuators
const EXCLAMATION = "!";
const DOLLAR = "$";
const OPEN_PARENTHESES = "(";
const CLOSE_PARENTHESES = ")";
const ELLIPSIS = "...";
const COLON = ":";
const EQUAL = "=";
const AT = "@";
const OPEN_BRACKET = "[";
const CLOSE_BRACKET = "]";
const OPEN_BRACE = "{";
const PIPE = "|";
const CLOSE_BRACE = "}";
const FRAGMENT = "fragment";
const ON = "on";
public const NULL = "null";

enum Digit {
    ZERO = "0",
    ONE = "1",
    TWO = "2",
    THREE = "3",
    FOUR = "4",
    FIVE = "5",
    SIX = "6",
    SEVEN = "7",
    EIGHT = "8",
    NINE = "9"
}

enum Exp {
    EXP_SIMPLE = "e",
    EXP_CAPITAL = "E"
}

enum WhiteSpace {
    SPACE = " ",
    TAB = "\t"
}

enum LineTerminator {
    NEW_LINE = "\n",
    LINE_RETURN = "\r",
    EOF = ""
}

const TRUE = "true";
const FALSE = "false";

// Parser Types
const T_EOF = 0;
public const T_IDENTIFIER = 1;
public const T_STRING = 2;
public const T_INT = 3;
public const T_FLOAT = 4;
public const T_BOOLEAN = 5;
public const T_COMMENT = 6;
public const T_OPEN_BRACE = 7;
public const T_CLOSE_BRACE = 8;
public const T_OPEN_PARENTHESES = 9;
public const T_CLOSE_PARENTHESES = 10;
public const T_COLON = 11;
public const T_COMMA = 12;
public const T_NEW_LINE = 13;
public const T_WHITE_SPACE = 14;
public const T_ELLIPSIS = 15;
public const T_DOLLAR = 16;
public const T_EQUAL = 17;
public const T_EXCLAMATION = 18;
public const T_OPEN_BRACKET = 19;
public const T_CLOSE_BRACKET = 20;
public const T_AT = 21;
public const T_INPUT_OBJECT = 22;

public const ANONYMOUS_OPERATION = "<anonymous>";
