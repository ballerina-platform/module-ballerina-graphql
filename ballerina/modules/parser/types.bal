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

public type Scalar int|float|decimal|string|boolean;

type CharIteratorNode record {
    string:Char value;
};

type CharIterator object {
    public isolated function next() returns CharIteratorNode?;
};

type Boolean TRUE|FALSE;

type SeparatorType T_EOF|T_WHITE_SPACE|T_COMMA|T_NEW_LINE;
type SpecialCharacterType T_OPEN_BRACE|T_CLOSE_BRACE|T_OPEN_PARENTHESES|T_CLOSE_PARENTHESES|T_COLON|T_COMMENT|T_DOLLAR|
                          T_EQUAL|T_EXCLAMATION|T_OPEN_BRACKET|T_CLOSE_BRACKET|T_AT;

type Separator WhiteSpace|LineTerminator|COMMA;
type SpecialCharacter EXCLAMATION|DOLLAR|OPEN_PARENTHESES|CLOSE_PARENTHESES|ELLIPSIS|COLON|EQUAL|AT|OPEN_BRACKET|
                      CLOSE_BRACKET|OPEN_BRACE|PIPE|CLOSE_BRACE|DOUBLE_QUOTE;

type TokenType SeparatorType|SpecialCharacterType|T_IDENTIFIER|T_STRING|T_INT|T_FLOAT|T_BOOLEAN|T_COMMENT|T_ELLIPSIS;

type LexicalType T_EOF|T_OPEN_BRACE|T_CLOSE_BRACE|T_OPEN_PARENTHESES|T_CLOSE_PARENTHESES|T_COLON|T_IDENTIFIER|T_STRING|
                 T_INT|T_FLOAT|T_BOOLEAN|T_ELLIPSIS|T_EQUAL|T_DOLLAR|T_EXCLAMATION|T_OPEN_BRACKET|T_CLOSE_BRACKET|T_AT;

type IgnoreType T_NEW_LINE|T_WHITE_SPACE|T_COMMENT|T_COMMA;

public type ArgumentType T_INT|T_FLOAT|T_BOOLEAN|T_STRING|T_IDENTIFIER|T_INPUT_OBJECT;

public type Selection FieldNode|FragmentNode;

# Represents the types of operations valid in Ballerina GraphQL.
public enum RootOperationType {
    OPERATION_QUERY = "query",
    OPERATION_MUTATION = "mutation",
    OPERATION_SUBSCRIPTION = "subscription"
}

public enum DirectiveLocation {
    //executable directive locations
    QUERY,
    MUTATION,
    SUBSCRIPTION,
    FIELD,
    FRAGMENT_DEFINITION,
    FRAGMENT_SPREAD,
    INLINE_FRAGMENT
}
