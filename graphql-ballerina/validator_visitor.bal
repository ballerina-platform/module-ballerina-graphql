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

class ValidatorVisitor {
    *parser:Visitor;

    private ErrorDetail[] errors;
    private __Schema schema;
    private int maxQueryDepth;

    public isolated function init(__Schema schema, int maxQueryDepth) {
        self.errors = [];
        self.schema = schema;
        self.maxQueryDepth = maxQueryDepth;
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
        if (self.maxQueryDepth > 0 && operationNode.getMaxDepth() > self.maxQueryDepth) {
            string depthString = operationNode.getMaxDepth().toString();
            string message = "Query has depth of " + depthString + ", which exceeds max depth of " +
                            self.maxQueryDepth.toString();
            self.errors.push(getErrorDetailRecord(message, operationNode.getLocation()));
            return;
        }
        parser:FieldNode[] selections = operationNode.getSelections();
        foreach parser:FieldNode selection in selections {
            if (selection.getName() == SCHEMA_FIELD) {
                self.processSchemaIntrospection(selection);
            } else {
                Parent parent = {
                    parentType: self.schema.queryType,
                    name: QUERY_TYPE_NAME
                };
                self.visitField(selection, parent);
            }
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        Parent parent = <Parent>data;
        __Type parentType = parent.parentType;

        map<__Field> fields = parentType?.fields == () ? {} : <map<__Field>>parentType?.fields;
        if (fields.length() == 0) {
            string message = getNoSubfieldsErrorMessage(parent.name, parentType.name.toString());
            self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
            return;
        }

        string requiredFieldName = fieldNode.getName();
        var schemaFieldValue = fields[requiredFieldName];
        if (schemaFieldValue is ()) {
            string message = getFieldNotFoundErrorMessage(requiredFieldName, parentType.name.toString());
            self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
            return;
        }

        __Field schemaField = <__Field>schemaFieldValue;
        self.checkArguments(parentType, fieldNode, schemaField);

        __Type fieldType = schemaField.'type;
        parser:FieldNode[] selections = fieldNode.getSelections();

        if (hasFields(fieldType) && selections.length() == 0) {
            string message = getMissingSubfieldsError(requiredFieldName, fieldType.name.toString());
            self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
        }

        foreach parser:FieldNode subFieldNode in selections {
            if (fieldType.kind == LIST || fieldType.kind == NON_NULL) {
                __Type? ofType = fieldType?.ofType;
                if (ofType is __Type) {
                    Parent subParent = {
                        parentType: <__Type>fieldType?.ofType,
                        name: fieldNode.getName()
                    };
                    self.visitField(subFieldNode, subParent);
                }
            } else {
                Parent subParent = {
                    parentType: fieldType,
                    name: fieldNode.getName()
                };
                self.visitField(subFieldNode, subParent);
            }
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        __InputValue schemaArg = <__InputValue>data;
        string typeName = schemaArg.'type.name.toString();
        parser:ArgumentValue value = argumentNode.getValue();
        string expectedTypeName = getTypeName(argumentNode);
        if (typeName != expectedTypeName) {
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
                self.errors.push(getErrorDetailRecord(message, operation.getLocation()));
            }
        }
    }

    isolated function checkArguments(__Type parentType, parser:FieldNode fieldNode, __Field schemaField) {
        parser:ArgumentNode[] arguments = fieldNode.getArguments();
        map<__InputValue>? schemaArgs = schemaField?.args;
        map<__InputValue> notFoundArgs = {};

        if (schemaArgs is map<__InputValue>) {
            notFoundArgs = schemaArgs.clone();
            foreach parser:ArgumentNode argumentNode in arguments {
                string argName = argumentNode.getName().value;
                __InputValue|error schemaArg = trap schemaArgs.get(argName);
                if (schemaArg is __InputValue) {
                    _ = notFoundArgs.remove(argName);
                    self.visitArgument(argumentNode, schemaArg);
                } else {
                    string parentName = parentType.name is string ? <string>parentType.name : "";
                    string message = getUnknownArgumentErrorMessage(argName, parentName, fieldNode.getName());
                    self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
                }
            }
        }

        if (notFoundArgs.length() > 0) {
            // TODO: Check dafaultability
            foreach __InputValue inputValue in notFoundArgs.toArray() {
                string message = getMissingRequiredArgError(fieldNode, inputValue);
                self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
            }
        }
    }

    isolated function processSchemaIntrospection(parser:FieldNode fieldNode) {
        if (fieldNode.getSelections().length() < 1) {
            string message = getMissingSubfieldsError(fieldNode.getName(), SCHEMA_TYPE_NAME);
            self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
            return;
        }
        foreach parser:FieldNode selection in fieldNode.getSelections() {
            if (selection.getName() == TYPES_FIELD) {
                __Type schemaType = <__Type>self.schema.types[SCHEMA_TYPE_NAME];
                Parent parent = {
                    parentType: schemaType,
                    name: SCHEMA_TYPE_NAME
                };
                return self.visitField(selection, parent);
            }
            var fieldValue = self.schema[selection.getName()];
            if (fieldValue != ()) {
                __Type schemaType = <__Type>self.schema.types[TYPE_TYPE_NAME];
                Parent parent = {
                    parentType: schemaType,
                    name: SCHEMA_TYPE_NAME
                };
                foreach parser:FieldNode subSelection in selection.getSelections() {
                    self.visitField(subSelection, parent);
                }
                return;
            }
            string message = getFieldNotFoundErrorMessage(selection.getName(), SCHEMA_TYPE_NAME);
            self.errors.push(getErrorDetailRecord(message, selection.getLocation()));
        }
    }
}

isolated function hasFields(__Type fieldType) returns boolean {
    if (fieldType.kind == OBJECT) {
        return true;
    }
    if (fieldType.kind == NON_NULL || fieldType.kind == LIST) {
        __Type? ofType = fieldType?.ofType;
        if (ofType is __Type) {
            return ofType.kind == OBJECT;
        }
    }
    return false;
}

type Parent record {
    __Type parentType;
    string name;
};
