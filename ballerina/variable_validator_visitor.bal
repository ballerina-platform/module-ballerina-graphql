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

class VariableValidatorVisitor {
    *ValidatorVisitor;

    private string[] visitedVariableDefinitions = [];
    private map<parser:VariableNode> variableDefinitions = {};
    private final ErrorDetail[] errors = [];
    private final (string|int)[] argumentPath = [];
    private final __Schema schema;
    private final map<json> variables;
    private final NodeModifierContext nodeModifierContext;

    isolated function init(__Schema schema, map<json>? variableValues, NodeModifierContext nodeModifierContext) {
        self.schema = schema;
        self.variables = variableValues == () ? {} : variableValues;
        self.nodeModifierContext = nodeModifierContext;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        parser:OperationNode[] operations = documentNode.getOperations();
        foreach parser:OperationNode operationNode in operations {
            operationNode.accept(self);
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        self.variableDefinitions = operationNode.getVaribleDefinitions();
        __Field? schemaFieldForOperation = createSchemaFieldFromOperation(self.schema.types, operationNode, self.errors,
                                                                          self.nodeModifierContext);
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
        parser:FragmentNode modifiedFragmentNode = self.nodeModifierContext.getModifiedFragmentNode(fragmentNode);
        self.validateDirectiveVariables(modifiedFragmentNode);
        foreach parser:SelectionNode selection in modifiedFragmentNode.getSelections() {
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
                    self.modifyArgumentNode(argumentNode, containsInvalidValue = true);
                }
            } else {
                string message = string `Variable "$${variableName}" is not defined.`;
                self.errors.push(getErrorDetailRecord(message, argumentNode.getLocation()));
                self.modifyArgumentNode(argumentNode, containsInvalidValue = true);
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
                parser:ArgumentValue[] value = [];
                foreach parser:ArgumentValue argField in <parser:ArgumentValue[]>argumentNode.getValue() {
                    if argField is parser:ArgumentNode {
                        argField.accept(self, inputValues);
                        parser:ArgumentNode modifiedArgNode = self.nodeModifierContext.getModifiedArgumentNode(argField);
                        value.push(modifiedArgNode);
                    } else {
                        value.push(argField);
                    }
                }
                self.modifyArgumentNode(argumentNode, value = value);
            }
        }
    }

    isolated function validateVariableDefinition(parser:ArgumentNode argumentNode, parser:VariableNode variable,
                                                 __Type variableType) {
        string variableName = <string>argumentNode.getVariableName();
        parser:ArgumentNode? defaultValue = variable.getDefaultValue();
        if self.variables.hasKey(variableName) {
            self.modifyArgumentNode(argumentNode, kind = getArgumentTypeIdentifierFromType(variableType));
            json value = self.variables.get(variableName);
            self.setArgumentValue(value, argumentNode, variable.getTypeName(), variableType);
        } else if defaultValue is parser:ArgumentNode {
            boolean hasInvalidValue = self.hasInvalidDefaultValue(defaultValue, variableType);
            if hasInvalidValue {
                string message = getInvalidDefaultValueError(variableName, variable.getTypeName(), defaultValue);
                self.errors.push(getErrorDetailRecord(message, defaultValue.getValueLocation()));
                self.modifyArgumentNode(argumentNode, containsInvalidValue = true);
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
                self.modifyArgumentNode(argumentNode, containsInvalidValue = true);
            } else {
                self.modifyArgumentNode(argumentNode, valueLocation = location, isVarDef = false);
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
            return false;
        } else if defaultValue.getValue() is () && variableType.kind != NON_NULL {
            return false;
        } else {
            return true;
        }
    }

    isolated function validateListTypeDefaultValue(parser:ArgumentNode defaultValue, __Type variableType) {
        __Type memberType = getListMemberTypeFromType(variableType);
        parser:ArgumentValue[] members = <parser:ArgumentValue[]>defaultValue.getValue();
        if members.length() > 0 {
            foreach int i in 0 ..< members.length() {
                self.updatePath(i);
                parser:ArgumentValue member = members[i];
                if member is parser:ArgumentNode {
                    boolean hasInvalidValue = self.hasInvalidDefaultValue(member, memberType);
                    if hasInvalidValue {
                        string listError = string `${getListElementError(self.argumentPath)}`;
                        string message = getInvalidDefaultValueError(listError, getTypeNameFromType(memberType), member);
                        self.errors.push(getErrorDetailRecord(message, member.getValueLocation()));
                        self.modifyArgumentNode(member, containsInvalidValue = true);
                    }
                }
                self.removePath();
            }
        } else if memberType.kind == NON_NULL {
            string listError = string `${getListElementError(self.argumentPath)}`;
            string message = getInvalidDefaultValueError(listError, getTypeNameFromType(variableType), defaultValue);
            self.errors.push(getErrorDetailRecord(message, defaultValue.getValueLocation()));
        }
    }

    isolated function setDefaultValueToArgumentNode(parser:ArgumentNode argumentNode, parser:ArgumentType kind,
                                                    parser:ArgumentValue|parser:ArgumentValue[] defaultValue,
                                                    parser:Location valueLocation) {
        self.modifyArgumentNode(argumentNode, kind = kind, value = defaultValue, valueLocation = valueLocation, isVarDef = false);
    }

    isolated function setArgumentValue(json value, parser:ArgumentNode argument, string variableTypeName,
                                       __Type variableType) {
        parser:ArgumentNode modifiedArgNode = self.nodeModifierContext.getModifiedArgumentNode(argument);
        if getOfType(variableType).name == UPLOAD {
            return;
        } else if value !is () && (modifiedArgNode.getKind() == parser:T_INPUT_OBJECT ||
            modifiedArgNode.getKind() == parser:T_LIST || modifiedArgNode.getKind() == parser:T_IDENTIFIER) {
            self.modifyArgumentNode(argument, variableValue = value);
        } else if value is Scalar && getTypeNameFromScalarValue(<Scalar>value) == getTypeName(modifiedArgNode) {
            self.modifyArgumentNode(argument, variableValue = value);
        } else if getTypeName(modifiedArgNode) == FLOAT && value is decimal|int {
            self.modifyArgumentNode(argument, variableValue = value);
        } else if value is () && variableType.kind != NON_NULL {
            self.modifyArgumentNode(argument, variableValue = value);
        } else {
            string invalidValue = value is () ? "null": value.toString();
            string message = string `Variable ${<string> modifiedArgNode.getVariableName()} expected value of type ` +
                             string `"${variableTypeName}", found ${invalidValue}`;
            self.errors.push(getErrorDetailRecord(message, modifiedArgNode.getLocation()));
            self.modifyArgumentNode(argument, containsInvalidValue = true);
        }
    }

    isolated function checkVariableUsageCompatibility(__Type varType, __InputValue[] inputValues,
                                                      parser:VariableNode variable,
                                                      parser:ArgumentNode argNode) {
        parser:ArgumentNode modifiedArgNode = self.nodeModifierContext.getModifiedArgumentNode(argNode);
        __InputValue? inputValue = getInputValueFromArray(inputValues, modifiedArgNode.getName());
        if inputValue is __InputValue {
            if !self.isVariableUsageAllowed(varType, variable, inputValue) {
                string message = string `Variable "${<string>modifiedArgNode.getVariableName()}" of type `+
                                 string `"${variable.getTypeName()}" used in position expecting type `+
                                 string `"${getTypeNameFromType(inputValue.'type)}".`;
                self.errors.push(getErrorDetailRecord(message, modifiedArgNode.getLocation()));
                self.modifyArgumentNode(argNode, containsInvalidValue = true);
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
            string ofTypeName = typeName.substring(0, typeName.length() - 1);
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
            string ofTypeName = typeName.substring(1, typeName.length() - 1);
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

    public isolated function getErrors() returns ErrorDetail[]? {
        return self.errors.length() > 0 ? self.errors : ();
    }

    private isolated function modifyArgumentNode(parser:ArgumentNode originalNode, parser:ArgumentType? kind = (),
                                                parser:ArgumentValue|parser:ArgumentValue[] value = (),
                                                Location? valueLocation = (), boolean? isVarDef = (),
                                                json variableValue = (), boolean? containsInvalidValue = ()) {
        parser:ArgumentNode previouslyModifiedNode = self.nodeModifierContext.getModifiedArgumentNode(originalNode);
        parser:ArgumentNode newModifiedNode = previouslyModifiedNode.modifyWith(kind, value, valueLocation, isVarDef,
                                                                                variableValue, containsInvalidValue);
        self.nodeModifierContext.addModifiedArgumentNode(originalNode, newModifiedNode);
        return;
    }
}
