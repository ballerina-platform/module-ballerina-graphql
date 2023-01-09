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
    string message = string`Syntax Error: Unexpected ${getErrorMessageTypeNameForError(token)}.`;
    Location l = token.location;
    return error InvalidTokenError(message, line = l.line, column = l.column);
}

isolated function getExpectedNameError(Token token) returns InvalidTokenError {
    string message = string`Syntax Error: Expected Name, found ${getErrorMessageTypeNameForError(token)}.`;
    Location l = token.location;
    return error InvalidTokenError(message, line = l.line, column = l.column);
}

isolated function getExpectedCharError(Token token, string char) returns InvalidTokenError {
    string message = string`Syntax Error: Expected "${char}", found ${getErrorMessageTypeNameForError(token)}.`;
    Location l = token.location;
    return error InvalidTokenError(message, line = l.line, column = l.column);
}

isolated function getDuplicateFieldError(Token token) returns InvalidTokenError {
    Scalar value = token.value;
    string message = string`Syntax Error: Duplicate input object field "${value}", ` +
    string`found ${getErrorMessageTypeNameForError(token)}.`;
    Location l = token.location;
    return error InvalidTokenError(message, line = l.line, column = l.column);
}

isolated function getAnonymousOperationInMultipleOperationsError(OperationNode operationNode) returns ErrorDetail {
    string message = "This anonymous operation must be the only defined operation.";
    Location[] locations = [operationNode.getLocation()];
    return {message: message, locations: locations};
}

isolated function getScalarTypeNameForError(Scalar value) returns string {
    if value is int {
        return string `Int "${value}"`;
    }
    if value is float {
        return string `Float "${value}"`;
    }
    if value is boolean {
        return string `Boolean "${value}"`;
    }
    return string `Name "${value}"`;
}

isolated function getErrorMessageTypeNameForError(Token token) returns string {
    TokenType kind = token.kind;
    if kind == T_EOF {
        return "<EOF>";
    } else if kind == T_IDENTIFIER {
        return getScalarTypeNameForError(token.value);
    } else if kind == T_STRING {
        return string `String "${token.value}"`;
    }
    return string `"${token.value}"`;
}

isolated function isValidFirstChar(string char) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.parser.ParserUtils"
} external;

isolated function isValidChar(string char) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.parser.ParserUtils"
} external;

public isolated function getHashCode(object {} obj) returns string = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.parser.ParserUtils"
} external;
