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

public class Parser {
    private Lexer lexer;
    private DocumentNode document;

    public isolated function init(string text) {
        self.lexer = new(text);
        self.document = new;
    }

    public isolated function parse() returns DocumentNode|Error {
        check self.populateDocument();
        return self.document;
    }

    isolated function populateDocument() returns Error? {
        Token token = check self.peekNextNonSeparatorToken();

        while token.kind != T_EOF {
            check self.parseRootOperation(token);
            token = check self.peekNextNonSeparatorToken();
        }
    }

    isolated function parseRootOperation(Token token) returns Error? {
        if token.kind == T_OPEN_PARENTHESES || token.kind == T_OPEN_BRACE {
            return self.parseAnonymousOperation();
        } else if token.kind == T_IDENTIFIER {
            Scalar value = token.value;
            if value is RootOperationType {
                return self.parseOperationWithType(value);
            } else if value == FRAGMENT {
                return self.parseFragment();
            }
        }
        return getUnexpectedTokenError(token);
    }

    isolated function parseAnonymousOperation() returns Error? {
        Token token = check self.peekNextNonSeparatorToken();
        OperationNode operation = check self.createOperationNode(ANONYMOUS_OPERATION, QUERY, token.location);
        self.addOperationToDocument(operation);
    }

    isolated function parseOperationWithType(RootOperationType operationType) returns Error? {
        Token token = check self.readNextNonSeparatorToken();
        Location location = token.location.clone();
        token = check self.peekNextNonSeparatorToken();
        string operationName = check getOperationNameFromToken(self);
        token = check self.peekNextNonSeparatorToken();
        TokenType tokenType = token.kind;
        if tokenType == T_OPEN_PARENTHESES || tokenType == T_OPEN_BRACE {
            OperationNode operation = check self.createOperationNode(operationName, operationType, location);
            self.addOperationToDocument(operation);
        } else {
            return getExpectedCharError(token, OPEN_BRACE);
        }
    }

    isolated function parseFragment() returns Error? {
        Token token = check self.readNextNonSeparatorToken(); // fragment keyword already validated
        Location location = token.location.clone();

        token = check self.readNextNonSeparatorToken();
        string name = check getIdentifierTokenvalue(token);
        if name == ON {
            return getUnexpectedTokenError(token);
        }

        token = check self.readNextNonSeparatorToken();
        string keyword = check getIdentifierTokenvalue(token);
        if keyword != ON {
            return getExpectedCharError(token, ON);
        }

        token = check self.readNextNonSeparatorToken();
        string onType = check getIdentifierTokenvalue(token);

        FragmentNode fragmentNode = new(name, location, onType, false);
        token = check self.peekNextNonSeparatorToken();
        if token.kind != T_OPEN_BRACE {
            return getExpectedCharError(token, OPEN_BRACE);
        }
        check self.addSelections(fragmentNode);
        check self.document.addFragment(fragmentNode);
    }

    isolated function createOperationNode(string name, RootOperationType kind, Location location)
    returns OperationNode|Error {
        OperationNode operation = new(name, kind, location);
        Token token = check self.peekNextNonSeparatorToken();
        if token.kind == T_OPEN_PARENTHESES {
            check self.addVariableDefinition(operation);
        }
        check self.addSelections(operation);
        return operation;
    }

    isolated function addVariableDefinition(OperationNode operationNode) returns Error? {
        Token token = check self.readNextNonSeparatorToken(); // Read the open parantheses here
        while token.kind != T_CLOSE_PARENTHESES {
            token = check self.readNextNonSeparatorToken();
            if token.kind != T_DOLLAR {
                return getExpectedCharError(token, DOLLAR);
            }
            Location varDefinitionLocation = token.location.clone();
            token = check self.readNextNonSeparatorToken();
            string varName = check getIdentifierTokenvalue(token);
            Location varLocation = token.location.clone();
            token = check self.readNextNonSeparatorToken();
            if token.kind != T_COLON {
                return getExpectedCharError(token, COLON);
            }
            token = check self.readNextNonSeparatorToken();
            string varType = check self.getTypeIdentifierTokenValue(token);
            VariableDefinition varDefinition = {
                name: varName,
                kind: varType,
                location: varDefinitionLocation
            };
            token = check self.peekNextNonSeparatorToken();
            if token.kind == T_EQUAL {
                token = check self.readNextNonSeparatorToken();// consume "=" sign here
                token = check self.peekNextNonSeparatorToken();
                if token.kind == T_OPEN_BRACE {
                    ArgumentNode value = check self.getInputObjectTypeArgument(varName, varLocation);
                    varDefinition.defaultValue = value;
                } else {
                    token = check self.readNextNonSeparatorToken();
                    ArgumentValue value = check getArgumentValue(token);
                    varDefinition.defaultValue = value;
                }
                token = check self.peekNextNonSeparatorToken();
            }
            operationNode.addVariableDefinition(varDefinition);
        }
        token = check self.readNextNonSeparatorToken();
    }

    isolated function addSelections(ParentNode parentNode) returns Error? {
        Token token = check self.readNextNonSeparatorToken(); // Read the open brace here
        while token.kind != T_CLOSE_BRACE {
            token = check self.peekNextNonSeparatorToken();
            if token.kind == T_ELLIPSIS {
                check self.addFragment(parentNode);
            } else {
                FieldNode fieldNode = check self.addSelectionToNode(parentNode);
                Selection selection = {
                    name: fieldNode.getAlias(),
                    isFragment: false,
                    node: fieldNode,
                    location: fieldNode.getLocation()
                };
                parentNode.addSelection(selection);
            }
            token = check self.peekNextNonSeparatorToken();
        }
        // If it comes to this, token.kind == T_CLOSE_BRACE. We consume it
        token = check self.readNextNonSeparatorToken();
    }

    isolated function addFragment(ParentNode parentNode) returns Error? {
        Token token = check self.readNextNonSeparatorToken(); // Consume Ellipsis token
        Location spreadLocation = token.location;
        token = check self.peekNextNonSeparatorToken();
        string keyword = check getIdentifierTokenvalue(token);
        if keyword == ON {
            var [name, location] = check self.addInlineFragmentToNode(parentNode);
            Selection selection = {
                name: name,
                isFragment: true,
                location: location,
                spreadLocation: spreadLocation
            };
            parentNode.addSelection(selection);
        } else {
            var [name, location] = check self.addNamedFragmentToNode(parentNode);
            Selection selection = {
                name: name,
                isFragment: true,
                location: location,
                spreadLocation: spreadLocation
            };
            parentNode.addSelection(selection);
        }
    }

    isolated function addSelectionToNode(ParentNode parentNode) returns FieldNode|Error {
        Token token = check self.readNextNonSeparatorToken();
        string alias = check getIdentifierTokenvalue(token);
        string name = check self.getNameWhenAliasPresent(alias);

        FieldNode fieldNode = new(name, token.location, alias);
        check self.addArgumentsToSelection(fieldNode);

        token = check self.peekNextNonSeparatorToken();
        if token.kind == T_OPEN_BRACE {
            check self.addSelections(fieldNode);
        }
        parentNode.addField(fieldNode);
        return fieldNode;
    }

    isolated function addNamedFragmentToNode(ParentNode parentNode) returns ([string, Location]|Error) {
        Token token = check self.readNextNonSeparatorToken();
        string fragmentName = check getIdentifierTokenvalue(token);
        parentNode.addFragment(fragmentName);
        return [fragmentName, token.location];
    }

    isolated function addInlineFragmentToNode(ParentNode parentNode) returns ([string,Location]|Error) {
        Token token = check self.readNextNonSeparatorToken();//Consume on keyword
        token = check self.readNextNonSeparatorToken();
        Location location = token.location;
        string onType = check getIdentifierTokenvalue(token);
        string fragmentName = string`${parentNode.getName()}_${onType}`;
        FragmentNode fragmentNode = new(fragmentName, location, onType, true);
        token = check self.peekNextNonSeparatorToken();
        if token.kind != T_OPEN_BRACE {
            return getExpectedCharError(token, OPEN_BRACE);
        }
        check self.addSelections(fragmentNode);
        check self.document.addFragment(fragmentNode);
        parentNode.addFragment(fragmentName);
        return [fragmentName, location];
    }

    isolated function addArgumentsToSelection(FieldNode fieldNode) returns Error? {
        Token token = check self.peekNextNonSeparatorToken();
        if token.kind != T_OPEN_PARENTHESES {
            return;
        }
        token = check self.readNextNonSeparatorToken();
        while token.kind != T_CLOSE_PARENTHESES {
            token = check self.readNextNonSeparatorToken();
            string name = check getIdentifierTokenvalue(token);
            Location location = token.location.clone();
            token = check self.readNextNonSeparatorToken();
            if token.kind != T_COLON {
                return getExpectedCharError(token, COLON);
            }
            token = check self.peekNextNonSeparatorToken();
            if token.kind == T_OPEN_BRACE {
                ArgumentNode argumentNode = check self.getInputObjectTypeArgument(name, location);
                fieldNode.addArgument(argumentNode);
            } else {
                ArgumentNode argument = check self.getScalarTypeArgument(name, location);
                fieldNode.addArgument(argument);
            }
            token = check self.peekNextNonSeparatorToken();
        }
        // If it comes to this, token.kind == T_CLOSE_BRACE. We consume it
        token = check self.readNextNonSeparatorToken();
    }

    isolated function getInputObjectTypeArgument(string name, Location location) returns ArgumentNode|Error {
        ArgumentNode argumentNode = new(name, location, T_IDENTIFIER, isInputObject = true);
        Token token = check self.readNextNonSeparatorToken();// consume open brace here
        token = check self.peekNextNonSeparatorToken();
        if token.kind != T_CLOSE_BRACE {
            while token.kind != T_CLOSE_BRACE {
                token = check self.readNextNonSeparatorToken();
                string fieldName = check getIdentifierTokenvalue(token);
                Location fieldLocation = token.location.clone();
                if argumentNode.getValue().hasKey(fieldName) {
                    return getDuplicateFieldError(token);
                }
                token = check self.readNextNonSeparatorToken();
                if token.kind != T_COLON {
                    return getExpectedCharError(token, COLON);
                }
                token = check self.peekNextNonSeparatorToken();
                if token.kind == T_OPEN_BRACE {
                    //nested input objects
                    ArgumentNode nestedInputObjectFields = check self.getInputObjectTypeArgument(fieldName, fieldLocation);
                    argumentNode.setValue(fieldName, nestedInputObjectFields);
                } else if token.kind == T_DOLLAR {
                    //input object fields with variable definitions
                    token = check self.readNextNonSeparatorToken();
                    token = check self.readNextNonSeparatorToken();
                    string varName = check getIdentifierTokenvalue(token);
                    ArgumentNode nestedVariableFields = new(fieldName, token.location, T_IDENTIFIER, isVarDef = true);
                    nestedVariableFields.addVariableName(varName);
                    argumentNode.setValue(fieldName, nestedVariableFields);
                } else {
                    //input object fields with value
                    token = check self.readNextNonSeparatorToken();
                    ArgumentType argType = <ArgumentType>token.kind;
                    ArgumentValue fieldValue = check getArgumentValue(token);
                    ArgumentNode inputObjectFieldNode = new(fieldName, fieldLocation, argType);
                    inputObjectFieldNode.setValue(fieldName, fieldValue);
                    argumentNode.setValue(fieldName, inputObjectFieldNode);
                }
                token = check self.peekNextNonSeparatorToken();
            }
        }
        token = check self.readNextNonSeparatorToken(); // consume close brace here
        return argumentNode;
    }

    isolated function getScalarTypeArgument(string name, Location location) returns ArgumentNode|Error {
        Token token = check self.readNextNonSeparatorToken();
        if token.kind == T_DOLLAR {
            //scalar type argument with variable definition
            token = check self.readNextNonSeparatorToken();
            string varName = check getIdentifierTokenvalue(token);
            ArgumentType argType = <ArgumentType>token.kind;
            ArgumentNode argument = new(name, token.location, argType, isVarDef = true);
            argument.addVariableName(varName);
            return argument;
        } else {
            ArgumentValue value = check getArgumentValue(token);
            ArgumentType argType = <ArgumentType>token.kind;
            ArgumentNode argument = new(name, location, argType);
            argument.setValue(name, value);
            return argument;
        }
    }

    isolated function getNameWhenAliasPresent(string alias) returns string|Error {
        Token token = check self.peekNextNonSeparatorToken();
        if token.kind == T_COLON {
            token = check self.readNextNonSeparatorToken(); // Read colon
            token = check self.readNextNonSeparatorToken();
            return getIdentifierTokenvalue(token);
        }
        return alias;
    }

    isolated function getTypeIdentifierTokenValue(Token token) returns string|Error {
        string varType = check getIdentifierTokenvalue(token);
        Token nextToken = check self.peekNextNonSeparatorToken();
        if nextToken.kind == T_EXCLAMATION {
            nextToken = check self.readNextNonSeparatorToken(); // Read exlamation
            varType += nextToken.value.toString();
            return varType;
        }
        return varType;
    }

    isolated function addOperationToDocument(OperationNode operation) {
        self.document.addOperation(operation);
    }

    isolated function readNextNonSeparatorToken() returns Token|Error {
        Token token = check self.lexer.read();
        if token.kind is IgnoreType {
            return self.readNextNonSeparatorToken();
        }
        return token;
    }

    isolated function peekNextNonSeparatorToken() returns Token|Error {
        int i = 1;
        Token token = check self.lexer.peek(i);
        while true {
            if token.kind is LexicalType {
                break;
            }
            i += 1;
            token = check self.lexer.peek(i);
        }

        return token;
    }
}

isolated function getRootOperationType(Token token) returns RootOperationType|Error {
    string value = <string>token.value;
    if value is RootOperationType {
        return value;
    }
    return getUnexpectedTokenError(token);
}

isolated function getArgumentValue(Token token) returns ArgumentValue|Error {
    if token.kind is ArgumentType {
        return {
            value: token.value,
            location: token.location
        };
    } else {
        return getUnexpectedTokenError(token);
    }
}

isolated function getOperationNameFromToken(Parser parser) returns string|Error {
    Token token = check parser.peekNextNonSeparatorToken();
    if token.kind == T_IDENTIFIER {
        // If this is a named operation, we should consume name token
        token = check parser.readNextNonSeparatorToken();
        return <string>token.value;
    } else if token.kind == T_OPEN_BRACE || token.kind == T_OPEN_PARENTHESES {
        return ANONYMOUS_OPERATION;
    }
    return getUnexpectedTokenError(token);
}

isolated function getIdentifierTokenvalue(Token token) returns string|Error {
    if token.kind == T_IDENTIFIER {
        return <string>token.value;
    } else {
        return getExpectedNameError(token);
    }
}
