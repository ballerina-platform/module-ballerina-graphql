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

isolated function getUnexpectedTokenError(Token token) returns InvalidTokenError {
    Scalar value = token.value;
    string message = "Syntax Error: Unexpected " + getErrorMessageTypeNameForError(token);
    ErrorRecord errorRecord = getErrorRecordFromToken(token);
    return InvalidTokenError(message, errorRecord = errorRecord);
}

isolated function getExpectedNameError(Token token) returns InvalidTokenError {
    Scalar value = token.value;
    string message = "Syntax Error: Expected Name, found " + getErrorMessageTypeNameForError(token);
    ErrorRecord errorRecord = getErrorRecordFromToken(token);
    return InvalidTokenError(message, errorRecord = errorRecord);
}

isolated function getExpectedCharError(Token token, string char) returns InvalidTokenError {
    Scalar value = token.value;
    string message = "Syntax Error: Expected \"" + char + "\", found " + getErrorMessageTypeNameForError(token);
    ErrorRecord errorRecord = getErrorRecordFromToken(token);
    return InvalidTokenError(message, errorRecord = errorRecord);
}

isolated function getScalarTypeNameForError(Scalar value) returns string {
    if (value is int) {
        return "Int \"" + value.toString() + "\".";
    } else if (value is float) {
        return "Float \"" + value.toString() + "\".";
    } else if (value is boolean) {
        return "Boolean \"" + value.toString() + "\".";
    } else {
        return "Name \"" + value + "\".";
    }
}

isolated function getErrorMessageTypeNameForError(Token token) returns string {
    TokenType 'type = token.'type;
    if ('type == T_EOF) {
        return "<EOF>.";
    } else if ('type == T_TEXT) {
        return getScalarTypeNameForError(token.value);
    } else {
        return "\"" + token.value.toString() + "\".";
    }
}
