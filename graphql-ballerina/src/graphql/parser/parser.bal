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

import ballerina/stringutils;

isolated function parse(string documentString) returns Document|ParsingError {
    Token[] tokens = check tokenize(documentString);
    if (tokens[0].value == "{") {
        Token openBraceToken = tokens.remove(0);
        Operation operation = check parseShortHandNotation(tokens);
        return {
            operations: [operation]
        };
    } else {
        Operation operation = check parseGeneralNotation(tokens);
        return {
            operations: [operation]
        };
    }
}

isolated function tokenize(string document) returns Token[]|ParsingError {
    string documentWithEof = document + " " + EOF;
    Token[] tokens = [];
    string[] lines = stringutils:split(documentWithEof, "\n");
    int lineNumber = 0;
    foreach string line in lines {
        lineNumber += 1;
        string trimmedLine = 'string:trim(line);
        if (!'string:startsWith(trimmedLine, COMMENT_BLOCK)) {
            check parseByColumns(line, lineNumber, tokens);
        }
    }
    return tokens;
}

isolated function parseByColumns(string line, int lineNumber, Token[] tokens) returns InvalidCharacterError? {
    string[] words = stringutils:split(line, "\\s+");
    foreach string word in words {
        if (word == "") {
            continue;
        }
        int columnNumber = <int>'string:indexOf(line, word) + 1;
        if (word == EOF) {
            columnNumber = columnNumber - 2;
        }
        Token token = {
            value: word,
            line: lineNumber,
            column: columnNumber
        };
        check validate(token);
        tokens.push(token);
    }
}

isolated function parseShortHandNotation(Token[] tokens) returns Operation|ParsingError {
    OperationType 'type = OPERATION_QUERY;
    return getOperationRecord('type, tokens);
}

isolated function parseGeneralNotation(Token[] tokens) returns Operation|ParsingError {
    OperationType operationType = check getOperationType(tokens);
    Token operationToken = tokens.remove(0);
    string operationName = operationToken.value;
    if (operationName == OPEN_BRACE) {
        return getOperationRecord(operationType, tokens);
    } else {
        Token openBraceToken = tokens.remove(0);
        string openBraceTokenValue = openBraceToken.value;
        if (openBraceTokenValue == OPEN_BRACE) {
            return getOperationRecord(operationType, tokens, operationName);
        } else {
            return getExpectedSyntaxError(openBraceToken, OPEN_BRACE, VALIDATION_TYPE_NAME);
        }
    }
}

isolated function getOperationRecord(OperationType 'type, Token[] tokens, string name = "") returns
Operation|ParsingError {
    Token[] fields = check getFields(tokens);
    if (name == "") {
        return {
            'type: 'type,
            fields: fields
        };
    } else {
        return {
            'type: 'type,
            fields: fields,
            name: name
        };
    }
}

isolated function getFields(Token[] tokens) returns Token[]|ParsingError {
    Token[] fields = [];
    int count = 0;
    foreach Token token in tokens {
        string value = token.value;
        if (value == OPEN_BRACE) {
            string message = "Ballerina GraphQL does not support multi-level queries yet.";
            return NotSupportedError(message);
        } else if (value == CLOSE_BRACE) {
            if (fields.length() == 0) {
                return getExpectedSyntaxError(token, VALIDATION_TYPE_NAME, CLOSE_BRACE);
            }
            return fields;
        } else {
            fields[count] = token;
            count += 1;
        }
    }
    string message = "Syntax Error: Expected Name, found <EOF>.";
    ErrorRecord errorRecord = getErrorRecordFromToken(fields[count - 1]);
    return InvalidTokenError(message, errorRecord = errorRecord);
}

isolated function getOperationType(Token[] tokens) returns OperationType|SyntaxError {
    Token token = tokens.remove(0);
    var operationType = token.value;
    if (operationType is OperationType) {
        return operationType;
    } else {
        return getUnexpectedSyntaxError(token, VALIDATION_TYPE_NAME);
    }
}

// TODO: Validate character by character
isolated function validate(Token token) returns InvalidCharacterError? {
    string word = token.value;
    if (word == OPEN_BRACE || word == CLOSE_BRACE || word == EOF) {
        return;
    }
    if (stringutils:matches(word, WORD_VALIDATOR)) {
        return;
    }
    string message = "Invalid token: " + word;
    ErrorRecord errorRecord = getErrorRecordFromToken(token);
    return InvalidCharacterError(message, errorRecord = errorRecord);
}
