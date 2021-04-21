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

    private __Schema schema;
    private parser:DocumentNode documentNode;
    private int maxQueryDepth;
    private ErrorDetail[] errors;
    private map<string> usedFragments;

    public isolated function init(__Schema schema, parser:DocumentNode documentNode, int maxQueryDepth) {
        self.schema = schema;
        self.documentNode = documentNode;
        self.maxQueryDepth = maxQueryDepth;
        self.errors = [];
        self.usedFragments = {};
    }

    public isolated function validate() returns ErrorDetail[]? {
        FragmentVisitor fragmentVisitor = new();
        fragmentVisitor.visitDocument(self.documentNode);
        foreach ErrorDetail errorDetail in fragmentVisitor.getErrors() {
            self.errors.push(errorDetail);
        }
        self.visitDocument(self.documentNode);
        if (self.errors.length() > 0) {
            return self.errors;
        }
    }

    public isolated function visitDocument(parser:DocumentNode documentNode) {
        parser:OperationNode[] operations = documentNode.getOperations();
        parser:OperationNode[] anonymousOperations = [];

        foreach ErrorDetail errorDetail in documentNode.getErrors() {
            self.errors.push(errorDetail);
        }

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
            string message = string`Query has depth of ${operationNode.getMaxDepth()}, which exceeds max depth of ${self.maxQueryDepth.toString()}`;
            self.errors.push(getErrorDetailRecord(message, operationNode.getLocation()));
            return;
        }
        Parent parent = {
            parentType: self.schema.queryType,
            name: QUERY_TYPE_NAME
        };
        foreach parser:Selection selection in operationNode.getSelections() {
            self.visitSelection(selection, parent);
        }
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        Parent parent = <Parent>data;
        __Type parentType = <__Type>getOfType(parent.parentType);
        if (parentType.kind == UNION) {
            if (!selection.isFragment) {
                string message = getInvalidFieldOnUnionTypeError(selection.name, parentType);
                self.errors.push(getErrorDetailRecord(message, selection.location));
                return;
            } else {
                parser:FragmentNode fragmentNode = <parser:FragmentNode>selection?.node;
                __Type? requiredType = getTypeFromTypeArray(<__Type[]>parentType?.possibleTypes, fragmentNode.getOnType());
                if (requiredType is __Type) {
                    Parent fragmentParent = {
                        parentType: requiredType,
                        name: requiredType.name.toString()
                    };
                    self.visitFragment(fragmentNode, fragmentParent);
                } else {
                    string message = getFragmetCannotSpreadError(fragmentNode, selection.name, parentType);
                    self.errors.push(getErrorDetailRecord(message, selection.location));
                }
            }
            return;
        }
        if (selection.isFragment) {
            // This will be nil if the fragment is not found. The error is recorded in the fragment visitor.
            // Therefore nil value is ignored.
            var node = selection?.node;
            if (node is ()) {
                return;
            }
            __Type? fragmentOnType = self.validateFragment(selection, <string>parentType.name);
            if (fragmentOnType is __Type) {
                Parent fragmentParent = {
                    parentType: fragmentOnType,
                    name: fragmentOnType.name.toString()
                };
                parser:FragmentNode fragmentNode = <parser:FragmentNode>node;
                self.visitFragment(fragmentNode, fragmentParent);
            }
        } else {
            parser:FieldNode fieldNode = <parser:FieldNode>selection?.node;
            if (selection.name == SCHEMA_FIELD) {
                self.processSchemaIntrospection(selection);
            } else {
                self.visitField(fieldNode, parent);
            }
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        Parent parent = <Parent>data;
        __Type parentType = getOfType(parent.parentType);

        __Field[] fields = parentType?.fields == () ? [] : <__Field[]>parentType?.fields;
        if (fields.length() == 0) {
            string message = getNoSubfieldsErrorMessage(parent.name, parent.parentType);
            self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
            return;
        }

        string requiredFieldName = fieldNode.getName();
        var schemaFieldValue = getFieldFromFieldArray(fields, requiredFieldName);
        if (schemaFieldValue is ()) {
            string message = getFieldNotFoundErrorMessageFromType(requiredFieldName, parent.parentType);
            self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
            return;
        }

        __Field schemaField = <__Field>schemaFieldValue;
        self.checkArguments(parentType, fieldNode, schemaField);

        __Type fieldType = getOfType(schemaField.'type);
        parser:Selection[] selections = fieldNode.getSelections();

        if (hasFields(fieldType) && selections.length() == 0) {
            string message = getMissingSubfieldsErrorFromType(requiredFieldName, schemaField.'type);
            self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
        }

        foreach parser:Selection subSelection in selections {
            if (fieldType.kind == LIST || fieldType.kind == NON_NULL) {
                __Type? ofType = fieldType?.ofType;
                if (ofType is __Type) {
                    Parent subParent = {
                        parentType: <__Type>fieldType?.ofType,
                        name: fieldNode.getName()
                    };
                    self.visitSelection(subSelection, subParent);
                }
            } else {
                Parent subParent = {
                    parentType: fieldType,
                    name: fieldNode.getName()
                };
                self.visitSelection(subSelection, subParent);
            }
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        __InputValue schemaArg = <__InputValue>data;
        __Type argType = getOfType(schemaArg.'type);
        string typeName = argType.name.toString();
        parser:ArgumentValue value = argumentNode.getValue();
        string expectedTypeName = getTypeName(argumentNode);
        if (typeName != expectedTypeName) {
            string message = string`${typeName} cannot represent non ${typeName} value: ${value.value.toString()}`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, value.location);
            self.errors.push(errorDetail);
            return;
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        Parent parent = <Parent>data;
        __Type? fragmentType = self.schema.types[fragmentNode.getOnType()];
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection, parent);
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

    isolated function processSchemaIntrospection(parser:Selection selection) {
        parser:ParentNode parentNode = <parser:ParentNode>selection?.node;
        if (parentNode.getSelections().length() < 1) {
            string message = getMissingSubfieldsError(parentNode.getName(), SCHEMA_TYPE_NAME);
            self.errors.push(getErrorDetailRecord(message, selection.location));
            return;
        }

        foreach parser:Selection subSelection in parentNode.getSelections() {
            self.validateIntrospectionFields(subSelection);
        }
    }

    isolated function validateIntrospectionFields(parser:Selection selection) {
        if (selection.isFragment) {
            parser:FragmentNode fragmentNode = <parser:FragmentNode>selection?.node;
            foreach parser:Selection subSelection in fragmentNode.getSelections() {
                self.validateIntrospectionFields(subSelection);
            }
        } else {
            parser:FieldNode fieldNode = <parser:FieldNode>selection?.node;
            if (selection.name == TYPES_FIELD) {
                __Type schemaType = <__Type>self.schema.types[SCHEMA_TYPE_NAME];
                Parent parent = {
                    parentType: schemaType,
                    name: SCHEMA_TYPE_NAME
                };
                return self.visitSelection(selection, parent);
            }
            var fieldValue = self.schema[selection.name];
            if (fieldValue != ()) {
                __Type schemaType = <__Type>self.schema.types[TYPE_TYPE_NAME];
                Parent parent = {
                    parentType: schemaType,
                    name: SCHEMA_TYPE_NAME
                };
                foreach parser:Selection subSelection in fieldNode.getSelections() {
                    self.visitSelection(subSelection, parent);
                }
                return;
            }
            string message = getFieldNotFoundErrorMessage(selection.name, SCHEMA_TYPE_NAME);
            self.errors.push(getErrorDetailRecord(message, selection.location));
        }
    }

    isolated function validateFragment(parser:Selection fragment, string schemaTypeName) returns __Type? {
        parser:FragmentNode fragmentNode = <parser:FragmentNode>self.documentNode.getFragment(fragment.name);
        string fragmentOnTypeName = fragmentNode.getOnType();
        __Type? fragmentOnType = self.schema.types[fragmentOnTypeName];
        if (fragmentOnType is ()) {
            string message = string`Unknown type "${fragmentOnTypeName}".`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, fragment.location);
            self.errors.push(errorDetail);
        } else {
            __Type schemaType = <__Type>self.schema.types[schemaTypeName];
            __Type ofType = getOfType(schemaType);
            if (fragmentOnType != ofType) {
                string message = getFragmetCannotSpreadError(fragmentNode, fragment.name, ofType);
                ErrorDetail errorDetail = getErrorDetailRecord(message, fragment.location);
                self.errors.push(errorDetail);
            }
            return fragmentOnType;
        }
    }
}

isolated function getFieldFromFieldArray(__Field[] fields, string fieldName) returns __Field? {
    foreach __Field schemaField in fields {
        if (schemaField.name == fieldName) {
            return schemaField;
        }
    }
}

isolated function getTypeFromTypeArray(__Type[] types, string typeName) returns __Type? {
    foreach __Type schemaType in types {
        __Type ofType = getOfType(schemaType);
        if (ofType.name == typeName) {
            return schemaType;
        }
    }
}

isolated function hasFields(__Type fieldType) returns boolean {
    if (fieldType.kind == OBJECT || fieldType.kind == UNION) {
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
