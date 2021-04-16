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

import ballerina/jballerina.java;

isolated function getUnexpectedTokenError(Token token) returns InvalidTokenError {
    Scalar value = token.value;
    string message = string`Syntax Error: Unexpected ${getErrorMessageTypeNameForError(token)}.`;
    Location l = token.location;
    return error InvalidTokenError(message, line = l.line, column = l.column);
}

isolated function getExpectedNameError(Token token) returns InvalidTokenError {
    Scalar value = token.value;
    string message = string`Syntax Error: Expected Name, found ${getErrorMessageTypeNameForError(token)}.`;
    Location l = token.location;
    return error InvalidTokenError(message, line = l.line, column = l.column);
}

isolated function getExpectedCharError(Token token, string char) returns InvalidTokenError {
    Scalar value = token.value;
    string message = string`Syntax Error: Expected "${char}", found ${getErrorMessageTypeNameForError(token)}.`;
    Location l = token.location;
    return error InvalidTokenError(message, line = l.line, column = l.column);
}

isolated function getScalarTypeNameForError(Scalar value) returns string {
    string result = "";
    if (value is int) {
        result = "Int";
    } else if (value is float) {
        result = "Float";
    } else if (value is boolean) {
        result = "Boolean";
    } else {
        result = "Name";
    }

    // TODO: Remove toString after fixing https://github.com/ballerina-platform/ballerina-lang/issues/29674
    return string`${result} "${value.toString()}"`;
}

isolated function getErrorMessageTypeNameForError(Token token) returns string {
    TokenType kind = token.kind;
    if (kind == T_EOF) {
        return "<EOF>";
    } else if (kind == T_IDENTIFIER) {
        return getScalarTypeNameForError(token.value);
    } else if (kind == T_STRING) {
        // TODO: Same as above
        return string`String "${token.value.toString()}"`;
    } else {
        // TODO: Remove toString after fixing https://github.com/ballerina-platform/ballerina-lang/issues/29674
        return string`"${token.value.toString()}"`;
    }
}

isolated function isValidFirstChar(string char) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.parser.ParserUtils"
} external;

isolated function isValidChar(string char) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.parser.ParserUtils"
} external;
