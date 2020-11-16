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
        check self.populateDocument();
        return self.document;
    }

    isolated function populateDocument() returns ParsingError? {
        Token token = check self.lexer.read();
        TokenType tokenType = token.kind;

        if (tokenType == T_OPEN_BRACE) {
            check self.parseOperation(token);
        } else if (tokenType == T_TEXT) {
            OperationType operationType = check getOperationType(token);
            token = check self.readNextNonSeparatorToken();
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
        while (token.kind != T_CLOSE_BRACE) {
            string operationName = <string>token.value;
            Location location = token.location.clone();
            token = check self.readNextNonSeparatorToken();
            TokenType tokenType = token.kind;
            if (tokenType == T_OPEN_BRACE) {
                OperationNode operation = check self.createOperationRecord(operationName, operationType, location);
                self.addOperationToDocument(operation);
                Token next = check self.peekNextNonSeparatorToken();
                if (next.kind != T_EOF) {
                    check self.populateDocument();
                }
            } else {
                return getExpectedCharError(token, OPEN_BRACE);
            }
            token = check self.readNextNonSeparatorToken();
        }
    }

    isolated function createOperationRecord(string operationName, OperationType kind, Location location)
    returns OperationNode|ParsingError {
        OperationNode operation = new(operationName, kind, location);
        check getFieldNode(self, operation);
        return operation;
    }

    isolated function addOperationToDocument(OperationNode operation) {
        self.document.addOperation(operation);
    }

    isolated function readNextNonSeparatorToken() returns Token|ParsingError {
        Token token = check self.lexer.read();
        if (token.kind is SeparatorType) {
            return self.readNextNonSeparatorToken();
        }
        return token;
    }

    isolated function peekNextNonSeparatorToken() returns Token|ParsingError {
        int i = 1;
        Token token = check self.lexer.peek(i);
        while (true) {
            if (token.kind is SeparatorType) {

            } else {
                break;
            }
            i += 1;
            token = check self.lexer.peek(i);
        }

        return token;
    }
}

isolated function getOperationType(Token token) returns OperationType|ParsingError {
    string value = <string>token.value;
    if (value is OperationType) {
        return value;
    }
    return getUnexpectedTokenError(token);
}

isolated function getFieldNode(Parser parser, ParentType parent) returns ParsingError? {
    Token token = check parser.readNextNonSeparatorToken();
    while (token.kind != T_CLOSE_BRACE) {
        string name = check getFieldName(token);
        Location location = token.location;
        FieldNode fieldNode = new (name, location);

        token = check parser.readNextNonSeparatorToken();

        if (token.kind != T_TEXT) {
            if (token.kind == T_OPEN_PARENTHESES) {
                check getArgumentNodeForField(parser, fieldNode);
                token = check parser.readNextNonSeparatorToken();
            }
            if (token.kind == T_OPEN_BRACE) {
                check getFieldNode(parser, fieldNode);
            }
        }

        parent.addSelection(fieldNode);

        if (token.kind == T_CLOSE_BRACE) {
            break;
        }
        token = check parser.readNextNonSeparatorToken();
    }
}

isolated function getArgumentNodeForField(Parser parser, FieldNode fieldNode) returns ParsingError? {
    Token token = check parser.readNextNonSeparatorToken();
    while (token.kind != T_CLOSE_PARENTHESES) {
        ArgumentName argumentName = check getArgumentName(token);

        token = check parser.readNextNonSeparatorToken();
        if (token.kind != T_COLON) {
            return getExpectedCharError(token, COLON);
        }

        token = check parser.readNextNonSeparatorToken();
        ArgumentValue argumentValue = check getArgumentValue(token);
        ArgumentNode argument = new(argumentName, argumentValue, <ArgumentType>token.kind);
        fieldNode.addArgument(argument);
        token = check parser.readNextNonSeparatorToken();
        if (token.kind == T_COMMA) {
            token = check parser.readNextNonSeparatorToken();
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
