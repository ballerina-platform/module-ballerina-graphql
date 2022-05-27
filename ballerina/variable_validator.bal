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

import graphql.parser;

class VariableValidator {
    *parser:Visitor;

    private final __Schema schema;
    private map<json> variables;
    private string[] visitedVariableDefinitions;
    private ErrorDetail[] errors;
    map<parser:VariableNode> variableDefinitions;
    private (string|int)[] argumentPath;

    isolated function init(__Schema schema, map<json>? variableValues) {
        self.schema = schema;
        self.visitedVariableDefinitions = [];
        self.errors = [];
        self.variables = variableValues == () ? {} : variableValues;
        self.variableDefinitions = {};
        self.argumentPath = [];
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        parser:OperationNode[] operations = documentNode.getOperations();
        foreach parser:OperationNode operationNode in operations {
            operationNode.accept(self);
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        self.variableDefinitions = operationNode.getVaribleDefinitions();
        __Field? schemaFieldForOperation =
            createSchemaFieldFromOperation(self.schema.types, operationNode, self.errors);
        foreach ErrorDetail errorDetail in operationNode.getErrors() {
            self.errors.push(errorDetail);
        }
        self.validateDirectiveVariables(operationNode);
        if schemaFieldForOperation is __Field {
            foreach parser:SelectionNode selection in operationNode.getSelections() {
                selection.accept(self, schemaFieldForOperation);
            }
        }
        string[] keys = self.variableDefinitions.keys();
        foreach string name in keys {
            if self.visitedVariableDefinitions.indexOf(name) == () {
                string message = string `Variable "$${name}" is never used.`;
                Location location = self.variableDefinitions.get(name).getLocation();
                self.errors.push(getErrorDetailRecord(message, location));
            }
        }
        self.visitedVariableDefinitions = [];
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        __Field parentField = <__Field>data;
        __Type parentType = getOfType(parentField.'type);
        __Field? requiredFieldValue = getRequierdFieldFromType(parentType, self.schema.types, fieldNode);
        __InputValue[] inputValues = requiredFieldValue is __Field ? requiredFieldValue.args : [];
        self.validateDirectiveVariables(fieldNode);
        foreach parser:ArgumentNode argument in fieldNode.getArguments() {
            argument.accept(self, inputValues);
        }
        if fieldNode.getSelections().length() > 0 {
            parser:SelectionNode[] selections = fieldNode.getSelections();
            foreach parser:SelectionNode subSelection in selections {
                subSelection.accept(self, data);
            }
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        self.validateDirectiveVariables(fragmentNode);
        foreach parser:SelectionNode selection in fragmentNode.getSelections() {
            selection.accept(self, data);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        __InputValue[] inputValues = <__InputValue[]>data;
        if argumentNode.isVariableDefinition() {
            string variableName = <string>argumentNode.getVariableName();
            self.updatePath(variableName);
            if self.variableDefinitions.hasKey(variableName) {
                parser:VariableNode variableNode = self.variableDefinitions.get(variableName);
                string argumentTypeName;
                __Type? variableType;
                [variableType, argumentTypeName] = self.getTypeRecordAndTypeFromTypeName(variableNode.getTypeName());
                if variableType is __Type {
                    self.validateVariableDefinition(argumentNode, variableNode, variableType);
                    self.checkVariableUsageCompatibility(variableType, inputValues, variableNode, argumentNode);
                    self.visitedVariableDefinitions.push(variableName);
                } else {
                    self.visitedVariableDefinitions.push(variableName);
                    string message = string `Unknown type "${argumentTypeName}".`;
                    self.errors.push(getErrorDetailRecord(message, variableNode.getLocation()));
                }
            } else {
                string message = string `Variable "$${variableName}" is not defined.`;
                self.errors.push(getErrorDetailRecord(message, argumentNode.getLocation()));
            }
            self.removePath();
        } else {
            __InputValue? inputValue = getInputValueFromArray(inputValues, argumentNode.getName());
            if inputValue is __InputValue {
                if getTypeKind(inputValue.'type) is LIST {
                    __InputValue[] inputFieldValues = [];
                    inputFieldValues.push(createInputValueForListItem(inputValue));
                    inputValues = inputFieldValues;
                } else {
                    __Type? inputFieldType = getOfType(inputValue.'type);
                    __InputValue[]? inputFieldValues = inputFieldType?.inputFields;
                    inputValues = inputFieldValues is __InputValue[] ? inputFieldValues : [];
                }
            }

            if argumentNode.getValue() is parser:ArgumentValue[] {
                foreach parser:ArgumentValue argField in <parser:ArgumentValue[]>argumentNode.getValue() {
                    if argField is parser:ArgumentNode {
                        argField.accept(self, inputValues);
                    }
                }
            }
        }
    }

    isolated function validateVariableDefinition(parser:ArgumentNode argumentNode, parser:VariableNode variable,
                                                 __Type variableType) {
        string variableName = <string>argumentNode.getVariableName();
        parser:ArgumentNode? defaultValue = variable.getDefaultValue();
        if self.variables.hasKey(variableName) {
            argumentNode.setKind(getArgumentTypeIdentifierFromType(variableType));
            json value = self.variables.get(variableName);
            self.setArgumentValue(value, argumentNode, variable.getTypeName(), variableType);
        } else if defaultValue is parser:ArgumentNode {
            boolean hasInvalidValue = self.hasInvalidDefaultValue(defaultValue, variableType);
            if hasInvalidValue {
                string message = getInvalidDefaultValueError(variableName, variable.getTypeName(), defaultValue);
                self.errors.push(getErrorDetailRecord(message, defaultValue.getValueLocation()));
            } else {
                self.setDefaultValueToArgumentNode(argumentNode, getArgumentTypeIdentifierFromType(variableType),
                                                   defaultValue.getValue(), defaultValue.getValueLocation());
            }
        } else {
            parser:Location location = argumentNode.getLocation();
            if variableType.kind == NON_NULL {
                string message = string `Variable "$${variableName}" of required type ${variable.getTypeName()} was `+
                                 string `not provided.`;
                self.errors.push(getErrorDetailRecord(message, location));
            } else {
                argumentNode.setValueLocation(location);
                argumentNode.setVariableDefinition(false);
            }
        }
    }

    isolated function hasInvalidDefaultValue(parser:ArgumentNode defaultValue, __Type variableType) returns boolean {
        if defaultValue.getKind() == getArgumentTypeIdentifierFromType(variableType) {
            if defaultValue.getKind() == parser:T_LIST {
                self.validateListTypeDefaultValue(defaultValue, variableType);
                return false;
            }
            return false;
        } else if defaultValue.getKind() == parser:T_INT &&
            getArgumentTypeIdentifierFromType(variableType) == parser:T_FLOAT {
            defaultValue.setValue(defaultValue.getValue());
            return false;
        } else if defaultValue.getValue() is () && variableType.kind != NON_NULL {
            return false;
        } else {
            return true;
        }
    }

    isolated function validateListTypeDefaultValue(parser:ArgumentNode defaultValue, __Type variableType) {
        __Type memberType = getListMemberTypeFromType(variableType);
        parser:ArgumentValue[] members = <parser:ArgumentValue[]> defaultValue.getValue();
        if members.length() > 0 {
            foreach int i in 0..< members.length() {
                self.updatePath(i);
                parser:ArgumentValue member = members[i];
                if member is parser:ArgumentNode {
                    boolean hasInvalidValue = self.hasInvalidDefaultValue(member, memberType);
                    if hasInvalidValue {
                        string listError = string `${getListElementError(self.argumentPath)}`;
                        string message = getInvalidDefaultValueError(listError, getTypeNameFromType(memberType), member);
                        self.errors.push(getErrorDetailRecord(message, member.getValueLocation()));
                    }
                }
                self.removePath();
            }
        } else if memberType.kind == NON_NULL  {
            string listError = string `${getListElementError(self.argumentPath)}`;
            string message = getInvalidDefaultValueError(listError, getTypeNameFromType(variableType), defaultValue);
            self.errors.push(getErrorDetailRecord(message, defaultValue.getValueLocation()));
        }
    }

    isolated function setDefaultValueToArgumentNode(parser:ArgumentNode argumentNode, parser:ArgumentType kind,
                                                    parser:ArgumentValue|parser:ArgumentValue[] defaultValue,
                                                    parser:Location valueLocation) {
        argumentNode.setKind(kind);
        argumentNode.setValue(defaultValue);
        argumentNode.setValueLocation(valueLocation);
        argumentNode.setVariableDefinition(false);
    }

    isolated function setArgumentValue(json value, parser:ArgumentNode argument, string variableTypeName,
                                       __Type variableType) {
        if getOfType(variableType).name == UPLOAD {
            return;
        } else if value !is () && (argument.getKind() == parser:T_INPUT_OBJECT ||
            argument.getKind() == parser:T_LIST || argument.getKind() == parser:T_IDENTIFIER) {
            argument.setVariableValue(value);
        } else if value is Scalar && getTypeNameFromValue(<Scalar>value) == getTypeName(argument) {
            argument.setVariableValue(value);
        } else if getTypeName(argument) == FLOAT && value is decimal|int {
            argument.setVariableValue(value);
        } else if value is () && variableType.kind != NON_NULL {
            argument.setVariableValue(value);
        } else {
            string invalidValue = value is () ? "null": value.toString();
            string message = string `Variable ${<string> argument.getVariableName()} expected value of type ` +
                             string `"${variableTypeName}", found ${invalidValue}`;
            self.errors.push(getErrorDetailRecord(message, argument.getLocation()));
        }
    }

    isolated function checkVariableUsageCompatibility(__Type varType, __InputValue[] inputValues,
                                                      parser:VariableNode variable,
                                                      parser:ArgumentNode argNode) {
        __InputValue? inputValue = getInputValueFromArray(inputValues, argNode.getName());
        if inputValue is __InputValue {
            if !self.isVariableUsageAllowed(varType, variable, inputValue) {
                string message = string `Variable "${<string>argNode.getVariableName()}" of type `+
                                 string `"${variable.getTypeName()}" used in position expecting type `+
                                 string `"${getTypeNameFromType(inputValue.'type)}".`;
                self.errors.push(getErrorDetailRecord(message, argNode.getLocation()));
            }
        }
    }

    isolated function isVariableUsageAllowed(__Type varType, parser:VariableNode variable,
                                             __InputValue inputValue) returns boolean {
        if inputValue.'type.kind == NON_NULL && varType.kind != NON_NULL {
            if inputValue?.defaultValue is () && variable.getDefaultValue() is () {
                return false;
            }
            return self.areTypesCompatible(varType, <__Type>inputValue.'type?.ofType);
        }
        return self.areTypesCompatible(varType, inputValue.'type);
    }

    isolated function areTypesCompatible(__Type varType, __Type inputType) returns boolean {
        if inputType.kind == NON_NULL {
            if varType.kind != NON_NULL {
                return false;
            }
            return self.areTypesCompatible(<__Type>varType?.ofType, <__Type>inputType?.ofType);
        } else if varType.kind == NON_NULL {
            return self.areTypesCompatible(<__Type>varType?.ofType, inputType);
        } else if inputType.kind == LIST {
            if varType.kind != LIST {
                return false;
            }
            return self.areTypesCompatible(<__Type>varType?.ofType, <__Type>inputType?.ofType);
        } else if varType.kind == LIST {
            return false;
        } else {
            if inputType == varType {
                return true;
            }
            return false;
        }
    }

    isolated function getTypeRecordAndTypeFromTypeName(string typeName) returns [__Type?, string] {
        if typeName.endsWith("!") {
            __Type wrapperType = {
                kind: NON_NULL
            };
            string ofTypeName = typeName.substring(0, typeName.length()-1);
            __Type? ofType;
            [ofType, ofTypeName] = self.getTypeRecordAndTypeFromTypeName(ofTypeName);
            if ofType is __Type {
                wrapperType.ofType = ofType;
                return [wrapperType, ofTypeName];
            }
            return [(), ofTypeName];
        } else if typeName.startsWith("[") {
            __Type wrapperType = {
                kind: LIST
            };
            string ofTypeName = typeName.substring(1, typeName.length()-1);
            __Type? ofType;
            [ofType, ofTypeName] = self.getTypeRecordAndTypeFromTypeName(ofTypeName);
            if ofType is __Type {
                wrapperType.ofType = ofType;
                return [wrapperType, ofTypeName];
            }
            return [(), ofTypeName];
        } else {
            return [getTypeFromTypeArray(self.schema.types, typeName), typeName];
        }
    }

    isolated function validateDirectiveVariables(parser:SelectionParentNode node) {
        foreach parser:DirectiveNode directive in node.getDirectives() {
            boolean isDefinedDirective = false;
            foreach __Directive defaultDirective in self.schema.directives {
                if directive.getName() == defaultDirective.name {
                    isDefinedDirective = true;
                    foreach parser:ArgumentNode argument in directive.getArguments() {
                        argument.accept(self, defaultDirective.args);
                    }
                    break;
                }
            }
            if !isDefinedDirective {
                //visit undefined directive's variables
                foreach parser:ArgumentNode argument in directive.getArguments() {
                    if argument.isVariableDefinition() {
                        self.visitedVariableDefinitions.push(<string>argument.getVariableName());
                    }
                }
            }
        }
    }

    isolated function updatePath(string|int path) {
        self.argumentPath.push(path);
    }

    isolated function removePath() {
        _ = self.argumentPath.pop();
    }

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {}

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {}

    isolated function getErrors() returns ErrorDetail[]? {
        return self.errors.length() > 0 ? self.errors : ();
    }
}
