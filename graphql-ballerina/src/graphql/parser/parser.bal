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

    public isolated function init(string text) returns ParsingError? {
        self.lexer = new(text);
    }

    public isolated function parse() returns Document|ParsingError? {
        return self.generateDocument();
    }

    isolated function generateDocument() returns Document|ParsingError? {
        Token token = check self.getNextNonWhiteSpaceToken();
        TokenType tokenType = token.'type;

        if (tokenType == T_OPEN_BRACE) {
            Operation operation = check self.createOperationRecord(ANONYMOUS_OPERATION, QUERY);
            map<Operation> operations = {operation};
            return {
                operations: operations
            };
        } else if (tokenType == T_WORD) {
            OperationType operationType = check getOperationType(token);
            token = check self.getNextNonWhiteSpaceToken();
            tokenType = token.'type;
            if (tokenType == T_OPEN_BRACE) {
                Operation operation = check self.createOperationRecord(ANONYMOUS_OPERATION, operationType);
                map<Operation> operations = {operation};
                return {
                    operations: operations
                };
            } else if (tokenType == T_WORD) {
                string operationName = <string>token.value;
                token = check self.getNextNonWhiteSpaceToken();
                tokenType = token.'type;
                if (tokenType == T_OPEN_BRACE) {
                    Operation operation = check self.createOperationRecord(operationName, operationType);
                    map<Operation> operations = {operation};
                    return {
                        operations: operations
                    };
                } else {
                    return getExpectedCharError(token, OPEN_BRACE);
                }
            }
        } else {
            return getUnexpectedTokenError(token);
        }
    }

    isolated function createOperationRecord(string operationName, OperationType 'type) returns Operation|ParsingError {
        Field[] fields = check self.getFieldsForOperation();
        return {
            name: operationName,
            'type: 'type,
            selections: fields
        };
    }

    isolated function getFieldsForOperation() returns Field[]|ParsingError {
        Token token = check self.getNextNonWhiteSpaceToken();
        Field[] fields = [];
        while (token.'type != T_CLOSE_BRACE) {
            Field 'field = {
                name: "",
                location: token.location.clone()
            };
            if (token.'type == T_WORD) {
                'field.name = <string>token.value;
            } else {
                return getExpectedNameError(token);
            }
            token = check self.getNextNonWhiteSpaceToken();
            if (token.'type == T_WORD) {
                fields.push('field);
                continue;
            } else if (token.'type == T_OPEN_PARENTHESES) {
                Argument[] arguments = check self.getArgumentsForField();
                token = check self.getNextNonWhiteSpaceToken();
            } else if (token.'type == T_OPEN_BRACE) {
                // Selections
            } else if (token.'type == T_CLOSE_BRACE) {
                fields.push('field);
                break;
            } else {
                return getExpectedNameError(token);
            }
        }
        return fields;
    }

    isolated function getNextNonWhiteSpaceToken() returns Token|ParsingError {
        Token? next = check self.lexer.getNext();
        Token? result = ();
        while (next != ()) {
            Token token = <Token>next;
            TokenType tokenType = token.'type;
            if (tokenType == T_WHITE_SPACE || tokenType == T_NEW_LINE) {
                // Do nothing
            } else {
                result = token;
                break;
            }
            next = check self.lexer.getNext();
        }
        return <Token>result;
    }

    isolated function getArgumentsForField() returns Argument[]|ParsingError {
        Argument[] arguments = [];
        Token token = check self.getNextNonWhiteSpaceToken();
        println(token);
        while (token.'type != T_CLOSE_PARENTHESES) {
            string argumentName = "";
            Scalar argumentValue = "";
            Location nameLocation = token.location;
            Location valueLocation = token.location;
            if (token.'type is T_WORD) {
                argumentName = <string>token.value;
            } else {
                return getExpectedNameError(token);
            }
            token = check self.getNextNonWhiteSpaceToken();
            println(token);
            if (token.'type != T_COLON) {
                return getExpectedCharError(token, COLON);
            }
            token = check self.getNextNonWhiteSpaceToken();
            println(token);
            if (token.'type is ArgumentValue) {
                argumentValue = token.value;
                valueLocation = token.location;
            } else {
                return getUnexpectedTokenError(token);
            }
            Argument argument = {
                name: argumentName,
                value: argumentValue,
                nameLocation: nameLocation,
                valueLocation: valueLocation
            };
            arguments.push(argument);
            token = check self.getNextNonWhiteSpaceToken();
            println(token);
            if (token.'type == T_COMMA) {
                token = check self.getNextNonWhiteSpaceToken();
                println(token);
                continue;
            }
        }
        return arguments;
    }
}



isolated function getBraceCount(TokenType tokenType, int braceCount) returns int {
    if (tokenType == T_OPEN_BRACE) {
        return braceCount + 1;
    } else if (tokenType == T_CLOSE_BRACE) {
        return braceCount - 1;
    }
    return braceCount;
}

isolated function getOperationType(Token token) returns OperationType|ParsingError {
    string value = <string>token.value;
    if (value is OperationType) {
        return value;
    }
    return getUnexpectedTokenError(token);
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
