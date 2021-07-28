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
    private ErrorDetail[] errors;
    private map<string> usedFragments;

    isolated function init(__Schema schema, parser:DocumentNode documentNode) {
        self.schema = schema;
        self.documentNode = documentNode;
        self.errors = [];
        self.usedFragments = {};
    }

    public isolated function validate() returns ErrorDetail[]? {
        self.visitDocument(self.documentNode);
        if (self.errors.length() > 0) {
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
                        name: requiredType?.name.toString()
                    };
                    self.visitFragment(fragmentNode, fragmentParent);
                } else {
                    string message = getFragmetCannotSpreadError(fragmentNode, selection.name, parentType);
                    self.errors.push(getErrorDetailRecord(message, <Location>selection?.spreadLocation));
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
            __Type? fragmentOnType = self.validateFragment(selection, <string>parentType?.name);
            if (fragmentOnType is __Type) {
                Parent fragmentParent = {
                    parentType: fragmentOnType,
                    name: fragmentOnType?.name.toString()
                };
                parser:FragmentNode fragmentNode = <parser:FragmentNode>node;
                self.visitFragment(fragmentNode, fragmentParent);
            }
        } else {
            parser:FieldNode fieldNode = <parser:FieldNode>selection?.node;
            if (selection.name == SCHEMA_FIELD) {
                __Type schemaType = <__Type>getTypeFromTypeArray(self.schema.types, SCHEMA_TYPE_NAME);
                parent = {
                    parentType: schemaType,
                    name: selection.name
                };
                if (fieldNode.getSelections().length() == 0) {
                    string message = getMissingSubfieldsError(fieldNode.getName(), SCHEMA_TYPE_NAME);
                    self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
                    return;
                }
                foreach parser:Selection subSelection in fieldNode.getSelections() {
                    self.visitSelection(subSelection, parent);
                }
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
        __Field? schemaFieldValue = getFieldFromFieldArray(fields, requiredFieldName);
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
        string expectedTypeName = argType?.name.toString();
        parser:ArgumentValue value = argumentNode.getValue();
        if (argType.kind == ENUM) {
            self.validateEnumArgument(argType, argumentNode, schemaArg);
        } else {
            string actualTypeName = getTypeName(argumentNode);
            if (expectedTypeName == actualTypeName) {
                return;
            }
            if (expectedTypeName == FLOAT && actualTypeName == INT) {
                self.coerceInputIntToFloat(argumentNode);
                return;
            }
            string message = string`${expectedTypeName} cannot represent non ${expectedTypeName} value: ${value.value.toString()}`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, value.location);
            self.errors.push(errorDetail);
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        Parent parent = <Parent>data;
        __Type? fragmentType = getTypeFromTypeArray(self.schema.types, fragmentNode.getOnType());
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection, parent);
        }
    }

    isolated function coerceInputIntToFloat(parser:ArgumentNode argument) {
        parser:ArgumentValue argumentValue = argument.getValue();
        argumentValue.value = <float>argument.getValue().value;
    }

    isolated function getErrors() returns ErrorDetail[] {
        return self.errors;
        // TODO: Sort the error records by line and column
    }

    isolated function checkArguments(__Type parentType, parser:FieldNode fieldNode, __Field schemaField) {
        parser:ArgumentNode[] arguments = fieldNode.getArguments();
        __InputValue[]? inputValues = schemaField?.args;
        __InputValue[] notFoundInputValues = [];

        if (inputValues is ()) {
            if (arguments.length() > 0) {
                foreach parser:ArgumentNode argumentNode in arguments {
                    string argName = argumentNode.getName().value;
                    string parentName = parentType?.name is string ? <string>parentType?.name : "";
                    string message = getUnknownArgumentErrorMessage(argName, parentName, fieldNode.getName());
                    self.errors.push(getErrorDetailRecord(message, argumentNode.getName().location));
                }
            }
        } else {
            notFoundInputValues = copyInputValueArray(inputValues);
            foreach parser:ArgumentNode argumentNode in arguments {
                string argName = argumentNode.getName().value;
                __InputValue? inputValue = getInputValueFromArray(inputValues, argName);
                if (inputValue is __InputValue) {
                    _ = notFoundInputValues.remove(<int>notFoundInputValues.indexOf(inputValue));
                    self.visitArgument(argumentNode, inputValue);
                } else {
                    string parentName = parentType?.name is string ? <string>parentType?.name : "";
                    string message = getUnknownArgumentErrorMessage(argName, parentName, fieldNode.getName());
                    self.errors.push(getErrorDetailRecord(message, argumentNode.getName().location));
                }
            }
        }

        foreach __InputValue inputValue in notFoundInputValues {
            if (inputValue.'type.kind == NON_NULL && inputValue?.defaultValue is ()) {
                string message = getMissingRequiredArgError(fieldNode, inputValue);
                self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
            }
        }
    }

    isolated function validateFragment(parser:Selection fragment, string schemaTypeName) returns __Type? {
        parser:FragmentNode fragmentNode = <parser:FragmentNode>self.documentNode.getFragment(fragment.name);
        string fragmentOnTypeName = fragmentNode.getOnType();
        __Type? fragmentOnType = getTypeFromTypeArray(self.schema.types, fragmentOnTypeName);
        if (fragmentOnType is ()) {
            string message = string`Unknown type "${fragmentOnTypeName}".`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, fragment.location);
            self.errors.push(errorDetail);
        } else {
            __Type schemaType = <__Type>getTypeFromTypeArray(self.schema.types, schemaTypeName);
            __Type ofType = getOfType(schemaType);
            if (fragmentOnType != ofType) {
                string message = getFragmetCannotSpreadError(fragmentNode, fragment.name, ofType);
                ErrorDetail errorDetail = getErrorDetailRecord(message, <Location>fragment?.spreadLocation);
                self.errors.push(errorDetail);
            }
            return fragmentOnType;
        }
    }

    isolated function validateEnumArgument(__Type argType, parser:ArgumentNode argNode, __InputValue inputValue) {
        parser:ArgumentValue value = argNode.getValue();
        if (argNode.getKind() != parser:T_IDENTIFIER) {
            string message = string`Enum "${getTypeNameFromType(argType)}" cannot represent non-enum value: "${value.value}"`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, value.location);
            self.errors.push(errorDetail);
            return;
        }
       __EnumValue[] enumValues = <__EnumValue[]>argType?.enumValues;
        foreach __EnumValue enumValue in enumValues {
            if (enumValue.name == value.value) {
                return;
            }
        }
        string message = string`Value "${value.value}" does not exist in "${inputValue.name}" enum.`;
        ErrorDetail errorDetail = getErrorDetailRecord(message, value.location);
        self.errors.push(errorDetail);
    }
}

isolated function copyInputValueArray(__InputValue[] original) returns __InputValue[] {
    __InputValue[] result = [];
    foreach __InputValue inputValue in original {
        result.push(inputValue);
    }
    return result;
}

isolated function getInputValueFromArray(__InputValue[] inputValues, string name) returns __InputValue? {
    foreach __InputValue inputValue in inputValues {
        if (inputValue.name == name) {
            return inputValue;
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
        if (ofType?.name.toString() == typeName) {
            return schemaType;
        }
    }
}

isolated function hasFields(__Type fieldType) returns boolean {
    if (fieldType.kind == OBJECT || fieldType.kind == UNION) {
        return true;
    }
    return false;
}

type Parent record {
    __Type parentType;
    string name;
};
