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
    private Token[] buffer;
    private Location currentLocation;

    public isolated function init(string document) {
        self.charReader = new (document);
        self.document = document;
        self.buffer = [];
        self.currentLocation = {
            line: 1,
            column: 1
        };
    }

    isolated function peek(int into = 0) returns Token|SyntaxError {
        if self.buffer.length() > into {
            return self.buffer[into];
        }
        int startIndex = self.buffer.length();
        foreach int i in startIndex ... into {
            Token token = check self.readNextToken();
            self.buffer.push(token);
        }
        return self.buffer[into];
    }

    isolated function read() returns Token|SyntaxError {
        if self.buffer.length() > 0 {
            return self.buffer.shift();
        }
        return self.readNextToken();
    }

    isolated function readNextToken() returns Token|SyntaxError {
        string? char = self.charReader.peek();
        if char == () {
            return {
                kind: T_EOF,
                value: "",
                location: self.currentLocation.clone()
            };
        } else if char == DOUBLE_QUOTE {
            return self.readStringLiteral();
        } else if char == DASH || char is Digit {
            return self.readNumericLiteral(char);
        } else if char is Separator || char is SpecialCharacter {
            return self.readSpecialCharacterToken(char);
        } else if char == HASH {
            return self.readCommentToken();
        } else if char == DOT {
            return self.readEllipsisToken();
        } else {
            return self.readIdentifierToken(char);
        }
    }

    isolated function readSeparatorToken(string char) returns Token? {
        Location location = self.currentLocation.clone();
        _ = self.readNextChar();
        TokenType kind = getTokenType(char);
        return getToken(char, kind, location);
    }

    isolated function readSpecialCharacterToken(string char) returns Token {
        Location location = self.currentLocation.clone();
        _ = self.readNextChar();
        TokenType kind = getTokenType(char);
        return getToken(char, kind, location);
    }

    isolated function readStringLiteral() returns Token|SyntaxError {
        if self.isTripleQuotedString() {
            return self.readBlockStringLiteral();
        } else {
            return self.readSingleLineStringLiteral();
        }
    }

    isolated function readSingleLineStringLiteral() returns Token|SyntaxError {
        string word = "";
        Location location = self.currentLocation.clone();
        _ = self.readNextChar(); // Consume first double quote character

        string? char = self.charReader.peek();
        boolean isEscaped = false;
        while char is string {
            if char is LineTerminator {
                break;
            } else if char == DOUBLE_QUOTE && !isEscaped {
                _ = self.readNextChar(); // Consume last double quote character
                return getToken(word, T_STRING, location);
            } else if char == BACK_SLASH {
                isEscaped = !isEscaped;
            } else {
                isEscaped = false;
            }
            word += char;
            _ = self.readNextChar();
            char = self.charReader.peek();
        }
        string message = "Syntax Error: Unterminated string.";
        return error UnterminatedStringError(message, line = self.currentLocation.line,
                                             column = self.currentLocation.column);
    }

    isolated function readBlockStringLiteral() returns Token|SyntaxError {
        Location location = self.currentLocation.clone();
        string[] lines = [];
        string line = "";
        self.consumeIgnoreChars(3); // Consume first three double quote characters

        string? currentChar = self.charReader.peek();
        boolean isEscaped = false;

        while currentChar != () {
            if currentChar == DOUBLE_QUOTE && !isEscaped {
                if self.isTripleQuotedString() {
                    self.consumeIgnoreChars(3); // Consume last three double quote characters
                    lines.push(line);
                    break;
                }
                line += currentChar;
                isEscaped = false;
            } else if currentChar is LineTerminator {
                lines.push(line);
                line = "";
            } else if currentChar == BACK_SLASH {
                isEscaped = !isEscaped;
            } else {
                line += currentChar;
                isEscaped = false;
            }
            _ = self.readNextChar();
            currentChar = self.charReader.peek();
        }

        if currentChar == () {
            string message = "Syntax Error: Unterminated string.";
            return error UnterminatedStringError(message, line = self.currentLocation.line,
                                                 column = self.currentLocation.column);
        }
        return getToken(self.getBlockStringValue(lines), T_STRING, location);
    }

    isolated function isTripleQuotedString() returns boolean {
        return self.charReader.peek(1) == DOUBLE_QUOTE && self.charReader.peek(2) == DOUBLE_QUOTE;
    }

    isolated function consumeIgnoreChars(int count) {
        foreach int i in 0 ..< count {
            _ = self.readNextChar();
        }
    }

    isolated function getBlockStringValue(string[] lines) returns string {
        int? commonIndent = ();
        string formatted = "";
        foreach string line in lines {
            int indent = self.getLeadingWhiteSpaceCount(line);
            if indent < line.length() && (commonIndent == () || indent < commonIndent) {
                commonIndent = indent;
            }
        }
        if commonIndent is int {
            foreach int i in 0 ..< lines.length() {
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

    isolated function readNumericLiteral(string firstChar) returns Token|SyntaxError {
        Location location = self.currentLocation.clone();
        string numeral = firstChar; // Passing first char to handle negative numbers.
        _ = self.readNextChar(); // Consume first char
        string? character = self.charReader.peek();
        while character != () {
            if character is Digit {
                numeral += character;
            } else if character == DOT || character is Exp {
                return self.readFloatLiteral(numeral, character, location);
            } else if character is Separator || character is SpecialCharacter {
                break;
            } else {
                string message = string `Syntax Error: Invalid number, expected digit but got: "${character}".`;
                return error InvalidTokenError(message, line = self.currentLocation.line,
                                                column = self.currentLocation.column);
            }
            _ = self.readNextChar();
            character = self.charReader.peek();
        }
        int number = check getInt(numeral, location);
        return getToken(number, T_INT, location);
    }

    isolated function readFloatLiteral(string initialNumber, string separator, Location location)
    returns Token|SyntaxError {
        _ = self.readNextChar(); // Consume the separator character
        boolean isExpExpected = separator == DOT;
        boolean isDashExpected = !isExpExpected;
        boolean isDigitExpected = true;

        string numeral = initialNumber + separator;
        string? value = self.charReader.peek();
        while value != () {
            if value is Digit {
                numeral += value;
                isDashExpected = false;
                isDigitExpected = false;
            } else if value is Exp && isExpExpected && !isDigitExpected {
                numeral += value;
                isExpExpected = false;
                isDashExpected = true;
                isDigitExpected = true;
            } else if value == DASH && isDashExpected {
                numeral += value;
                isDashExpected = false;
                isDigitExpected = true;
            } else if (value is Separator || value is SpecialCharacter) && !isDigitExpected {
                return getToken(check getFloat(numeral, location), T_FLOAT, location);
            } else {
                string message = string `Syntax Error: Invalid number, expected digit but got: "${value}".`;
                return error InvalidTokenError(message, line = self.currentLocation.line,
                                               column = self.currentLocation.column);
            }
            _ = self.readNextChar();
            value = self.charReader.peek();
        }
        return getToken(check getFloat(numeral, location), T_FLOAT, location);
    }

    isolated function readCommentToken() returns Token|SyntaxError {
        Location location = self.currentLocation.clone();
        _ = self.readNextChar(); // Ignore first hash character
        string? character = self.charReader.peek();
        string word = "#";
        while character != () {
            if character is LineTerminator {
                break;
            } else {
                word += character;
            }
            _ = self.readNextChar();
            character = self.charReader.peek();
        }
        return getToken(word, T_COMMENT, location);
    }

    isolated function readEllipsisToken() returns Token|SyntaxError {
        Location location = self.currentLocation.clone();
        string ellipsis = "";
        int i = 0;
        while i < 3 {
            i += 1;
            string? c = self.readNextChar();
            if c is DOT {
                ellipsis += c;
                continue;
            } else if c == () {
                string message = string `Syntax Error: Cannot parse the unexpected character "${EOF}".`;
                return error InvalidTokenError(message, line = self.currentLocation.line,
                                               column = self.currentLocation.column);
            } else { // TODO: We don't need this else block. Added due to https://github.com/ballerina-platform/ballerina-lang/issues/39914
                string message = string `Syntax Error: Cannot parse the unexpected character "${c}".`;
                return error InvalidTokenError(message, line = self.currentLocation.line,
                                               column = self.currentLocation.column);
            }
        }
        return getToken(ELLIPSIS, T_ELLIPSIS, location);
    }

    isolated function readIdentifierToken(string firstChar) returns Token|SyntaxError {
        Location location = self.currentLocation.clone();
        _ = self.readNextChar();
        check validateFirstChar(firstChar, self.currentLocation);
        string word = firstChar;
        string? char = self.charReader.peek();
        while char != () {
            if char is SpecialCharacter {
                break;
            } else if char is Separator {
                break;
            } else {
                Location charLocation = self.currentLocation.clone();
                _ = self.readNextChar();
                check validateChar(char, charLocation);
                word += char;
            }
            char = self.charReader.peek();
        }
        TokenType kind = getWordTokenType(word);
        Scalar value = word;
        if kind is T_BOOLEAN {
            boolean|error booleanValue = 'boolean:fromString(word);
            if booleanValue is boolean {
                value = booleanValue;
            } else {
                panic booleanValue;
            }
        }
        return {
            value: value,
            kind: kind,
            location: location
        };
    }

    isolated function updateLocation(string? char) {
        if char is LineTerminator {
            self.currentLocation.line += 1;
            self.currentLocation.column = 1;
        } else {
            self.currentLocation.column += 1;
        }
    }

    isolated function readNextChar() returns string? {
        string? char = self.charReader.read();
        self.updateLocation(char);
        return char;
    }
}

isolated function getTokenType(string? value) returns TokenType {
    match value {
        () => {
            return T_EOF;
        }
        OPEN_BRACE => {
            return T_OPEN_BRACE;
        }
        CLOSE_BRACE => {
            return T_CLOSE_BRACE;
        }
        OPEN_PARENTHESES => {
            return T_OPEN_PARENTHESES;
        }
        CLOSE_PARENTHESES => {
            return T_CLOSE_PARENTHESES;
        }
        DOLLAR => {
            return T_DOLLAR;
        }
        EQUAL => {
            return T_EQUAL;
        }
        COLON => {
            return T_COLON;
        }
        COMMA => {
            return T_COMMA;
        }
        SPACE|TAB => {
            return T_WHITE_SPACE;
        }
        NEW_LINE|LINE_RETURN => {
            return T_NEW_LINE;
        }
        DOUBLE_QUOTE => {
            return T_STRING;
        }
        ZERO|ONE|TWO|THREE|FOUR|FIVE|SIX|SEVEN|EIGHT|NINE => {
            return T_INT;
        }
        HASH => {
            return T_COMMENT;
        }
        EXCLAMATION => {
            return T_EXCLAMATION;
        }
        OPEN_BRACKET => {
            return T_OPEN_BRACKET;
        }
        CLOSE_BRACKET => {
            return T_CLOSE_BRACKET;
        }
        AT => {
            return T_AT;
        }
        _ => {
            return T_IDENTIFIER;
        }
    }
}

isolated function getToken(Scalar value, TokenType kind, Location location) returns Token {
    return {
        kind,
        value,
        location
    };
}

isolated function getWordTokenType(string value) returns TokenType {
    if value is Boolean {
        return T_BOOLEAN;
    }
    return T_IDENTIFIER;
}

isolated function getInt(string value, Location location) returns int|InternalError {
    int|error number = 'int:fromString(value);
    if number is error {
        return getInternalError(value, "Int", location);
    }
    return number;
}

isolated function getFloat(string value, Location location) returns float|InternalError {
    float|error number = 'float:fromString(value);
    if number is error {
        return getInternalError(value, "Float", location);
    }
    return number;
}

isolated function validateChar(string char, Location location) returns InvalidTokenError? {
    if !isValidChar(char) {
        string message = string `Syntax Error: Cannot parse the unexpected character "${char}".`;
        return error InvalidTokenError(message, line = location.line, column = location.column);
    }
}

isolated function validateFirstChar(string char, Location location) returns InvalidTokenError? {
    if !isValidFirstChar(char) {
        string message = string `Syntax Error: Cannot parse the unexpected character "${char}".`;
        return error InvalidTokenError(message, line = location.line, column = location.column);
    }
}

isolated function getInternalError(string value, string kind, Location location) returns InternalError {
    string message = string `Internal Error: Failed to convert the "${value}" to "${kind}".`;
    return error InternalError(message, line = location.line, column = location.column);
}
