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

    public isolated function parse() returns Document|ParsingError {
        check self.blockAnalysis();
        return self.generateDocument();
    }

    public isolated function blockAnalysis() returns ParsingError? {
        Token? next = check self.lexer.getNextSpecialCharaterToken();
        int braceCount = 0;
        int parenthesesCount = 0;
        while (next != ()) {
            Token token = <Token>next;
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
            next = check self.lexer.getNextSpecialCharaterToken();
        }
        if (braceCount > 0 || parenthesesCount > 0) {
            return getExpectedNameError(<Token>next);
        }
        self.lexer.reset();
    }

    isolated function generateDocument() returns Document|ParsingError {
        Token token = check self.lexer.getNextNonWhiteSpaceToken();
        TokenType tokenType = token.'type;

        if (tokenType == T_OPEN_BRACE) {
            Operation operation = check self.createOperationRecord(ANONYMOUS_OPERATION, QUERY);
            map<Operation> operations = {operation};
            return {
                operations: operations
            };
        } else if (tokenType == T_WORD) {
            OperationType operationType = check getOperationType(token);
            token = check self.lexer.getNextNonWhiteSpaceToken();
            tokenType = token.'type;
            if (tokenType == T_OPEN_BRACE) {
                Operation operation = check self.createOperationRecord(ANONYMOUS_OPERATION, operationType);
                map<Operation> operations = {operation};
                return {
                    operations: operations
                };
            } else if (tokenType == T_WORD) {
                string operationName = <string>token.value;
                token = check self.lexer.getNextNonWhiteSpaceToken();
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
            } else {
                return getUnexpectedTokenError(token);
            }
        } else {
            return getUnexpectedTokenError(token);
        }
    }

    isolated function createOperationRecord(string operationName, OperationType 'type) returns Operation|ParsingError {
        Field[] fields = check getFieldsForOperation(self.lexer);
        return {
            name: operationName,
            'type: 'type,
            fields: fields
        };
    }
}

isolated function getOperationType(Token token) returns OperationType|ParsingError {
    string value = <string>token.value;
    if (value is OperationType) {
        return value;
    }
    return getUnexpectedTokenError(token);
}

isolated function getFieldsForOperation(Lexer lexer) returns Field[]|ParsingError {
    Token token = check lexer.getNextNonWhiteSpaceToken();
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
        token = check lexer.getNextNonWhiteSpaceToken();
        if (token.'type == T_WORD) {
            fields.push('field);
            token = check lexer.getNextNonWhiteSpaceToken();
            continue;
        }

        if (token.'type == T_OPEN_PARENTHESES) {
            Argument[] arguments = check getArgumentsForField(lexer);
            'field.arguments = arguments;
            token = check lexer.getNextNonWhiteSpaceToken();
        }

        if (token.'type == T_OPEN_BRACE) {
            Field[] selections = check getFieldsForOperation(lexer);
            'field.selections = selections;
        }
        fields.push('field);
        if (token.'type == T_CLOSE_BRACE) {
            break;
        }
        token = check lexer.getNextNonWhiteSpaceToken();
    }
    return fields;
}

isolated function getArgumentsForField(Lexer lexer) returns Argument[]|ParsingError {
    Argument[] arguments = [];
    Token token = check lexer.getNextNonWhiteSpaceToken();
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
        token = check lexer.getNextNonWhiteSpaceToken();
        if (token.'type != T_COLON) {
            return getExpectedCharError(token, COLON);
        }
        token = check lexer.getNextNonWhiteSpaceToken();
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
        token = check lexer.getNextNonWhiteSpaceToken();
        if (token.'type == T_COMMA) {
            token = check lexer.getNextNonWhiteSpaceToken();
            continue;
        }
    }
    return arguments;
}
