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
        string word = "";
        Location location = self.currentLocation.clone();
        _ = self.readNextChar(); // Ignore first double quote character
        string value = self.charReader.peek();
        if value == DOUBLE_QUOTE {
            value = self.readNextChar();
            value = self.charReader.peek();
            if value == DOUBLE_QUOTE {
                word = self.readBlockStringLiteral();
                return getToken(word, T_STRING, location);
            } else {
                return getToken(word, T_STRING, location);
            }
        } else {
            return self.readSingleLineStringLiteral(location);
        }
    }

    isolated function readSingleLineStringLiteral(Location location) returns Token|SyntaxError {
        string previousChar = "";
        string value = "";
        string word = "";
        while true {
            value = self.charReader.peek();
            if value is LineTerminator {
                string message = "Syntax Error: Unterminated string.";
                return error UnterminatedStringError(message, line = self.currentLocation.line,
                                                     column = self.currentLocation.column);
            } else {
                value = self.readNextChar();
                if value == DOUBLE_QUOTE && previousChar != BACK_SLASH {
                    break;
                } else {
                    word += value;
                }
                previousChar = value;
            }
        }
        return getToken(word, T_STRING, location);
    }

    isolated function readBlockStringLiteral() returns string {
        string word = "";
        string[] lines = [];
        _ = self.readNextChar(); // Ignore third double quote character
        while true {
            string value = self.charReader.peek();
            if value == NEW_LINE {
                lines.push(word);
                word = "";
                value = self.readNextChar();
            } else if value == DOUBLE_QUOTE {
                string previousChar = self.readNextChar();
                value = self.charReader.peek();
                if value == DOUBLE_QUOTE {
                    previousChar += self.readNextChar();
                    value = self.charReader.peek();
                    if value == DOUBLE_QUOTE {
                        previousChar += self.readNextChar();
                        if word.endsWith(BACK_SLASH) {
                            word = word.substring(0, word.length()-1); //Remove back slash
                        } else {
                            lines.push(word);
                            break;
                        }
                    }
                }
                word += previousChar;
            } else {
                value = self.readNextChar();
                word += value;
            }
        }
        return self.getBlockStringValue(lines);
    }

    isolated function getBlockStringValue(string[] lines) returns string {
        int? commonIndent = ();
        string formatted = "";
        foreach string line in lines {
            int indent  = self.getLeadingWhiteSpaceCount(line);
            if indent < line.length() && (commonIndent is () || indent < commonIndent) {
                commonIndent = indent;
            }
        }
        if commonIndent is int {
            foreach int i in 0..< lines.length() {
                if commonIndent > lines[i].length() {
                    continue;
                } else {
                    lines[i] = lines[i].substring(commonIndent, lines[i].length());
                }
            }
        }
        foreach string line in lines {
            formatted = string:'join("\n", formatted, line);
        }
        return formatted.trim();
    }

    isolated function getLeadingWhiteSpaceCount(string line) returns int {
        CharIterator iterator = line.iterator();
        CharIteratorNode? next = iterator.next();
        int i = 0;
        while next is CharIteratorNode {
            if next.value is WhiteSpace {
                i += 1;
                next = iterator.next();
            } else {
                break;
            }
        }
        return i;
    }

    isolated function readNumericLiteral(string fisrtChar) returns Token|SyntaxError {
        Location location = self.currentLocation.clone();
        string numeral = self.readNextChar();
        while (!self.charReader.isEof()) {
            string value = self.charReader.peek();
            if (value is Digit) {
                value = self.readNextChar();
                numeral += value.toString();
            } else if (value == DOT || value is Exp) {
                return self.readFloatLiteral(numeral, location);
            } else if (value is Separator || value is SpecialCharacter) {
                break;
            } else {
                string message = string`Syntax Error: Invalid number, expected digit but got: "${value}".`;
                return error InvalidTokenError(message, line = self.currentLocation.line,
                                               column = self.currentLocation.column);
            }
        }
        int number = check getInt(numeral, location);
        return getToken(number, T_INT, location);
    }

    isolated function readFloatLiteral(string initialString, Location location) returns Token|SyntaxError {
        string separator = self.readNextChar();
        boolean isExpExpected = separator == DOT;
        boolean isDashExpected = !isExpExpected;
        boolean isDigitExpected = true;

        string numeral = initialString + separator;
        while (!self.charReader.isEof()) {
            string value = self.charReader.peek();
            if (value is Digit) {
                value = self.readNextChar();
                numeral += value;
                isDashExpected = false;
                isDigitExpected = false;
            } else if (value is Exp && isExpExpected && !isDigitExpected) {
                value = self.readNextChar();
                numeral += value;
                isExpExpected = false;
                isDashExpected = true;
                isDigitExpected = true;
            } else if (value == DASH && isDashExpected) {
                value = self.readNextChar();
                numeral += value;
                isDashExpected = false;
                isDigitExpected = true;
            } else if ((value is Separator || value is SpecialCharacter) && !isDigitExpected) {
                break;
            } else {
                string message = string`Syntax Error: Invalid number, expected digit but got: "${value}".`;
                return error InvalidTokenError(message, line = self.currentLocation.line,
                                               column = self.currentLocation.column);
            }
        }
        float number = check getFloat(numeral, location);
        return getToken(number, T_FLOAT, location);
    }

    isolated function readCommentToken() returns Token|SyntaxError {
        Location location = self.currentLocation.clone();
        string word = self.readNextChar();
        while (!self.charReader.isEof()) {
            string char = self.charReader.peek();
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
        int i = 0;
        while i < 3 {
            string c = self.readNextChar();
            if (c != DOT) {
                string message = string`Syntax Error: Cannot parse the unexpected character "${DOT}".`;
                return error InvalidTokenError(message, line = self.currentLocation.line,
                                                               column = self.currentLocation.column);
            }
            i += 1;
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
    } else if (value == DOLLAR) {
        return T_DOLLAR;
    } else if (value == EQUAL) {
        return T_EQUAL;
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
    } else if value == EXCLAMATION {
        return T_EXCLAMATION;
    } else if value == OPEN_BRACKET {
        return T_OPEN_BRACKET;
    } else if value == CLOSE_BRACKET {
        return T_CLOSE_BRACKET;
    } else if value == AT {
        return T_AT;
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

isolated function getInt(string value, Location location) returns int|InternalError {
    var number = 'int:fromString(value);
    if (number is error) {
        return getInternalError(value, "Int", location);
    } else {
        return number;
    }
}

isolated function getFloat(string value, Location location) returns float|InternalError {
    var number = 'float:fromString(value);
    if (number is error) {
        return getInternalError(value, "Float", location);
    } else {
        return number;
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
