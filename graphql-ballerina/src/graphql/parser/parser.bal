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

import ballerina/io;

isolated function parse(string documentString) returns Token[]|ParsingError {
    Token[] tokens = check getLexicalTokens(documentString);
    tokens = check removeComments(tokens);
    tokens = check serachStrings(tokens);
    tokens = removeWhiteSpaces(tokens);
    check getDocument(tokens);
    return tokens;
}

isolated function removeComments(Token[] tokens) returns Token[]|ParsingError {
    Token[] words = [];
    boolean isComment = false;
    foreach Token token in tokens {
        string value = token.value;
        if (value is Comment) {
            isComment = true;
        } else if (isComment && value is LineTerminator) {
            isComment = false;
            words.push(token);
        } else if (!isComment) {
            words.push(token);
        }
    }
    return words;
}

isolated function serachStrings(Token[] tokens) returns Token[]|ParsingError {
    Token[] words = [];
    string previousChar = "";
    string word = "";
    Location location = {
        line: 1,
        column: 1
    };
    boolean isString = false;
    foreach Token token in tokens {
        TokenType tokenType = token.'type;
        if (!isString && tokenType is Quote && previousChar != BACK_SLASH) {
            isString = true;
            location = token.location.clone();
            continue;
        }
        string value = token.value;
        if (isString) {
            if (value is LineTerminator) {
                string message = "Syntax Error: Unterminated string.";
                ErrorRecord errorRecord = {
                    locations: [token.location.clone()]
                };
                return UnterminatedStringError(message, errorRecord = errorRecord);
            }
            if (value is Quote && previousChar != BACK_SLASH) {
                Token stringToken = {
                    'type: WORD,
                    value: word,
                    location: location
                };
                words.push(stringToken);
                isString = false;
            } else {
                word += value;
            }
        } else {
            words.push(token);
        }
        previousChar = value;
    }
    return words;
}

isolated function removeWhiteSpaces(Token[] tokens) returns Token[] {
    Token[] result = [];
    boolean stripFront = true;
    foreach Token token in tokens {
        if (token.value is WhiteSpace) {
            continue;
        } else if (stripFront && token.value is LineTerminator) {
            continue;
        } else {
            result.push(token);
            stripFront = false;
        }
    }
    return result;
}

isolated function getDocument(Token[] tokens) returns InvalidTokenError? {
    check validateTokensLength(tokens);
    Operation operation = check getOperation(tokens);
    io:println(operation);
}

isolated function getOperation(Token[] tokens) returns Operation|InvalidTokenError {
    Token firstToken = tokens[0];
    OperationType operationType = QUERY;
    string operationName = ANONYMOUS_OPERATION;
    if (firstToken.'type is OPEN_BRACE) {
        return {
            name: operationName,
            'type: operationType
        };
    } else if (firstToken.'type is Word) {
        if (firstToken.value is OperationType) {
            operationType = <OperationType>firstToken.value;
        } else {
            string message = "Syntax Error: Unexpected Name \"" + firstToken.value + "\".";
            ErrorRecord errorRecord = {
                locations: [firstToken.location]
            };
            return InvalidTokenError(message, errorRecord = errorRecord);
        }
    } else {
        string message = "Syntax Error: Unexpected \"" + firstToken.value + "\".";
        ErrorRecord errorRecord = {
            locations: [firstToken.location]
        };
        return InvalidTokenError(message, errorRecord = errorRecord);
    }
    foreach Token token in tokens.slice(1, tokens.length()) {
        if (token.'type is TerminalCharacter) {
            continue;
        } else if (token.'type is Word) {
            operationName = token.value;
            break;
        } else if (token.'type == OPEN_BRACE) {
            break;
        } else {
            string message = "Syntax Error: Unexpected \"" + token.value + "\".";
            ErrorRecord errorRecord = {
                locations: [token.location]
            };
            return InvalidTokenError(message, errorRecord = errorRecord);
        }
    }
    return {
        name: operationName,
        'type: operationType
    };
}

isolated function validateTokensLength(Token[] tokens) returns InvalidTokenError? {
    if (tokens.length() == 1) {
        string message = "Syntax Error: Unexpected <EOF>.";
        ErrorRecord errorRecord = getErrorRecordFromToken({
            value: tokens[0].value,
            location: tokens[0].location
        });
        return InvalidTokenError(message, errorRecord = errorRecord);
    }
}
