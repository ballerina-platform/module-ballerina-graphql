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
    private parser:DocumentNode documentNode;
    private map<json> variables;
    private string[] visitedVariableDefinitions;
    private ErrorDetail[] errors;
    map<parser:VariableDefinitionNode> variableDefinitions;
    private __Directive[] defaultDirectives;

    isolated function init(__Schema schema, parser:DocumentNode documentNode, map<json>? variableValues) {
        self.schema = schema;
        self.documentNode = documentNode;
        self.visitedVariableDefinitions = [];
        self.errors = [];
        self.variables = variableValues == () ? {} : variableValues;
        self.variableDefinitions = {};
        self.defaultDirectives = schema.directives;
    }

    public isolated function validate() returns ErrorDetail[]? {
        self.visitDocument(self.documentNode);
        if self.errors.length() > 0 {
            return self.errors;
        }
        return;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        parser:OperationNode[] operations = documentNode.getOperations();
        foreach parser:OperationNode operationNode in operations {
            self.visitOperation(operationNode);
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
            foreach parser:Selection selection in operationNode.getSelections() {
                self.visitSelection(selection, schemaFieldForOperation);
            }
        }
        string[] keys = self.variableDefinitions.keys();
        foreach string name in keys {
            if self.visitedVariableDefinitions.indexOf(name) == () {
                string message = string`Variable "$${name}" is never used.`;
                Location location = self.variableDefinitions.get(name).getLocation();
                self.errors.push(getErrorDetailRecord(message, location));
            }
        }
        self.visitedVariableDefinitions = [];
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        if selection is parser:FragmentNode {
            self.visitFragment(selection, data);
        } else {
            self.visitField(selection, data);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        __Field parentField = <__Field>data;
        __Type parentType = getOfType(parentField.'type);
        __Field? requiredFieldValue = getRequierdFieldFromType(parentType, self.schema.types, fieldNode);
        __InputValue[] inputValues = requiredFieldValue is __Field ? requiredFieldValue.args : [];
        self.validateDirectiveVariables(fieldNode);
        foreach parser:ArgumentNode argument in fieldNode.getArguments() {
            self.visitArgument(argument, inputValues);
        }
        if fieldNode.getSelections().length() > 0 {
            parser:Selection[] selections = fieldNode.getSelections();
            foreach parser:Selection subSelection in selections {
                self.visitSelection(subSelection, data);
            }
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        self.validateDirectiveVariables(fragmentNode);
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection, data);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        __InputValue[] inputValues = <__InputValue[]>data;
        if argumentNode.isVariableDefinition() {
            string variableName = <string>argumentNode.getVariableName();
            if self.variableDefinitions.hasKey(variableName) {
                parser:VariableDefinitionNode variableDefinition = self.variableDefinitions.get(variableName);
                string argumentTypeName;
                __Type? variableType;
                [variableType, argumentTypeName] = self.getTypeRecordAndTypeFromTypeName(variableDefinition.getTypeName());
                self.checkVariableUsageCompatibility(variableType, inputValues, variableDefinition, argumentNode);
                self.visitedVariableDefinitions.push(variableName);
                self.validateVariableDefinition(argumentNode, variableDefinition, argumentTypeName, variableType);
            } else {
                string message = string`Variable "$${variableName}" is not defined.`;
                self.errors.push(getErrorDetailRecord(message, argumentNode.getLocation()));
            }
        } else {
            __InputValue? inputValue = getInputValueFromArray(inputValues, argumentNode.getName());
            if inputValue is __InputValue {
                __Type? inputFieldType = getOfType(inputValue.'type);
                __InputValue[]? inputFieldValues = inputFieldType?.inputFields;
                inputValues = inputFieldValues is __InputValue[] ? inputFieldValues : [];
            }
            foreach parser:ArgumentValue|parser:ArgumentNode argField in argumentNode.getValue() {
                if argField is parser:ArgumentNode {
                    self.visitArgument(argField, inputValues);
                }
            }
        }
    }

    public isolated function validateVariableDefinition(parser:ArgumentNode argumentNode,
                                                        parser:VariableDefinitionNode varDef, string argumentTypeName,
                                                        __Type? variableType) {
        string variableName = <string>argumentNode.getVariableName();
        parser:ArgumentNode? defaultValue = varDef.getDefaultValue();
        if self.variables.hasKey(variableName) {
            argumentNode.setKind(getArgumentTypeKind(argumentTypeName));
            anydata value = self.variables.get(variableName);
            self.setArgumentValue(value, argumentNode, varDef);
        } else if defaultValue is parser:ArgumentNode {
            if defaultValue.getKind() == parser:T_INPUT_OBJECT {
                if getArgumentTypeKind(argumentTypeName) == parser:T_IDENTIFIER {
                    argumentNode.setKind(parser:T_INPUT_OBJECT);
                    foreach parser:ArgumentValue|parser:ArgumentNode fieldValue in defaultValue.getValue() {
                        if fieldValue is parser:ArgumentNode {
                            argumentNode.setValue(fieldValue.getName(), fieldValue);
                        }
                    }
                    argumentNode.setVariableDefinition(false);
                } else {
                    string message = string`Variable "${variableName}" of type "${varDef.getTypeName()}" has invalid` +
                    string` default value. Expected type "${varDef.getTypeName()}"`;
                    self.errors.push(getErrorDetailRecord(message, defaultValue.getLocation()));
                }
            } else {
                if variableType is __Type {
                    parser:ArgumentValue value = <parser:ArgumentValue> defaultValue.getValue()[variableName];
                    if value.value is Scalar {
                        if getArgumentTypeKind(argumentTypeName) == parser:T_FLOAT &&
                            defaultValue.getKind() == parser:T_INT {
                            self.setDefaultValueToArgumentNode(argumentNode, argumentTypeName, value);
                        } else if getArgumentTypeKind(argumentTypeName) == defaultValue.getKind() {
                            self.setDefaultValueToArgumentNode(argumentNode, argumentTypeName, value);
                        } else {
                            string message = string`Variable "${variableName}" of type "${varDef.getTypeName()}" has` +
                            string` invalid default value: ${value.value.toString()}. Expected type ` +
                            string`"${argumentTypeName}", found ${value.value.toString()}`;
                            self.errors.push(getErrorDetailRecord(message, value.location));
                        }
                    } else {
                        if variableType.kind == NON_NULL {
                            string message = string`Variable "${variableName}" of type "${varDef.getTypeName()}" has` +
                            string` invalid default value: null. Expected type "${argumentTypeName}", found null`;
                            self.errors.push(getErrorDetailRecord(message, value.location));
                        } else {
                            self.setDefaultValueToArgumentNode(argumentNode, argumentTypeName, value);
                        }
                    }
                }
            }
        } else {
            parser:Location location = argumentNode.getLocation();
            if variableType is __Type && variableType.kind == NON_NULL {
                string message = string`Variable "$${variableName}" of required type ${varDef.getTypeName()} was `+
                string`not provided.`;
                self.errors.push(getErrorDetailRecord(message, location));
            } else {
                argumentNode.setValue(argumentNode.getName(), {value: (), location: location});
                argumentNode.setVariableDefinition(false);
            }
        }
    }

    public isolated function setDefaultValueToArgumentNode(parser:ArgumentNode argumentNode, string argumentTypeName,
                                                           parser:ArgumentValue|parser:ArgumentNode defaultValue) {
        argumentNode.setKind(getArgumentTypeKind(argumentTypeName));
        argumentNode.setValue(argumentNode.getName(), defaultValue);
        argumentNode.setVariableDefinition(false);
    }

    public isolated function setArgumentValue(anydata value, parser:ArgumentNode argument,
                                              parser:VariableDefinitionNode varDef) {
        if argument.getKind() == parser:T_INPUT_OBJECT {
            argument.setVariableValue(value);
        } else if argument.getKind() == parser:T_IDENTIFIER {
            argument.setVariableValue(value);
        } else if value is Scalar && getTypeNameFromValue(<Scalar>value) == getTypeName(argument) {
            argument.setVariableValue(value);
        } else if value is decimal && getTypeName(argument) == FLOAT {
            argument.setVariableValue(<float>value);
        } else if value is int && getTypeName(argument) == FLOAT {
            argument.setVariableValue(value);
        } else {
            string message = string`Variable "$${<string> argument.getVariableName()}" got invalid value ` +
            string`${value.toString()}; Expected type ${varDef.getTypeName()}. ${getTypeName(argument)}` +
            string` cannot represent value: ${value.toString()}`;
            self.errors.push(getErrorDetailRecord(message, argument.getLocation()));
        }
    }

    isolated function checkVariableUsageCompatibility(__Type? varType, __InputValue[] inputValues,
                                                      parser:VariableDefinitionNode varDef,
                                                      parser:ArgumentNode argNode) {
        __InputValue? inputValue = getInputValueFromArray(inputValues, argNode.getName());
        if inputValue is __InputValue {
            if !self.isVariableUsageAllowed(varType, varDef, inputValue) {
                string message = string`Variable "${<string>argNode.getVariableName()}" of type `+
                string`"${varDef.getTypeName()}" used in position expecting type `+
                string`"${getTypeNameFromType(inputValue.'type)}".`;
                self.errors.push(getErrorDetailRecord(message, argNode.getLocation()));
            }
        }
    }

    isolated function isVariableUsageAllowed(__Type? varType, parser:VariableDefinitionNode varDef,
                                             __InputValue inputValue) returns boolean {
        if varType is __Type {
            if inputValue.'type.kind == NON_NULL && varType.kind != NON_NULL {
                if inputValue?.defaultValue is () && varDef.getDefaultValue() is () {
                    return false;
                }
                return self.areTypesCompatible(varType, <__Type>inputValue.'type?.ofType);
            }
            return self.areTypesCompatible(varType, inputValue.'type);
        }
        return false;
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

    isolated function validateDirectiveVariables(parser:ParentNode node) {
        foreach parser:DirectiveNode directive in node.getDirectives() {
            boolean isDefinedDirective = false;
            foreach __Directive defaultDirective in self.defaultDirectives {
                if directive.getName() == defaultDirective.name {
                    isDefinedDirective = true;
                    foreach parser:ArgumentNode argument in directive.getArguments() {
                        self.visitArgument(argument, defaultDirective.args);
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

}
