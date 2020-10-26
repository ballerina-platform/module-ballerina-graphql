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
const SPACE = " ";
const TAB = "\t";

const NEW_LINE = "\n";
const LINE_RETURN = "\r";

const EOF = "<E>";
const TERMINAL = "<T>";

const QUOTE = "\"";
const BACK_SLASH = "\\";

const HASH = "#";

const OPEN_BRACE = "{";
const CLOSE_BRACE = "}";
const OPEN_PARENTHESES = "(";
const CLOSE_PARENTHESES = ")";

const COLON = ":";
const COMMA = ",";

// Token Types
const T_EOF = 0;
const T_WORD = 1;
const T_STRING = 2;
const T_NUMERIC = 3;
const T_COMMENT = 4;
const T_OPEN_BRACE = 5;
const T_CLOSE_BRACE = 6;
const T_OPEN_PARENTHESES = 7;
const T_CLOSE_PARENTHESES = 8;
const T_COLON = 9;
const T_COMMA = 10;
const T_NEW_LINE = 11;
const T_WHITE_SPACE = 12;
