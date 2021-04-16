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

public class Lexer {
    private CharReader charReader;
    private string document;
    private boolean inProgress;
    private Token[] buffer;
    private Location currentLocation;

    public isolated function init(string document) {
        self.charReader = new(document);
        self.document = document;
        self.inProgress = true;
        self.buffer = [];
        self.currentLocation = {
            line: 1,
            column: 1
        };
    }

    public isolated function reset() {
        self.charReader = new(self.document);
        self.buffer = [];
    }

    public isolated function peek(int n = 1) returns Token|SyntaxError {
        int index = n - 1;
        int difference = n - self.buffer.length();
        int i = 0;
        while (i <= difference) {
            Token token = check self.readNextToken();
            self.pushToBuffer(token);
            i += 1;
        }
        return self.buffer[index];
    }

    public isolated function hasNext() returns boolean {
        if (self.buffer.length() > 0) {
            return true;
        }
        return self.inProgress;
    }

    public isolated function read() returns Token|SyntaxError {
        if (self.buffer.length() > 0) {
            return self.buffer.shift();
        }
        return self.readNextToken();
    }

    isolated function readNextToken() returns Token|SyntaxError {
        string char = self.charReader.peek();
        Location location = self.currentLocation.clone();
        if (char == EOF) {
            self.inProgress = false;
            return self.getTokenFromChar(char);
        } else if (char == DOUBLE_QUOTE) {
            return self.readStringLiteral();
        } else if (char == DASH || char is Digit) {
            return self.readNumericLiteral(char);
        } else if (char is Separator || char is SpecialCharacter) {
            return self.readSpecialCharacterToken();
        } else if (char == HASH) {
            return self.readCommentToken();
        } else if (char == DOT) {
            return self.readEllipsisToken();
        } else {
            return self.readIdentifierToken(char);
        }
    }

    isolated function readSeparatorToken() returns Token {
        Location location = self.currentLocation.clone();
        string char = self.readNextChar();
        TokenType kind = getTokenType(char);
        return getToken(char, kind, location);
    }

    isolated function readSpecialCharacterToken() returns Token {
        Location location = self.currentLocation.clone();
        string char = self.readNextChar();
        TokenType kind = getTokenType(char);
        return getToken(char, kind, location);
    }

    isolated function readStringLiteral() returns Token|SyntaxError {
        string previousChar = "";
        string word = "";
        Location location = self.currentLocation.clone();
        _ = self.readNextChar(); // Ignore first double quote character
        while (true) {
            string value = self.charReader.peek();
            if (value is LineTerminator) {
                string message = "Syntax Error: Unterminated string.";
                return error UnterminatedStringError(message, line = self.currentLocation.line,
                                                     column = self.currentLocation.column);
            } else if (value == DOUBLE_QUOTE && previousChar != BACK_SLASH) {
                value = self.readNextChar();
                break;
            } else {
                value = self.readNextChar();
                word += value;
            }
            previousChar = value;
        }
        return getToken(word, T_STRING, location);
    }

    isolated function readNumericLiteral(string fisrtChar) returns Token|SyntaxError {
        boolean isFloat = false;
        Location location = self.currentLocation.clone();
        string numeral = self.readNextChar();
        while (!self.charReader.isEof()) {
            string value = self.charReader.peek();
            if (value is Digit) {
                value = self.readNextChar();
                numeral += value.toString();
            } else if (value == DOT && !isFloat) {
                value = self.readNextChar();
                numeral += value;
                isFloat = true;
            } else if (value is Separator || value is SpecialCharacter) {
                break;
            } else {
                string message = string`Syntax Error: Invalid number, expected digit but got: "${value}".`;
                return error InvalidTokenError(message, line = self.currentLocation.line,
                                               column = self.currentLocation.column);
            }
        }
        int|float number = check getNumber(numeral, isFloat, location);
        TokenType kind = isFloat? T_FLOAT:T_INT;
        return getToken(number, kind, location);
    }

    isolated function readCommentToken() returns Token|SyntaxError {
        string word = HASH;
        Location location = self.currentLocation.clone();
        while (!self.charReader.isEof()) {
            string char = self.readNextChar();
            if (char is LineTerminator) {
                break;
            } else {
                char = self.readNextChar();
                word += char;
            }
        }
        return getToken(word, T_COMMENT, location);
    }

    isolated function readEllipsisToken() returns Token|SyntaxError {
        Location location = self.currentLocation.clone();
        foreach int i in 0...2 {
            string c = self.readNextChar();
            if (c != DOT) {
                string message = string`Syntax Error: Cannot parse the unexpected character "${DOT}".`;
                return error InvalidTokenError(message, line = self.currentLocation.line,
                                                               column = self.currentLocation.column);
            }
        }
        return getToken(ELLIPSIS, T_ELLIPSIS, location);
    }

    isolated function readIdentifierToken(string firstChar) returns Token|SyntaxError {
        check validateFirstChar(firstChar, self.currentLocation);
        Location location = self.currentLocation.clone();
        string word = self.readNextChar();
        while (!self.charReader.isEof()) {
            string char = self.charReader.peek();
            if (char is SpecialCharacter) {
                break;
            } else if (char is Separator) {
                break;
            } else {
                Location charLocation = self.currentLocation.clone();
                char = self.readNextChar();
                check validateChar(char, charLocation);
                word += char;
            }
        }
        TokenType kind = getWordTokenType(word);
        Scalar value = word;
        if (kind is T_BOOLEAN) {
            value = <boolean> checkpanic 'boolean:fromString(word);
        }
        return {
            value: value,
            kind: kind,
            location: location
        };
    }

    isolated function pushToBuffer(Token token) {
        self.buffer.push(token);
    }

    isolated function updateLocation(string char) {
        if (char is LineTerminator) {
            self.currentLocation.line += 1;
            self.currentLocation.column = 1;
        } else {
            self.currentLocation.column += 1;
        }
    }

    isolated function readNextChar() returns string {
         string char = self.charReader.read();
         self.updateLocation(char);
         return char;
    }

    isolated function getTokenFromChar(string value) returns Token {
        TokenType tokenType = getTokenType(value);
        return {
            kind: tokenType,
            value: value,
            location: self.currentLocation.clone()
        };
    }
}

isolated function getTokenType(string value) returns TokenType {
    if (value == OPEN_BRACE) {
        return T_OPEN_BRACE;
    } else if (value == CLOSE_BRACE) {
        return T_CLOSE_BRACE;
    } else if (value == OPEN_PARENTHESES) {
        return T_OPEN_PARENTHESES;
    } else if (value == CLOSE_PARENTHESES) {
        return T_CLOSE_PARENTHESES;
    } else if (value == COLON) {
        return T_COLON;
    } else if (value == COMMA) {
        return T_COMMA;
    } else if (value is WhiteSpace) {
        return T_WHITE_SPACE;
    } else if (value is EOF) {
        return T_EOF;
    } else if (value is LineTerminator) {
        return T_NEW_LINE;
    } else if (value == DOUBLE_QUOTE) {
        return T_STRING;
    } else if (value is Digit) {
        return T_INT;
    } else if (value == HASH) {
        return T_COMMENT;
    }
    return T_IDENTIFIER;
}

isolated function getToken(Scalar value, TokenType kind, Location location) returns Token {
    return {
        kind: kind,
        value: value,
        location: location
    };
}

isolated function getWordTokenType(string value) returns TokenType {
    if (value is Boolean) {
        return T_BOOLEAN;
    }
    return T_IDENTIFIER;
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

isolated function validateChar(string char, Location location) returns InvalidTokenError? {
    if (!isValidChar(char)) {
        string message = string`Syntax Error: Cannot parse the unexpected character "${char}".`;
        return error InvalidTokenError(message, line = location.line, column = location.column);
    }
}

isolated function validateFirstChar(string char, Location location) returns InvalidTokenError? {
    if (!isValidFirstChar(char)) {
        string message = string`Syntax Error: Cannot parse the unexpected character "${char}".`;
        return error InvalidTokenError(message, line = location.line, column = location.column);
    }
}

isolated function getInternalError(string value, string kind, Location location) returns InternalError {
    string message = string`Internal Error: Failed to convert the "${value}" to "${kind}".`;
    return error InternalError(message, line = location.line, column = location.column);
}
