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
                location: self.currentLocation
            };
        }
        int tokenTag = -1;
        if (symbolTable.hasKey(char)) {
            tokenTag = symbolTable.get(char);
        }
        if char == DOUBLE_QUOTE {
            return self.readStringLiteral();
        } else if char == DASH || tokenTag == DIGIT_TAG {
            return self.readNumericLiteral(char);
        } else if (tokenTag >= WHITE_SPACE_TAG && tokenTag <= SPECIAL_CHARACTER_TAG) {
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
        Location location = self.currentLocation;
        _ = self.readNextChar();
        int kind = getTokenType(char);
        return getToken(char, kind, location);
    }

    isolated function readSpecialCharacterToken(string char) returns Token {
        Location location = self.currentLocation;
        _ = self.readNextChar();
        int kind = getTokenType(char);
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
        Location location = self.currentLocation;
        _ = self.readNextChar(); // Consume first double quote character

        string? char = self.charReader.peek();
        boolean isEscaped = false;
        int tokenTag = -1;
        while char != () {
            if (symbolTable.hasKey(char)) {
                tokenTag = symbolTable.get(char);
            } else {
                tokenTag = -1;
            }
            if tokenTag == LINE_TERMINATOR_TAG {
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
        Location location = self.currentLocation;
        string[] lines = [];
        string line = "";
        self.consumeIgnoreChars(3); // Consume first three double quote characters
        int tokenTag = -1;
        string? currentChar = self.charReader.peek();
        boolean isEscaped = false;

        while currentChar != () {
            if (symbolTable.hasKey(currentChar)) {
                tokenTag = symbolTable.get(currentChar);
            } else {
                tokenTag = -1;
            }
            if currentChar == DOUBLE_QUOTE && !isEscaped {
                if self.isTripleQuotedString() {
                    self.consumeIgnoreChars(3); // Cosume last three double quote characters
                    lines.push(line);
                    break;
                }
                line += currentChar;
                isEscaped = false;
            } else if tokenTag == LINE_TERMINATOR_TAG {
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
        int tokenTag = -1;

        while next is CharIteratorNode {
            string value = next.value;
            if (symbolTable.hasKey(value)) {
                tokenTag = symbolTable.get(value);
            } else {
                tokenTag = -1;
            }
            if tokenTag == WHITE_SPACE_TAG {
                i += 1;
                next = iterator.next();
            } else {
                break;
            }
        }
        return i;
    }

    isolated function readNumericLiteral(string firstChar) returns Token|SyntaxError {
        Location location = self.currentLocation;
        string numeral = firstChar; // Passing first char to handle negative numbers.
        _ = self.readNextChar(); // Consume first char
        string? character = self.charReader.peek();
        int tokenTag = -1;
        while character != () {
            if (symbolTable.hasKey(character)) {
                tokenTag = symbolTable.get(character);
            } else {
                tokenTag = -1;
            }
            if tokenTag == DIGIT_TAG {
                numeral += character;
            } else if character == DOT || tokenTag == EXP_TAG {
                return self.readFloatLiteral(numeral, character, location);
            } else if (tokenTag >= WHITE_SPACE_TAG && tokenTag <= SPECIAL_CHARACTER_TAG) {
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
        int tokenTag = -1;
        while value != () {
            if (symbolTable.hasKey(value)) {
                tokenTag = symbolTable.get(value);
            } else {
                tokenTag = -1;
            }
            if tokenTag == DIGIT_TAG {
                numeral += value;
                isDashExpected = false;
                isDigitExpected = false;
            } else if tokenTag == EXP_TAG && isExpExpected && !isDigitExpected {
                numeral += value;
                isExpExpected = false;
                isDashExpected = true;
                isDigitExpected = true;
            } else if value == DASH && isDashExpected {
                numeral += value;
                isDashExpected = false;
                isDigitExpected = true;
            } else if (tokenTag >= WHITE_SPACE_TAG && tokenTag <= SPECIAL_CHARACTER_TAG) && !isDigitExpected {
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
        Location location = self.currentLocation;
        _ = self.readNextChar(); // Ignore first hash character
        string? character = self.charReader.peek();
        string word = "#";
        int tokenTag = -1;
        while character != () {
            if (symbolTable.hasKey(character)) {
                tokenTag = symbolTable.get(character);
            } else {
                tokenTag = -1;
            }
            if tokenTag == LINE_TERMINATOR_TAG {
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
        Location location = self.currentLocation;
        string ellipsis = "";
        int i = 0;
        while i < 3 {
            i += 1;
            string? c = self.readNextChar();
            if c == DOT {
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
        Location location = self.currentLocation;
        _ = self.readNextChar();
        check validateFirstChar(firstChar, self.currentLocation);
        string word = firstChar;
        string? char = self.charReader.peek();
        int tokenTag = -1;
        while char != () {
            if (symbolTable.hasKey(char)) {
                tokenTag = symbolTable.get(char);
            } else {
                tokenTag = -1;
            }
            if tokenTag >= WHITE_SPACE_TAG && tokenTag <= SPECIAL_CHARACTER_TAG {
                break;
            } else {
                Location charLocation = self.currentLocation;
                _ = self.readNextChar();
                check validateChar(char, charLocation);
                word += char;
            }
            char = self.charReader.peek();
        }
        int kind = getWordTokenType(word);
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
        if (char == ()) {
            self.currentLocation.column += 1;
            return;
        }
        int tokenTag = -1;
        if (symbolTable.hasKey(char)) {
            tokenTag = symbolTable.get(char);
        }

        if tokenTag == LINE_TERMINATOR_TAG {
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

isolated function getTokenType(string? value) returns int {
    if value == () {
        return T_EOF;
    }
    int tokenTag = -1;
    if (symbolTable.hasKey(value)) {
        tokenTag = symbolTable.get(value);
    }
    if value == OPEN_BRACE {
        return T_OPEN_BRACE;
    } else if value == CLOSE_BRACE {
        return T_CLOSE_BRACE;
    } else if value == OPEN_PARENTHESES {
        return T_OPEN_PARENTHESES;
    } else if value == CLOSE_PARENTHESES {
        return T_CLOSE_PARENTHESES;
    } else if value == DOLLAR {
        return T_DOLLAR;
    } else if value == EQUAL {
        return T_EQUAL;
    } else if value == COLON {
        return T_COLON;
    } else if value == COMMA {
        return T_COMMA;
    } else if tokenTag == WHITE_SPACE_TAG {
        return T_WHITE_SPACE;
    } else if tokenTag == LINE_TERMINATOR_TAG {
        return T_NEW_LINE;
    } else if value == DOUBLE_QUOTE {
        return T_STRING;
    } else if tokenTag == DIGIT_TAG {
        return T_INT;
    } else if value == HASH {
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

isolated function getToken(Scalar value, int kind, Location location) returns Token {
    return {
        kind: kind,
        value: value,
        location: location
    };
}

isolated function getWordTokenType(string value) returns int {
    if value == "true" || value == "false" {
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
