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

class Lexer {
    private CharReader charReader;
    private string document;
    private boolean inProgress;
    private Token[] buffer;

    public isolated function init(string document) {
        self.charReader = new(document);
        self.document = document;
        self.inProgress = true;
        self.buffer = [];
    }

    public isolated function reset() {
        self.charReader = new(self.document);
        self.buffer = [];
    }

    isolated function peekLexical() returns Token|ParsingError {
        Token? token = ();
        int i = 1;
        while (true) {
            Token nextToken = check self.peek(i);
            if (nextToken.'type is LexicalType) {
                token = nextToken;
                break;
            }
            i += 1;
        }
        return <Token>token;
    }

    public isolated function peek(int n = 1) returns Token|ParsingError {
        int index = n - 1;
        if (self.buffer.length() < n) {
            int difference = n - self.buffer.length();
            int i = 0;
            while (i <= difference) {
                Token token = check self.readNextToken();
                self.pushToBuffer(token);
                i += 1;
            }
        }
        return self.buffer[index];
    }

    public isolated function hasNext() returns boolean {
        if (self.buffer.length() > 0) {
            return true;
        }
        return self.inProgress;
    }

    isolated function nextLexicalToken() returns Token|ParsingError {
        Token? token = ();
        while (true) {
            Token nextToken = check self.next();
            if (nextToken.'type is LexicalType) {
                token = nextToken;
                break;
            }
        }
        return <Token>token;
    }

    public isolated function next() returns Token|ParsingError {
        if (self.buffer.length() > 0) {
            return self.buffer.shift();
        }
        return self.readNextToken();
    }

    isolated function readNextToken() returns Token|ParsingError {
        Char char = self.charReader.next();
        TokenType tokenType = getTokenType(char);
        if (tokenType == T_EOF) {
            self.inProgress = false;
            return getTokenFromChar(char);
        } else if (tokenType == T_STRING) {
            return self.readStringToken(char.location);
        } else if (tokenType == T_INT) {
            return self.readNumeralToken(char.location, char.value);
        } else if (tokenType is TerminalCharacter) {
            return getTokenFromChar(char);
        } else if (tokenType == T_COMMENT) {
            return self.readCommentToken(char.location);
        } else if (tokenType is SpecialCharacter) {
            return getTokenFromChar(char);
        } else {
            return self.readWordToken(char);
        }
    }

    isolated function getNextSpecialCharaterToken() returns Token|ParsingError {
        Token token = check self.next();
        if (token.'type is SpecialCharacter) {
            return self.getNextSpecialCharaterToken();
        } else {
            return token;
        }
    }

    isolated function readStringToken(Location location) returns Token|SyntaxError {
        string previousChar = "";
        string word = "";
        while (!self.charReader.isEof()) {
            Char charToken = self.charReader.next();
            string value = charToken.value;
            if (value is EOF) {
                return getUnexpectedTokenError(getTokenFromChar(charToken));
            }
            if (value is LineTerminator) {
                string message = "Syntax Error: Unterminated string.";
                ErrorRecord errorRecord = {
                    locations: [location.clone()]
                };
                return UnterminatedStringError(message, errorRecord = errorRecord);
            } else if (value is QUOTE && previousChar != BACK_SLASH) {
                break;
            } else {
                word += value;
            }
            previousChar = value;
        }
        return getToken(word, T_STRING, location);
    }

    isolated function readNumeralToken(Location location, string fisrtChar) returns Token|ParsingError {
        string numeral = fisrtChar;
        boolean isFloat = false;
        while (!self.charReader.isEof()) {
            Char char = self.charReader.peek();
            TokenType tokenType = getTokenType(char);
            string value = char.value;
            if (tokenType is TerminalCharacter) {
                break;
            } else if (tokenType is SpecialCharacter) {
                break;
            } else if (value == DECIMAL) {
                char = self.charReader.next();
                numeral += value;
                isFloat = true;
            } else if (value is Numeral) {
                char = self.charReader.next();
                numeral += value.toString();
            } else {
                char = self.charReader.next();
                string message = "Syntax Error: Invalid number, expected digit but got: \"" + value + "\".";
                ErrorRecord errorRecord = {
                    locations: [char.location.clone()]
                };
                return InvalidTokenError(message, errorRecord = errorRecord);
            }
        }
        int|float number = check getNumber(numeral, isFloat, location);
        TokenType 'type = isFloat? T_FLOAT:T_INT;
        return getToken(number, 'type, location);
    }

    isolated function readCommentToken(Location location) returns Token|ParsingError {
        string word = HASH;
        while (!self.charReader.isEof()) {
            Char char = self.charReader.peek();
            TokenType tokenType = getTokenType(char);
            if (char.value is LineTerminator) {
                break;
            } else {
                char = self.charReader.next();
                word += char.value;
            }
        }
        return getToken(word, T_COMMENT, location);
    }

    isolated function readWordToken(Char firstChar) returns Token|ParsingError {
        check validateChar(firstChar);
        Location location = firstChar.location;
        string word = firstChar.value;
        while (!self.charReader.isEof()) {
            Char char = self.charReader.peek();
            TokenType tokenType = getTokenType(char);
            if (tokenType is SpecialCharacter) {
                break;
            } else if (tokenType is TerminalCharacter) {
                break;
            } else {
                char = self.charReader.next();
                check validateChar(char);
                word += char.value;
            }
        }
        TokenType 'type = getWordTokenType(word);
        Scalar value = word;
        if ('type is T_BOOLEAN) {
            value = <boolean>'boolean:fromString(word);
        }
        return {
            value: value,
            'type: 'type,
            location: location
        };
    }

    isolated function pushToBuffer(Token token) {
        self.buffer.push(token);
    }
}

isolated function getTokenType(Char char) returns TokenType {
    string value = char.value;
    if (value is OPEN_BRACE) {
        return T_OPEN_BRACE;
    } else if (value is CLOSE_BRACE) {
        return T_CLOSE_BRACE;
    } else if (value is OPEN_PARENTHESES) {
        return T_OPEN_PARENTHESES;
    } else if (value is CLOSE_PARENTHESES) {
        return T_CLOSE_PARENTHESES;
    } else if (value is COLON) {
        return T_COLON;
    } else if (value is COMMA) {
        return T_COMMA;
    } else if (value is WhiteSpace) {
        return T_WHITE_SPACE;
    } else if (value is EOF) {
        return T_EOF;
    } else if (value is LineTerminator) {
        return T_NEW_LINE;
    } else if (value is QUOTE) {
        return T_STRING;
    } else if (value is Numeral) {
        return T_INT;
    } else if (value is HASH) {
        return T_COMMENT;
    }
    return T_WORD;
}

isolated function getToken(Scalar value, TokenType 'type, Location location) returns Token {
    return {
        'type: 'type,
        value: value,
        location: location
    };
}

isolated function getTokenFromChar(Char charToken) returns Token {
    TokenType tokenType = getTokenType(charToken);
    return {
        'type: tokenType,
        value: charToken.value,
        location: charToken.location
    };
}

isolated function getWordTokenType(string value) returns TokenType {
    if (value is Boolean) {
        return T_BOOLEAN;
    }
    return T_WORD;
}

isolated function getNumber(string value, boolean isFloat, Location location) returns int|float|InternalError {
    if (isFloat) {
        var number = 'float:fromString(value);
        if (number is error) {
            return getInternalError(value, "float", location);
        } else {
            return number;
        }
    } else {
        var number = 'int:fromString(value);
        if (number is error) {
            return getInternalError(value, "int", location);
        } else {
            return number;
        }
    }
}

isolated function validateChar(Char char) returns InvalidTokenError? {
    if (!stringutils:matches(char.value, VALID_CHAR_REGEX)) {
        string message = "Syntax Error: Cannot parse the unexpected character \"" + char.value + "\".";
        ErrorRecord errorRecord = {
            locations: [char.location]
        };
        return InvalidTokenError(message, errorRecord = errorRecord);
    }
}

isolated function validateFirstChar(Char char) returns InvalidTokenError? {
    if (!stringutils:matches(char.value, VALID_FIRST_CHAR_REGEX)) {
        string message = "Syntax Error: Cannot parse the unexpected character \"" + char.value + "\".";
        ErrorRecord errorRecord = {
            locations: [char.location]
        };
        return InvalidTokenError(message, errorRecord = errorRecord);
    }
}

isolated function getInternalError(string value, string 'type, Location location) returns InternalError {
    string message = "Internal Error: Failed to convert the \"" + value + "\" to \"" + 'type + "\".";
    ErrorRecord errorRecord = {
        locations: [location]
    };
    return InternalError(message, errorRecord = errorRecord);
}
