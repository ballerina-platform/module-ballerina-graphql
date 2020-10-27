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

enum Numeral {
    ZERO = "0",
    ONE = "1",
    TWO = "2",
    THREE = "3",
    FOUR = "4",
    FIVE = "5",
    SIX = "6",
    SEVEN = "7",
    EIGHT = "8",
    NINE = "9",
    DECIMAL = ".",
    NEGATIVE = "-"
}

// Special Characters
// Terminal chars
type WhiteSpace SPACE|TAB;
type LineTerminator NEW_LINE|LINE_RETURN|EOF;
type Terminal WhiteSpace|LineTerminator;

// Separators
type Eof EOF;
type Quote QUOTE;
type Hash HASH;
type Colon COLON;
type Comma COMMA;
type OpenBrace OPEN_BRACE;
type CloseBrace CLOSE_BRACE;
type OpenParentheses OPEN_PARENTHESES;
type CloseParentheses CLOSE_PARENTHESES;

// Others
type BackSlash BACK_SLASH;
type Boolean TRUE|FALSE;

type TerminalCharacter T_EOF|T_WHITE_SPACE|T_NEW_LINE;
type SpecialCharacter T_OPEN_BRACE|T_CLOSE_BRACE|T_OPEN_PARENTHESES|T_CLOSE_PARENTHESES|T_COLON|T_COMMA|T_COMMENT;
type TokenType TerminalCharacter|SpecialCharacter|T_WORD|T_STRING|T_NUMERIC|T_BOOLEAN|T_COMMENT;

type ArgumentValue T_WORD|T_STRING|T_NUMERIC|T_BOOLEAN;

type CharToken record {|
    string value;
    Location location;
|};

type Token record {|
    TokenType 'type;
    Scalar value;
    Location location;
|};

# Stores a location for an error in a GraphQL operation.
#
# + line - The line of the document where error occured
# + column - The column of the document where error occurred
public type Location record {|
    int line;
    int column;
|};
