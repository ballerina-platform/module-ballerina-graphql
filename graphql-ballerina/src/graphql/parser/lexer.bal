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

class Lexer {
    private CharReader charReader;
    private Token? buffer;

    public isolated function init(string document) {
        self.charReader = new(document);
        self.buffer = ();
    }

    public isolated function getNext() returns Token|ParsingError? {
        if (self.buffer is Token) {
            Token token = <Token>self.buffer.clone();
            self.buffer = ();
            if (token.'type == T_COMMENT) {
                return self.getTokenSkippingComment(token.location);
            }
            return token;
        }
        return self.getNextToken();
    }

    isolated function getNextToken() returns Token|ParsingError? {
        CharToken? next = check self.charReader.getNext();
        while (next != ()) {
            CharToken char = <CharToken>next;
            string value = char.value;
            TokenType tokenType = getTokenType(char);
            if (tokenType == T_STRING) {
                return self.getStringToken(char.location);
            } else if (tokenType == T_NUMERIC) {
                return self.getNumeralToken(char.location, value);
            } else if (tokenType is TerminalCharacter) {
                return self.getTerminalToken(char, tokenType);
            } else if (tokenType == T_COMMENT) {
                return self.getTokenSkippingComment(char.location);
            } else if (tokenType is SpecialCharacter) {
                return self.getSpecialCharacterToken(char, tokenType);
            } else {
                return self.getWordToken(char.location, value);
            }
        }
    }

    isolated function getStringToken(Location location) returns Token|SyntaxError {
        string previousChar = "";
        string word = "";
        CharToken? next = check self.charReader.getNext();
        Token token = {
            'type: T_STRING,
            value: word,
            location: location.clone()
        };
        while (next != ()) {
            CharToken charToken = <CharToken>next;
            string value = charToken.value;
            if (value is Eof) {
                string message = "Syntax Error: Unexpected <EOF>.";
                ErrorRecord errorRecord = {
                    locations: [charToken.location.clone()]
                };
                return InvalidTokenError(message, errorRecord = errorRecord);
            }
            if (value is LineTerminator) {
                string message = "Syntax Error: Unterminated string.";
                ErrorRecord errorRecord = {
                    locations: [location.clone()]
                };
                return UnterminatedStringError(message, errorRecord = errorRecord);
            } else if (value is Quote && previousChar != BACK_SLASH) {
                token.value = word;
                break;
            } else {
                word += value;
            }
            previousChar = value;
            next = check self.charReader.getNext();
        }
        return token;
    }

    isolated function getNumeralToken(Location location, string fisrtChar) returns Token|ParsingError {
        string numeral = fisrtChar;
        boolean isFloat = false;
        CharToken? next = check self.charReader.getNext();
        while (next != ()) {
            CharToken token = <CharToken>next;
            TokenType tokenType = getTokenType(token);
            string value = token.value;
            if (tokenType is TerminalCharacter) {
                self.buffer = check self.getTerminalToken(token, tokenType);
                break;
            } else if (tokenType is SpecialCharacter) {
                self.buffer = self.getSpecialCharacterToken(token, tokenType);
            } else if (value == DECIMAL) {
                numeral += value;
                isFloat = true;
            } else if (value is Numeral) {
                numeral += value.toString();
            } else {
                string message = "Syntax Error: Invalid number, expected digit but got: \"" + value + "\".";
                ErrorRecord errorRecord = {
                    locations: [token.location.clone()]
                };
                return InvalidTokenError(message, errorRecord = errorRecord);
            }
            next = check self.charReader.getNext();
        }
        int|float number = check getNumber(numeral, isFloat, location);
        return {
            value: number,
            'type: T_NUMERIC,
            location: location
        };
    }

    isolated function getTokenSkippingComment(Location location) returns Token|ParsingError {
        CharToken? next = check self.charReader.getNext();
        Token terminalToken = {
            value: EOF,
            'type: T_EOF,
            location: location
        };
        while (next != ()) {
            CharToken token = <CharToken>next;
            TokenType tokenType = getTokenType(token);
            if (token.value is LineTerminator) {
                terminalToken = <Token>check self.getTerminalToken(token, tokenType);
                break;
            } else {
                next = check self.charReader.getNext();
                continue;
            }
        }
        return terminalToken;
    }

    isolated function getWordToken(Location location, string firstChar) returns Token|ParsingError {
        CharToken? next = check self.charReader.getNext();
        string word = firstChar;
        while (next != ()) {
            CharToken token = <CharToken>next;
            TokenType tokenType = getTokenType(token);
            if (tokenType is SpecialCharacter) {
                self.buffer = self.getSpecialCharacterToken(token, tokenType);
                break;
            } else if (tokenType is TerminalCharacter) {
                self.buffer = <Token>check self.getTerminalToken(token, tokenType);
                break;
            } else {
                // TODO: Validate char here
                word += token.value;
            }
            next = check self.charReader.getNext();
        }
        return {
            value: word,
            'type: T_WORD,
            location: location
        };
    }

    isolated function getTerminalToken(CharToken charToken, TokenType tokenType) returns Token|ParsingError? {
        return {
            'type: tokenType,
            value: TERMINAL,
            location: charToken.location
        };
    }

    isolated function getSpecialCharacterToken(CharToken charToken, TokenType tokenType) returns Token {
        return {
            'type: tokenType,
            value: charToken.value,
            location: charToken.location
        };
    }
}

isolated function getTokenType(CharToken token) returns TokenType {
    string value = token.value;
    if (value is OpenBrace) {
        return T_OPEN_BRACE;
    } else if (value is CloseBrace) {
        return T_CLOSE_BRACE;
    } else if (value is OpenParentheses) {
        return T_OPEN_PARENTHESES;
    } else if (value is CloseParentheses) {
        return T_CLOSE_PARENTHESES;
    } else if (value is Colon) {
        return T_COLON;
    } else if (value is Comma) {
        return T_COMMA;
    } else if (value is WhiteSpace) {
        return T_WHITE_SPACE;
    } else if (value is Eof) {
        return T_EOF;
    } else if (value is LineTerminator) {
        return T_NEW_LINE;
    } else if (value is Quote) {
        return T_STRING;
    } else if (value is Numeral) {
        return T_NUMERIC;
    } else if (value is Hash) {
        return T_COMMENT;
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

isolated function getInternalError(string value, string 'type, Location location) returns InternalError {
    string message = "Internal Error: Failed to convert the \"" + value + "\" to \"" + 'type + "\".";
    ErrorRecord errorRecord = {
        locations: [location]
    };
    return InternalError(message, errorRecord = errorRecord);
}
