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
    NEGATIVE = "-"
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

type Terminal WhiteSpace|LineTerminator;
type Boolean TRUE|FALSE;

type TerminalCharacter T_EOF|T_WHITE_SPACE|T_COMMA|T_NEW_LINE;
type SpecialCharacter T_OPEN_BRACE|T_CLOSE_BRACE|T_OPEN_PARENTHESES|T_CLOSE_PARENTHESES|T_COLON|T_COMMENT;
type TokenType TerminalCharacter|SpecialCharacter|T_TEXT|T_STRING|T_INT|T_FLOAT|T_BOOLEAN|T_COMMENT;

type LexicalType T_EOF|T_OPEN_BRACE|T_CLOSE_BRACE|T_OPEN_PARENTHESES|T_CLOSE_PARENTHESES|T_COLON|T_TEXT|T_STRING|
                 T_INT|T_FLOAT|T_BOOLEAN;

type IgnoreType T_NEW_LINE|T_WHITE_SPACE|T_COMMENT|T_COMMA;

public type ArgumentType T_INT|T_FLOAT|T_BOOLEAN|T_STRING;

# Represents a character in a string.
#
# + value - The value of the character
# + location - The location of the character in the given document
public type Char record {|
    string value;
    Location location;
|};

type Token record {|
    TokenType kind;
    Scalar value;
    Location location;
|};

type CharIteratorNode record {
    string value;
};

type CharIterator object {
    public isolated function next() returns CharIteratorNode?;
};

# Stores a location for an error in a GraphQL operation.
#
# + line - The line of the document where error occured
# + column - The column of the document where error occurred
public type Location record {|
    int line;
    int column;
|};
