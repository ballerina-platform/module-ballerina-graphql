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
    private DocumentNode? document;
    private OperationNode? operation;

    public isolated function init(string text) returns ParsingError? {
        self.lexer = new(text);
        self.document = ();
        self.operation = ();
    }

    public isolated function parse() returns DocumentNode|ParsingError {
        check self.blockAnalysis();
        check self.populateDocument();
        return <DocumentNode>self.document;
    }

    public isolated function blockAnalysis() returns ParsingError? {
        int braceCount = 0;
        int parenthesesCount = 0;
        while (self.lexer.hasNext()) {
            Token token = check self.lexer.getNextSpecialCharaterToken();
            if (token.'type == T_EOF) {
                break;
            }
            TokenType tokenType = token.'type;
            if (tokenType == T_OPEN_BRACE) {
                braceCount += 1;
            } else if (tokenType == T_CLOSE_BRACE) {
                braceCount -= 1;
            } else if (tokenType == T_OPEN_PARENTHESES) {
                parenthesesCount += 1;
            } else if (tokenType == T_CLOSE_PARENTHESES) {
                parenthesesCount -= 1;
            }
            if (braceCount < 0 || parenthesesCount < 0) {
                return getUnexpectedTokenError(token);
            }
        }
        if (braceCount > 0 || parenthesesCount > 0) {
            Token token = check self.lexer.getNextSpecialCharaterToken();
            return getExpectedNameError(token);
        }
        self.lexer.reset();
    }

    isolated function populateDocument() returns ParsingError? {
        Token token = check self.lexer.nextLexicalToken();
        TokenType tokenType = token.'type;

        if (tokenType == T_OPEN_BRACE) {
            check self.parseOperation(token);
        } else if (tokenType == T_TEXT) {
            OperationType operationType = check getOperationType(token);
            token = check self.lexer.nextLexicalToken();
            tokenType = token.'type;
            if (tokenType == T_OPEN_BRACE) {
                check self.parseOperation(token, operationType);
            } else if (tokenType == T_TEXT) { // TODO: Handle multiple operations
                check self.parseOperationWithType(token, operationType);
            } else {
                return getUnexpectedTokenError(token);
            }
        } else {
            return getUnexpectedTokenError(token);
        }
    }

    isolated function parseOperation(Token token, OperationType 'type = QUERY) returns ParsingError? {
        Location location = token.location.clone();
        OperationNode operation = check self.createOperationRecord(ANONYMOUS_OPERATION, 'type, location);
        self.addOperationToDocument(operation);
    }

    isolated function parseOperationWithType(Token firstToken, OperationType operationType) returns ParsingError? {
        Token token = firstToken;
        while (token.'type != T_EOF) {
            string operationName = <string>token.value;
            Location location = token.location.clone();
            token = check self.lexer.nextLexicalToken();
            TokenType tokenType = token.'type;
            if (tokenType == T_OPEN_BRACE) {
                OperationNode operation = check self.createOperationRecord(operationName, operationType, location);
                self.addOperationToDocument(operation);
                Token next = check self.lexer.peekLexical();
                if (next.'type != T_EOF) {
                    check self.populateDocument();
                }
            } else {
                return getExpectedCharError(token, OPEN_BRACE);
            }
            token = check self.lexer.nextLexicalToken();
        }
    }

    isolated function createOperationRecord(string operationName, OperationType 'type, Location location)
    returns OperationNode|ParsingError {
        FieldNode 'field = check getFieldNode(self.lexer);

        return {
            name: operationName,
            'type: 'type,
            firstField: 'field,
            location: location
        };
    }

    isolated function addOperationToDocument(OperationNode operation) {
        OperationNode? operationNode = self.operation;
        if (operationNode is OperationNode) {
            operationNode.nextOperation = operation;
            self.operation = operation;
        } else {
            DocumentNode document = {
                firstOperation: operation
            };
            self.document = document;
            self.operation = operation;
        }
    }
}

isolated function getOperationType(Token token) returns OperationType|ParsingError {
    string value = <string>token.value;
    if (value is OperationType) {
        return value;
    }
    return getUnexpectedTokenError(token);
}

isolated function getFieldNode(Lexer lexer) returns FieldNode|ParsingError {
    Token token = check lexer.nextLexicalToken();
    FieldNode? 'field = ();
    FieldNode? firstField = ();
    while (token.'type != T_CLOSE_BRACE) {
        string name = check getFieldName(token);
        Location location = token.location;

        token = check lexer.nextLexicalToken();

        ArgumentNode? firstArgument = ();
        FieldNode? firstSelection = ();
        if (token.'type != T_TEXT) {
            if (token.'type == T_OPEN_PARENTHESES) {
                firstArgument = check getArgumentNodeForField(lexer);
                token = check lexer.nextLexicalToken();
            }
            if (token.'type == T_OPEN_BRACE) {
                firstSelection = check getFieldNode(lexer);
            }
        }

        FieldNode fieldNode = {
            name: name,
            location: location,
            firstArgument: firstArgument,
            firstSelection: firstSelection
        };

        if ('field is ()) {
            firstField = fieldNode;
            'field = fieldNode;
        } else {
            'field.nextField = fieldNode;
            'field = fieldNode;
        }

        if (token.'type == T_CLOSE_BRACE) {
            break;
        }
        token = check lexer.nextLexicalToken();
    }
    return <FieldNode>firstField;
}

isolated function getArgumentNodeForField(Lexer lexer) returns ArgumentNode|ParsingError {
    Token token = check lexer.nextLexicalToken();
    ArgumentNode? argument = ();
    ArgumentNode? firstArgument = ();
    while (token.'type != T_CLOSE_PARENTHESES) {
        ArgumentName argumentName = check getArgumentName(token);

        token = check lexer.nextLexicalToken();
        if (token.'type != T_COLON) {
            return getExpectedCharError(token, COLON);
        }

        token = check lexer.nextLexicalToken();
        ArgumentValue argumentValue = check getArgumentValue(token);

        if (argument is ()) {
            argument = getArgumentNode(argumentName, argumentValue, <ArgumentType>token.'type);
            firstArgument = argument;
        } else {
            ArgumentNode nextArgument = getArgumentNode(argumentName, argumentValue, <ArgumentType>token.'type);
            argument.nextArgument = nextArgument;
            argument = nextArgument;
        }
        token = check lexer.nextLexicalToken();
        if (token.'type == T_COMMA) {
            token = check lexer.nextLexicalToken();
            continue;
        }
    }
    return <ArgumentNode>firstArgument;
}

isolated function getArgumentName(Token token) returns ArgumentName|ParsingError {
    if (token.'type == T_TEXT) {
        return {
            value: <string>token.value,
            location: token.location
        };
    } else {
        return getExpectedNameError(token);
    }
}

isolated function getArgumentValue(Token token) returns ArgumentValue|ParsingError {
    if (token.'type is ArgumentType) {
        return {
            value: token.value,
            location: token.location
        };
    } else {
        return getUnexpectedTokenError(token);
    }
}

isolated function getArgumentNode(ArgumentName name, ArgumentValue value, ArgumentType 'type) returns ArgumentNode {
    return {
        name: name,
        value: value,
        'type: 'type
    };
}

isolated function getFieldName(Token token) returns string|ParsingError {
    if (token.'type == T_TEXT) {
        return <string>token.value;
    } else {
        return getExpectedNameError(token);
    }
}
