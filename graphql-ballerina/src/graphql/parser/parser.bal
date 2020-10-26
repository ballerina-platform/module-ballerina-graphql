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

class Parser {
    private Lexer lexer;
    private Token[] tokens;

    public isolated function init(string text) {
        self.lexer = new(text);
        self.tokens = [];
    }

    public isolated function parse() returns Token[]|ParsingError {
        self.tokens = check removeWhiteSpaces(self.lexer);
        self.generateDocument();
        return self.tokens;
    }

    isolated function generateDocument() {

    }
}

isolated function removeWhiteSpaces(Lexer lexer) returns Token[]|ParsingError {
    Token[] tokens = [];
    boolean stripFront = true;

    Token? next = check lexer.getNext();
    while (next != ()) {
        Token token = <Token>next;
        TokenType tokenType = token.'type;
        if (tokenType == T_WHITE_SPACE) {
            // Do nothing
        } else if (stripFront && tokenType == T_NEW_LINE) {
            // Do nothing
        } else {
            stripFront = false;
            tokens.push(token);
        }
        next = check lexer.getNext();
    }
    return tokens;
}

//isolated function getNonTerminalTokensArray(Token[] tokens) returns Token[] {
//    Token[] nonTerminalTokens = [];
//    foreach Token token in tokens {
//        if !(token.'type is TerminalCharacter) {
//            nonTerminalTokens.push(token);
//        }
//    }
//    return nonTerminalTokens;
//}
//
//isolated function validateNonTerminalTokens(Token[] tokens) returns InvalidTokenError? {
//    Token firstToken = getNextTokenFromIterator(iterator);;
//    if (firstToken.'type is Word) {
//        check validateOperationType(firstToken);
//        //return validateGeneralNotation(iterator);
//    } else if (firstToken.'type == OPEN_BRACE) {
//        Operation operation = {
//            name: ANONYMOUS_OPERATION,
//            'type: QUERY,
//
//        };
//        Document document = {
//
//        };
//        return getShortHandNotationDocument(iterator);
//    } else {
//        string value = firstToken.value;
//        if (firstToken.'type is String) {
//            value = "\"";
//        }
//        string message = "Syntax Error: Unexpected \"" + firstToken.value + "\".";
//        ErrorRecord errorRecord = {
//            locations: [firstToken.location]
//        };
//        return InvalidTokenError(message, errorRecord = errorRecord);
//    }
//}
//
//isolated function getFields(TokenIterator iterator) {
//    Field[] fields = [];
//    while(true) {
//        TokenIteratorNode? next = iterator.next();
//        if (next is ()) {
//            break;
//        }
//        TokenIteratorNode nextNode = <TokenIteratorNode>next;
//        Token token = nextNode.value;
//        if (token.'type is Word) {
//            Field 'field = {
//                name: token.value
//            };
//            Argument[]|Token checkArguments = getArguments();
//            if (checkArguments is Token) {
//                token = arguments;
//                continue;
//            }
//            Argument[] arguments = <Argument[]>checkArguments;
//            'field.arguments = arguments;
//        }
//    }
//}
//
//
//// Returns the arguments if there's any, otherwise returns the token from the iterator.
//isolated function getArgumentsForField(TokenIterator iterator) returns Argument[]|Token {
//    Token token = getNextTokenFromIterator(iterator);
//    boolean getArguments = true;
//    if (token.'type == OPEN_PARENTHESES) {
//        Argument[] arguments = [];
//        while (getArguments) {
//            Argument argument = check getArgument(iterator);
//            arguments.push(argument);
//            token = getNextTokenFromIterator(iterator);
//            if (token.'type is Comma) {
//                continue;
//            } else if (token.'type == CLOSE_PARENTHESES) {
//                return arguments;
//            } else {
//                string message = "Syntax Error: Expected Name, found \"" + value + "\".";
//                ErrorRecord errorRecord = {
//                    locations: [token.location]
//                };
//                return InvalidTokenError(message, errorRecord = errorRecord);
//            }
//        }
//    } else {
//        return token;
//    }
//}
//
//isolated function getArgument(TokenIterator iterator) returns Argument|InvalidTokenError {
//    Token token = getNextTokenFromIterator(iterator);
//    string value = token.value;
//
//    if (token.'type is Word) {
//        string argumentValue = check getArgumentValue(iterator);
//        Argument argument = {
//            name: token.value,
//            value: argumentValue,
//            'type: INLINE
//        };
//        return argument;
//    } else {
//        string message = "Syntax Error: Expected Name, found \"" + value + "\".";
//        ErrorRecord errorRecord = {
//            locations: [token.location]
//        };
//        return InvalidTokenError(message, errorRecord = errorRecord);
//    }
//}
//
//isolated function getArgumentValue(TokenIterator iterator) returns string|InvalidTokenError {
//    TokenIteratorNode nextNode = <TokenIteratorNode>iterator.next();
//    Token token = nextNode.value;
//    string value = token.value;
//    if (value is Colon) {
//        nextNode = <TokenIteratorNode>iterator.next();
//        Token valueToken = nextNode.value;
//        if (valueToken.'type is Word || valueToken.'type is String) {
//            return valueToken.value;
//        } else {
//            string message = "Syntax Error: Unexpected \"" + valueToken.value + "\".";
//            ErrorRecord errorRecord = {
//                locations: [token.location]
//            };
//            return InvalidTokenError(message, errorRecord = errorRecord);
//        }
//    }
//    string message = "Syntax Error: Expected \":\", found \"" + value + "\".";
//    ErrorRecord errorRecord = {
//        locations: [token.location]
//    };
//    return InvalidTokenError(message, errorRecord = errorRecord);
//}
//
//isolated function validateOperationType(Token token) returns InvalidTokenError? {
//    string value = token.value;
//    if (value is OperationType) {
//        return;
//    }
//    string message = "Syntax Error: Unexpected name \"" + value + "\".";
//    ErrorRecord errorRecord = {
//        locations: [token.location]
//    };
//    return InvalidTokenError(message, errorRecord = errorRecord);
//}
//
//isolated function validateNonTerminalsForShorthandNotation() {
//    Operation operation = {
//        name: ANONYMOUS_OPERATION,
//        'type: QUERY
//    };
//    Field[] selection = [];
//    Field currentField = {
//        name: ""
//    };
//
//}
//
//isolated function getDocument(Token[] tokens) returns InvalidTokenError? {
//    check validateTokensLength(tokens);
//    Operation operation = check getOperation(tokens);
//    io:println(operation);
//}
//
//isolated function getOperation(Token[] tokens) returns Operation|InvalidTokenError {
//    Token firstToken = tokens[0];
//    OperationType operationType = QUERY;
//    string operationName = ANONYMOUS_OPERATION;
//    if (firstToken.'type is OPEN_BRACE) {
//        return {
//            name: operationName,
//            'type: operationType
//        };
//    } else if (firstToken.'type is Word) {
//        if (firstToken.value is OperationType) {
//            operationType = <OperationType>firstToken.value;
//        } else {
//            string message = "Syntax Error: Unexpected Name \"" + firstToken.value + "\".";
//            ErrorRecord errorRecord = {
//                locations: [firstToken.location]
//            };
//            return InvalidTokenError(message, errorRecord = errorRecord);
//        }
//    } else {
//        string message = "Syntax Error: Unexpected \"" + firstToken.value + "\".";
//        ErrorRecord errorRecord = {
//            locations: [firstToken.location]
//        };
//        return InvalidTokenError(message, errorRecord = errorRecord);
//    }
//    foreach Token token in tokens.slice(1, tokens.length()) {
//        if (token.'type is TerminalCharacter) {
//            continue;
//        } else if (token.'type is Word) {
//            operationName = token.value;
//            break;
//        } else if (token.'type == OPEN_BRACE) {
//            break;
//        } else {
//            string message = "Syntax Error: Unexpected \"" + token.value + "\".";
//            ErrorRecord errorRecord = {
//                locations: [token.location]
//            };
//            return InvalidTokenError(message, errorRecord = errorRecord);
//        }
//    }
//    return {
//        name: operationName,
//        'type: operationType
//    };
//}
//
//isolated function validateTokensLength(Token[] tokens) returns InvalidTokenError? {
//    if (tokens.length() == 1) {
//        string message = "Syntax Error: Unexpected <EOF>.";
//        ErrorRecord errorRecord = getErrorRecordFromToken({
//            value: tokens[0].value,
//            location: tokens[0].location
//        });
//        return InvalidTokenError(message, errorRecord = errorRecord);
//    }
//}
