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

    private parser:DocumentNode documentNode;
    private map<json> variables;
    private string[] visitedVariableDefinitions;
    private ErrorDetail[] errors;

    public isolated function init(parser:DocumentNode documentNode, map<json>? variableValues){
        self.documentNode = documentNode;
        self.visitedVariableDefinitions = [];
        self.errors = [];
        self.variables = variableValues == () ? {} : variableValues;
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
        map<parser:VariableDefinition> variableDefinitions = operationNode.getVaribleDefinitions();
        foreach ErrorDetail errorDetail in operationNode.getErrors() {
            self.errors.push(errorDetail);
        }
        foreach parser:Selection selection in operationNode.getSelections() {
            self.visitSelection(selection, <anydata>variableDefinitions);
        }
        string[] keys = variableDefinitions.keys();
        foreach string name in keys {
            if self.visitedVariableDefinitions.indexOf(name) == () {
                string message = string`Variable "$${name}" is never used.`;
                Location location  = <Location> variableDefinitions.get(name)?.location;
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
        foreach parser:ArgumentNode argument in fieldNode.getArguments() {
            self.visitArgument(argument, data);
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
        map<parser:VariableDefinition> variableDefinitions = <map<parser:VariableDefinition>> data;
        parser:Location location = argumentNode.getLocation();
        if argumentNode.isVariableDefinition() {
            string variableName = <string>argumentNode.getVariableName();
            if variableDefinitions.hasKey(variableName) {
                parser:VariableDefinition variableDefinition = variableDefinitions.get(variableName);
                self.visitedVariableDefinitions.push(variableName);
                if self.variables.hasKey(variableName) {
                    argumentNode.setKind(getArgumentTypeKind(variableDefinition.kind));
                    anydata value = self.variables.get(variableName);
                    self.setArgumentValue(value, argumentNode, location);
                } else if !(variableDefinition?.defaultValue is ()) {
                    argumentNode.setKind(getArgumentTypeKind(variableDefinition.kind));
                    if variableDefinition?.defaultValue is parser:ArgumentValue {
                        argumentNode.setValue(<parser:ArgumentValue>variableDefinition?.defaultValue);
                        argumentNode.setVariableDefinition(false);
                    } else {
                        parser:ArgumentNode defaultValue = <parser:ArgumentNode>variableDefinition?.defaultValue;
                        argumentNode.setValue(defaultValue.getValue());
                        argumentNode.setVariableDefinition(false);
                    }
                } else {
                    string message = string`Variable "$${variableName}" of required type ${variableDefinition.kind} `+
                    string`was not provided.`;
                    self.errors.push(getErrorDetailRecord(message, location));
                }
            } else {
                string message = string`Variable "$${variableName}" is not defined.`;
                self.errors.push(getErrorDetailRecord(message, location)); 
            }
        } else if argumentNode.getValue() is map<parser:ArgumentValue|parser:ArgumentNode> {
            map<parser:ArgumentValue|parser:ArgumentNode> fields =
                <map<parser:ArgumentValue|parser:ArgumentNode>> argumentNode.getValue();
            foreach string keys in fields.keys() {
                if fields.get(keys) is parser:ArgumentNode {
                    self.visitArgument(<parser:ArgumentNode>fields.get(keys), data);
                }
            }
        }
    }

    public isolated function setArgumentValue(anydata value, parser:ArgumentNode argument,
                                              parser:Location location) {
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
            string`${value.toString()};Expected type ${getTypeName(argument)}. ${getTypeName(argument)}` +
            string` cannot represent value: ${value.toString()}`;
            self.errors.push(getErrorDetailRecord(message, location)); 
        }
    }
}
