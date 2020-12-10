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

public class ValidatorVisitor {
    *parser:Visitor;

    private ErrorDetail[] errors;
    private __Schema schema;

    public isolated function init(__Schema schema) {
        self.errors = [];
        self.schema = schema;
    }

    public isolated function validate(parser:DocumentNode documentNode) {
        self.visitDocument(documentNode);
    }

    // TODO: Check for definitions other than Operations and Fragments, and if they exists, invalidate.
    // Parser doesn't support it yet.
    public isolated function visitDocument(parser:DocumentNode documentNode) {
        parser:OperationNode[] operations = documentNode.getOperations();
        parser:OperationNode[] anonymousOperations = [];

        foreach parser:OperationNode operationNode in operations {
            if (operationNode.getName() == parser:ANONYMOUS_OPERATION) {
                anonymousOperations.push(operationNode);
            }
            self.visitOperation(operationNode);
        }
        self.checkAnonymousOperations(anonymousOperations);
    }

    public isolated function visitOperation(parser:OperationNode operationNode) {
        __Type queryType = self.schema.queryType;
        parser:FieldNode[] selections = operationNode.getSelections();
        foreach parser:FieldNode selection in selections {
            self.visitField(selection, queryType);
        }
    }

    // TODO: Simplify this function
    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        string requiredFieldName = fieldNode.getName();
        __Type parentType = <__Type>data;
        map<__Field>? result = parentType?.fields;
        if (result == ()) {
            string message = getNoSubFieldsErrorMessage(parentType);
            ErrorDetail errorDetail = getErrorDetailRecord(message, fieldNode.getLocation());
            self.errors.push(errorDetail);
            return;
        }

        map<__Field> fields = <map<__Field>>result;
        var schemaFieldValue = fields[requiredFieldName];
        if (schemaFieldValue is ()) {
            string message = getFieldNotFoundErrorMessage(requiredFieldName, parentType.name);
            ErrorDetail errorDetail = getErrorDetailRecord(message, fieldNode.getLocation());
            self.errors.push(errorDetail);
            return;
        }
        __Field schemaField = <__Field>schemaFieldValue;
        parser:ArgumentNode[] arguments = fieldNode.getArguments();
        map<__InputValue>? schemaArgs = schemaField?.args;

        if (arguments.length() == 0 && schemaArgs == ()) {
            return;
        }

        if (schemaArgs is map<__InputValue>) {
            map<__InputValue> foundArgs = {};
            foreach parser:ArgumentNode argumentNode in arguments {
                string argName = argumentNode.getName().value;
                __InputValue? schemaArg = schemaArgs.get(argName);
                if (schemaArg is __InputValue) {
                    foundArgs[argName] = schemaArg;
                    self.visitArgument(argumentNode, schemaArg);
                } else {
                    string message = getUnknownArgumentErrorMessage(argName, schemaField, argumentNode);
                    ErrorDetail errorDetail = getErrorDetailRecord(message, fieldNode.getLocation());
                    self.errors.push(errorDetail);
                }
            }
        }

        __Type fieldType = schemaField.'type;
        parser:FieldNode[] selections = fieldNode.getSelections();

        if (fieldType.kind == SCALAR) {
            if (selections.length() > 0) {
                string message = getNoSubfieldsError(requiredFieldName, fieldType);
                ErrorDetail errorDetail = getErrorDetailRecord(message, fieldNode.getLocation());
                self.errors.push(errorDetail);
            }
        } else if (fieldType.kind == OBJECT) {
            if (selections.length() == 0) {
                string message = getMissingSubfieldsError(requiredFieldName, fieldType.name);
                ErrorDetail errorDetail = getErrorDetailRecord(message, fieldNode.getLocation());
                self.errors.push(errorDetail);
            } else {
                foreach parser:FieldNode subFieldNode in selections {
                    self.visitField(subFieldNode, fieldType);
                }
            }
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        __InputValue schemaArg = <__InputValue>data;
        string typeName = schemaArg.'type.name;
        parser:ArgumentValue value = argumentNode.getValue();
        string expectedTypeName = getTypeName(value);
        if (typeName != expectedTypeName) {
            // TODO: Improve error message
            string message = typeName + " cannot represent non " + typeName + " value: " + value.value.toString();
            ErrorDetail errorDetail = getErrorDetailRecord(message, value.location);
            self.errors.push(errorDetail);
            return;
        }
    }

    public isolated function getErrors() returns ErrorDetail[] {
        return self.errors;
        // TODO: Sort the error records by line and column
    }

    isolated function checkAnonymousOperations(parser:OperationNode[] anonymousOperations) {
        if (anonymousOperations.length() > 1) {
            string message = "This anonymous operation must be the only defined operation.";
            foreach parser:OperationNode operation in anonymousOperations {
                ErrorDetail err = {
                    message: message,
                    locations: [operation.getLocation()]
                };
                self.errors.push(err);
            }
        }
    }
}
