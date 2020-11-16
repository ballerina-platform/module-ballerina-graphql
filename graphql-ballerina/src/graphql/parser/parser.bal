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
    private DocumentNode document;

    public isolated function init(string text) returns ParsingError? {
        self.lexer = new(text);
        self.document = new;
    }

    public isolated function parse() returns DocumentNode|ParsingError {
        check self.blockAnalysis();
        check self.populateDocument();
        return self.document;
    }

    public isolated function blockAnalysis() returns ParsingError? {
        int braceCount = 0;
        int parenthesesCount = 0;
        while (self.lexer.hasNext()) {
            Token token = check self.lexer.getNextSpecialCharaterToken();
            if (token.kind == T_EOF) {
                break;
            }
            TokenType tokenType = token.kind;
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
        Token token = check self.lexer.read();
        TokenType tokenType = token.kind;

        if (tokenType == T_OPEN_BRACE) {
            check self.parseOperation(token);
        } else if (tokenType == T_TEXT) {
            OperationType operationType = check getOperationType(token);
            token = check self.lexer.nextLexicalToken();
            tokenType = token.kind;
            if (tokenType == T_OPEN_BRACE) {
                check self.parseOperation(token, operationType);
            } else if (tokenType == T_TEXT) {
                check self.parseOperationWithType(token, operationType);
            } else {
                return getUnexpectedTokenError(token);
            }
        } else {
            return getUnexpectedTokenError(token);
        }
    }

    isolated function parseOperation(Token token, OperationType kind = QUERY) returns ParsingError? {
        Location location = token.location.clone();
        OperationNode operation = check self.createOperationRecord(ANONYMOUS_OPERATION, kind, location);
        self.addOperationToDocument(operation);
    }

    isolated function parseOperationWithType(Token firstToken, OperationType operationType) returns ParsingError? {
        Token token = firstToken;
        while (token.kind != T_EOF) {
            string operationName = <string>token.value;
            Location location = token.location.clone();
            token = check self.lexer.nextLexicalToken();
            TokenType tokenType = token.kind;
            if (tokenType == T_OPEN_BRACE) {
                OperationNode operation = check self.createOperationRecord(operationName, operationType, location);
                self.addOperationToDocument(operation);
                Token next = check self.lexer.peekLexical();
                if (next.kind != T_EOF) {
                    check self.populateDocument();
                }
            } else {
                return getExpectedCharError(token, OPEN_BRACE);
            }
            token = check self.lexer.nextLexicalToken();
        }
    }

    isolated function createOperationRecord(string operationName, OperationType kind, Location location)
    returns OperationNode|ParsingError {
        OperationNode operation = new(operationName, kind, location);
        check getFieldNode(self.lexer, operation);
        return operation;
    }

    isolated function addOperationToDocument(OperationNode operation) {
        self.document.addOperation(operation);
    }
}

isolated function getOperationType(Token token) returns OperationType|ParsingError {
    string value = <string>token.value;
    if (value is OperationType) {
        return value;
    }
    return getUnexpectedTokenError(token);
}

isolated function getFieldNode(Lexer lexer, ParentType parent) returns ParsingError? {
    Token token = check lexer.nextLexicalToken();
    while (token.kind != T_CLOSE_BRACE) {
        string name = check getFieldName(token);
        Location location = token.location;
        FieldNode fieldNode = new (name, location);

        token = check lexer.nextLexicalToken();

        if (token.kind != T_TEXT) {
            if (token.kind == T_OPEN_PARENTHESES) {
                check getArgumentNodeForField(lexer, fieldNode);
                token = check lexer.nextLexicalToken();
            }
            if (token.kind == T_OPEN_BRACE) {
                check getFieldNode(lexer, fieldNode);
            }
        }

        parent.addSelection(fieldNode);

        if (token.kind == T_CLOSE_BRACE) {
            break;
        }
        token = check lexer.nextLexicalToken();
    }
}

isolated function getArgumentNodeForField(Lexer lexer, FieldNode fieldNode) returns ParsingError? {
    Token token = check lexer.nextLexicalToken();
    while (token.kind != T_CLOSE_PARENTHESES) {
        ArgumentName argumentName = check getArgumentName(token);

        token = check lexer.nextLexicalToken();
        if (token.kind != T_COLON) {
            return getExpectedCharError(token, COLON);
        }

        token = check lexer.nextLexicalToken();
        ArgumentValue argumentValue = check getArgumentValue(token);
        ArgumentNode argument = new(argumentName, argumentValue, <ArgumentType>token.kind);
        fieldNode.addArgument(argument);
        token = check lexer.nextLexicalToken();
        if (token.kind == T_COMMA) {
            token = check lexer.nextLexicalToken();
            continue;
        }
    }
}

isolated function getArgumentName(Token token) returns ArgumentName|ParsingError {
    if (token.kind == T_TEXT) {
        return {
            value: <string>token.value,
            location: token.location
        };
    } else {
        return getExpectedNameError(token);
    }
}

isolated function getArgumentValue(Token token) returns ArgumentValue|ParsingError {
    if (token.kind is ArgumentType) {
        return {
            value: token.value,
            location: token.location
        };
    } else {
        return getUnexpectedTokenError(token);
    }
}

isolated function getFieldName(Token token) returns string|ParsingError {
    if (token.kind == T_TEXT) {
        return <string>token.value;
    } else {
        return getExpectedNameError(token);
    }
}
