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
    map<parser:VariableDefinition> variableDefinitions;

    isolated function init(__Schema schema, parser:DocumentNode documentNode, map<json>? variableValues) {
        self.schema = schema;
        self.documentNode = documentNode;
        self.visitedVariableDefinitions = [];
        self.errors = [];
        self.variables = variableValues == () ? {} : variableValues;
        self.variableDefinitions = {};
    }

    public isolated function validate() returns ErrorDetail[]? {
        self.visitDocument(self.documentNode);
        if self.errors.length() > 0 {
            return self.errors;
        }
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
        if schemaFieldForOperation is __Field {
            foreach parser:Selection selection in operationNode.getSelections() {
                self.visitSelection(selection, schemaFieldForOperation);
            }
        }
        string[] keys = self.variableDefinitions.keys();
        foreach string name in keys {
            if self.visitedVariableDefinitions.indexOf(name) == () {
                string message = string`Variable "$${name}" is never used.`;
                Location location = <Location> self.variableDefinitions.get(name)?.location;
                self.errors.push(getErrorDetailRecord(message, location)); 
            }
        }
        self.visitedVariableDefinitions = [];
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        if selection.isFragment {
            parser:FragmentNode fragmentNode = self.documentNode.getFragments().get(selection.name);
            self.visitFragment(fragmentNode, data);
        } else {
            parser:FieldNode fieldNode = <parser:FieldNode>selection?.node;
            self.visitField(fieldNode, data);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        __Field parentField = <__Field>data;
        __Type parentType = getOfType(parentField.'type);
        __Field? requiredFieldValue = getRequierdFieldFromType(parentType, self.schema.types, fieldNode);
        __InputValue[] inputValues = requiredFieldValue is __Field ? requiredFieldValue.args : [];
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
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection, data);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        __InputValue[] inputValues = <__InputValue[]>data;
        if argumentNode.isVariableDefinition() {
            string variableName = <string>argumentNode.getVariableName();
            if self.variableDefinitions.hasKey(variableName) {
                parser:VariableDefinition variableDefinition = self.variableDefinitions.get(variableName);
                string argumentTypeName;
                __Type? variableType;
                [variableType, argumentTypeName] = self.getTypeRecordAndTypeFromTypeName(variableDefinition.kind);
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

    public isolated function validateVariableDefinition(parser:ArgumentNode argumentNode, parser:VariableDefinition variableDefinition,
                                                        string argumentTypeName, __Type? variableType) {
        parser:Location location = argumentNode.getLocation();
        string variableName = <string>argumentNode.getVariableName();
        if self.variables.hasKey(variableName) {
            argumentNode.setKind(getArgumentTypeKind(argumentTypeName));
            anydata value = self.variables.get(variableName);
            self.setArgumentValue(value, argumentNode, variableDefinition);
        } else if variableDefinition?.defaultValue is parser:ArgumentValue {
            parser:ArgumentValue value = <parser:ArgumentValue> variableDefinition?.defaultValue;
            if variableType is __Type {
                if value.value is () && variableType.kind == NON_NULL {
                    string message = string`Variable "${variableName}" of type "${variableDefinition.kind}" has` +
                    string` invalid default value: null. Expected type "${argumentTypeName}", found null`;
                    self.errors.push(getErrorDetailRecord(message, value.location));
                } else if value.value is Scalar && getTypeNameFromValue(<Scalar>value.value) != argumentTypeName {
                    string message = string`Variable "${variableName}" of type "${variableDefinition.kind}" has` +
                    string` invalid default value: ${value.value.toString()}. Expected type` +
                    string` "${argumentTypeName}", found ${value.value.toString()}`;
                    self.errors.push(getErrorDetailRecord(message, value.location));
                } else {
                    argumentNode.setKind(getArgumentTypeKind(argumentTypeName));
                    argumentNode.setValue(argumentNode.getName(), value);
                    argumentNode.setVariableDefinition(false);
                }
            }
        } else if variableDefinition?.defaultValue is parser:ArgumentNode {
            parser:ArgumentNode value = <parser:ArgumentNode> variableDefinition?.defaultValue;
            argumentNode.setKind(getArgumentTypeKind(argumentTypeName));
            if getArgumentTypeKind(argumentTypeName) == parser:T_IDENTIFIER {
                foreach parser:ArgumentValue|parser:ArgumentNode fieldValue in value.getValue() {
                    if fieldValue is parser:ArgumentNode {
                        argumentNode.setValue(fieldValue.getName(), fieldValue);
                    }
                }
                argumentNode.setInputObject(true);
                argumentNode.setVariableDefinition(false);
            } else {
                string message = string`Variable "${variableName}" of type "${variableDefinition.kind}" has` +
                string` invalid default value. Expected type "${variableDefinition.kind}"`;
                self.errors.push(getErrorDetailRecord(message, value.getLocation()));
            }
        } else {
            if variableType is __Type && variableType.kind == NON_NULL {
                string message = string`Variable "$${variableName}" of required type ${variableDefinition.kind} `+
                string`was not provided.`;
                self.errors.push(getErrorDetailRecord(message, location));
            } else {
                argumentNode.setValue(argumentNode.getName(), {value: (), location: location});
                argumentNode.setVariableDefinition(false);
            }
        }
    }

    public isolated function setArgumentValue(anydata value, parser:ArgumentNode argument,
                                              parser:VariableDefinition varDef) {
        if argument.getKind() == parser:T_IDENTIFIER {
            argument.setVariableValue(value);
        } else if getTypeNameFromValue(<Scalar>value) == getTypeName(argument) {
            argument.setVariableValue(value);
        } else if value is decimal && getTypeName(argument) == FLOAT {
            argument.setVariableValue(<float>value);
        } else if value is int && getTypeName(argument) == FLOAT {
            argument.setVariableValue(value);
        } else {
            string message = string`Variable "$${<string> argument.getVariableName()}" got invalid value ` +
            string`${value.toString()};Expected type ${varDef.kind}. ${getTypeName(argument)}` +
            string` cannot represent value: ${value.toString()}`;
            self.errors.push(getErrorDetailRecord(message, argument.getLocation()));
        }
    }

    isolated function checkVariableUsageCompatibility(__Type? varType, __InputValue[] inputValues,
                                                      parser:VariableDefinition varDef, parser:ArgumentNode argNode) {
        __InputValue? inputValue = getInputValueFromArray(inputValues, argNode.getName());
        if inputValue is __InputValue {
            if !self.isVariableUsageAllowed(varType, varDef, inputValue) {
                string message = string`Variable "${<string>argNode.getVariableName()}" of type "${varDef.kind}" `+
                string`used in position expecting type "${getTypeNameFromType(inputValue.'type)}".`;
                self.errors.push(getErrorDetailRecord(message, argNode.getLocation()));
            }
        }
    }

    isolated function isVariableUsageAllowed(__Type? varType, parser:VariableDefinition varDef,
                                             __InputValue inputValue) returns boolean {
        if varType is __Type {
            if inputValue.'type.kind == NON_NULL && varType.kind != NON_NULL {
                if inputValue?.defaultValue is () && varDef?.defaultValue is () {
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
                kind: NON_NULL,
                name: ()
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
                kind: LIST,
                name: ()
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

}
