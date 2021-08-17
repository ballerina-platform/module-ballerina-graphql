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
        __Field? schemaFieldForOperation = self.createSchemaFieldFromOperation(operationNode);
        if schemaFieldForOperation is __Field {
            foreach parser:Selection selection in operationNode.getSelections() {
                self.visitSelection(selection, schemaFieldForOperation);
            }
        }
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        __Field parentField = <__Field>data;
        __Type parentType = <__Type>getOfType(parentField.'type);
        if (parentType.kind == UNION) {
            if (!selection.isFragment) {
                string message = getInvalidFieldOnUnionTypeError(selection.name, parentType);
                self.errors.push(getErrorDetailRecord(message, selection.location));
                return;
            } else {
                parser:FragmentNode fragmentNode = <parser:FragmentNode>selection?.node;
                __Type? requiredType = getTypeFromTypeArray(<__Type[]>parentType?.possibleTypes,
                                                            fragmentNode.getOnType());
                if (requiredType is __Type) {
                    parentField = createField(requiredType?.name.toString(), requiredType);
                    self.visitFragment(fragmentNode, parentField);
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
                parentField = createField(fragmentOnType?.name.toString(), fragmentOnType);
                parser:FragmentNode fragmentNode = <parser:FragmentNode>node;
                self.visitFragment(fragmentNode, parentField);
            }
        } else {
            parser:FieldNode fieldNode = <parser:FieldNode>selection?.node;
            if (selection.name == SCHEMA_FIELD) {
                __Type schemaType = <__Type>getTypeFromTypeArray(self.schema.types, SCHEMA_TYPE_NAME);
                parentField = createField(selection.name, schemaType);
                if (fieldNode.getSelections().length() == 0) {
                    string message = getMissingSubfieldsError(fieldNode.getName(), SCHEMA_TYPE_NAME);
                    self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
                    return;
                }
                foreach parser:Selection subSelection in fieldNode.getSelections() {
                    self.visitSelection(subSelection, parentField);
                }
            } else {
                self.visitField(fieldNode, parentField);
            }
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        __Field parentField = <__Field>data;
        __Type parentType = getOfType(parentField.'type);

        __Field[] fields = parentType?.fields == () ? [] : <__Field[]>parentType?.fields;
        if (fields.length() == 0) {
            string message = getNoSubfieldsErrorMessage(parentField.name, parentType);
            self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
            return;
        }

        string requiredFieldName = fieldNode.getName();
        __Field? schemaFieldValue = getFieldFromFieldArray(fields, requiredFieldName);
        if (schemaFieldValue is ()) {
            string message = getFieldNotFoundErrorMessageFromType(requiredFieldName, parentType);
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
                    self.visitSelection(subSelection, schemaField);
                }
            } else {
                self.visitSelection(subSelection, schemaField);
            }
        }
    }

    public isolated function visitArgument(parser:InputObjectNode argumentNode, anydata data = ()) {
        __InputValue schemaArg = <__InputValue>(<map<anydata>>data).get("input");
        string fieldName = <string>(<map<anydata>>data).get("fieldName");
        __Type argType = getOfType(schemaArg.'type);
        string expectedTypeName = argType?.name.toString();
        parser:ArgumentValue|map<parser:ArgumentValue|parser:InputObjectNode> value = argumentNode.getValue();
        if isInputObject(value) {
            map<parser:ArgumentValue|parser:InputObjectNode> inputObjectValue =
                <map<parser:ArgumentValue|parser:InputObjectNode>>value;
            string actualTypeName = getTypeName(argumentNode);
            if argumentNode.isVariableDefinition() {//decimal
                if argumentNode.getVariableValue() is Scalar {
                    parser:ArgumentValue argValue = <parser:ArgumentValue>
                        {value: <Scalar>argumentNode.getVariableValue(), location: argumentNode.getLocation()};
                    self.validateArgumentValue(argValue, getTypeName(argumentNode), schemaArg);
                } else if argumentNode.getVariableValue() is map<anydata> {
                    self.validateInputObjectVariableValue(<map<anydata>>argumentNode.getVariableValue(), schemaArg,
                                                          argumentNode.getLocation(), fieldName);
                } else {
                    string message = string`${expectedTypeName} cannot represent non ${expectedTypeName} ` +
                    string`value: ${argumentNode.getVariableValue().toString()}`;
                    ErrorDetail errorDetail = getErrorDetailRecord(message, argumentNode.getLocation());
                    self.errors.push(errorDetail);
                }
            } else {
                self.visitInputObject(argumentNode, data);
            }
        } else {
            self.validateArgumentValue(<parser:ArgumentValue>value, getTypeName(argumentNode), schemaArg);
        }
    }

    isolated function visitInputObject(parser:InputObjectNode inputObjectNode, anydata data = ()) {
        __InputValue inputValue = <__InputValue>(<map<anydata>>data).get("input");
        string fieldName = <string>(<map<anydata>>data).get("fieldName");
        __Type argType = getOfType(inputValue.'type);
        string expectedTypeName = argType?.name.toString();
        __Field[] fields = <__Field[]>argType?.fields;
        map<parser:ArgumentValue|parser:InputObjectNode> inputObjectFields =
            <map<parser:ArgumentValue|parser:InputObjectNode>>inputObjectNode.getValue();
        self.validateInputObjectFields(inputObjectNode, fields);
        foreach __Field 'field in fields {
            __Type subArgType = getOfType('field.'type);
            expectedTypeName = subArgType?.name.toString();
            __InputValue subInputValue = <__InputValue> getInputValueFromArray('field?.args, 'field.name);
            if inputObjectFields.hasKey('field.name) {
                parser:ArgumentValue|parser:InputObjectNode fieldValue = inputObjectFields.get('field.name);
                if fieldValue is parser:InputObjectNode {
                    self.visitArgument(fieldValue, {input:subInputValue, fieldName:fieldName});
                } else {
                    self.validateArgumentValue(fieldValue, getTypeNameFromValue(fieldValue.value), subInputValue);
                }
            } else {
                if ((subInputValue.'type).kind == NON_NULL && inputValue?.defaultValue is ()) {
                    string message = string`Field "${fieldName}" argument "${subInputValue.name}" of type ` +
                    string`"${getTypeNameFromType(subInputValue.'type)}" is required, but it was not provided.`;
                    self.errors.push(getErrorDetailRecord(message, inputObjectNode.getLocation()));
                }
            }
        }
    }

    isolated function validateArgumentValue(parser:ArgumentValue value, string actualTypeName, __InputValue schemaArg) {
        __Type argType = getOfType(schemaArg.'type);
        string expectedTypeName = argType?.name.toString();
        if argType.kind == ENUM {
            self.validateEnumArgument(argType, value, actualTypeName, schemaArg);
        } else {
            if (expectedTypeName == actualTypeName) {
                return;
            }
            if (expectedTypeName == FLOAT && actualTypeName == INT) {
                self.coerceInputIntToFloat(value);
                return;
            }
            string message = string`${expectedTypeName} cannot represent non ${expectedTypeName} value: ` +
            string`${(<parser:ArgumentValue>value).value.toString()}`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, (<parser:ArgumentValue>value).location);
            self.errors.push(errorDetail);
        }
    }

    isolated function validateInputObjectVariableValue(map<anydata> value, __InputValue inputValue, Location location,
                                                       string fieldName) {
        __Type argType = getOfType(inputValue.'type);
        __Field[] fields = <__Field[]>argType?.fields;
        string expectedTypeName = argType?.name.toString();
        foreach __Field 'field in fields {
            __Type subArgType = getOfType('field.'type);
            expectedTypeName = subArgType?.name.toString();
            __InputValue subInputValue = <__InputValue> getInputValueFromArray('field?.args, 'field.name);
            if value.hasKey('field.name) {
                anydata fieldValue = value.get('field.name);
                if fieldValue is Scalar {
                    parser:ArgumentValue argValue = {value: <Scalar>fieldValue, location: location};
                    if subArgType.kind == ENUM {
                        self.validateEnumArgument(getOfType(subInputValue.'type), argValue, argType.kind,
                                                  subInputValue);
                    } else {
                        string actualTypeName = getTypeNameFromValue(fieldValue);
                        self.validateArgumentValue(argValue, actualTypeName, subInputValue);
                    }
                } else if fieldValue is decimal {
                    if expectedTypeName == FLOAT {
                        parser:ArgumentValue argValue = {value: <float>fieldValue, location: location};
                        self.validateArgumentValue(argValue, getTypeNameFromValue(fieldValue), subInputValue);
                    } else {
                        string message = string`${expectedTypeName} cannot represent non ${expectedTypeName} value: `+
                        string`${fieldValue.toString()}`;
                        ErrorDetail errorDetail = getErrorDetailRecord(message, location);
                        self.errors.push(errorDetail);
                    }
                } else if fieldValue is map<anydata> {
                    self.validateInputObjectVariableValue(<map<anydata>>fieldValue, subInputValue, location, fieldName);
                } else {
                    string message = string`${expectedTypeName} cannot represent non ${expectedTypeName} value: `+
                    string`${fieldValue.toString()}`;
                    ErrorDetail errorDetail = getErrorDetailRecord(message, location);
                    self.errors.push(errorDetail);
                }
            } else {
                if ((subInputValue.'type).kind == NON_NULL && inputValue?.defaultValue is ()) {
                    string message = string`Field "${fieldName}" argument "${subInputValue.name}" of type `+
                    string`"${getTypeNameFromType(subInputValue.'type)}" is required, but it was not provided.`;
                    self.errors.push(getErrorDetailRecord(message, location));
                }
            }
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        __Field parentField = <__Field>data;
        __Type? fragmentType = getTypeFromTypeArray(self.schema.types, fragmentNode.getOnType());
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection, parentField);
        }
    }

    isolated function coerceInputIntToFloat(parser:ArgumentValue argument) {
        argument.value = <float>argument.value;
    }

    isolated function coerceInputVariableIntToFloat(string name, map<anydata> value) {
        value[name] = <float>value.get(name);
    }

    isolated function getErrors() returns ErrorDetail[] {
        return self.errors;
    }

    isolated function checkArguments(__Type parentType, parser:FieldNode fieldNode, __Field schemaField) {
        parser:InputObjectNode[] arguments = fieldNode.getArguments();
        __InputValue[]? inputValues = schemaField?.args;
        __InputValue[] notFoundInputValues = [];

        if (inputValues is ()) {
            if (arguments.length() > 0) {
                foreach parser:InputObjectNode argumentNode in arguments {
                    string argName = argumentNode.getName();
                    string parentName = parentType?.name is string ? <string>parentType?.name : "";
                    string message = getUnknownArgumentErrorMessage(argName, parentName, fieldNode.getName());
                    self.errors.push(getErrorDetailRecord(message, argumentNode.getLocation()));
                }
            }
        } else {
            notFoundInputValues = copyInputValueArray(inputValues);
            foreach parser:InputObjectNode argumentNode in arguments {
                string argName = argumentNode.getName();
                __InputValue? inputValue = getInputValueFromArray(inputValues, argName);
                if (inputValue is __InputValue) {
                    _ = notFoundInputValues.remove(<int>notFoundInputValues.indexOf(inputValue));
                    self.visitArgument(argumentNode, {input:inputValue, fieldName:fieldNode.getName()});
                } else {
                    string parentName = parentType?.name is string ? <string>parentType?.name : "";
                    string message = getUnknownArgumentErrorMessage(argName, parentName, fieldNode.getName());
                    self.errors.push(getErrorDetailRecord(message, argumentNode.getLocation()));
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

    isolated function validateInputObjectFields(parser:InputObjectNode node, __Field[] schemaFields) {
        map<parser:ArgumentValue|parser:InputObjectNode> inputObjectFields =
            <map<parser:ArgumentValue|parser:InputObjectNode>>node.getValue();
        string[] undefinedFields = inputObjectFields.keys();
        foreach __Field fields in schemaFields {
            if !(undefinedFields.indexOf(fields.name) is ()) {
                _ = undefinedFields.remove(<int>undefinedFields.indexOf(fields.name));
            }
        }
        foreach string name in undefinedFields {
            string message = string`Field "${name}" is not defined by type "${node.getName()}".`;
            parser:ArgumentValue|parser:InputObjectNode fieldValue = inputObjectFields.get(name);
            if fieldValue is parser:ArgumentValue {
                self.errors.push(getErrorDetailRecord(message, fieldValue.location));
            } else {
                self.errors.push(getErrorDetailRecord(message, fieldValue.getLocation()));
            }
        }
    }

    isolated function validateEnumArgument(__Type argType, parser:ArgumentValue value, string actualArgType,
                                           __InputValue inputValue) {
        if (getArgumentTypeKind(actualArgType) != parser:T_IDENTIFIER) {
            string message = string`Enum "${getTypeNameFromType(argType)}" cannot represent non-enum value: `+
            string`"${value.value}"`;
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

    isolated function createSchemaFieldFromOperation(parser:OperationNode operationNode) returns __Field? {
        parser:RootOperationType operationType = operationNode.getKind();
        string operationTypeName = getOperationTypeNameFromOperationType(operationType);
        __Type? 'type = getTypeFromTypeArray(self.schema.types, operationTypeName);
        if 'type == () {
            string message = string`Schema is not configured for ${operationType.toString()}s.`;
            self.errors.push(getErrorDetailRecord(message, operationNode.getLocation()));
        } else {
            return createField(operationTypeName, 'type);
        }
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

isolated function isInputObject(parser:ArgumentValue|map<parser:ArgumentValue|parser:InputObjectNode> argument)
    returns boolean {
    if argument is map<parser:ArgumentValue|parser:InputObjectNode> {
        return true;
    }
    return false;
}

isolated function getOperationTypeNameFromOperationType(parser:RootOperationType rootOperationType) returns string {
    match rootOperationType {
        parser:MUTATION => {
            return MUTATION_TYPE_NAME;
        }
        parser:SUBSCRIPTION => {
            return SUBSCRIPTION_TYPE_NAME;
        }
        _ => {
            return QUERY_TYPE_NAME;
        }
    }
}

isolated function createField(string fieldName, __Type fieldType) returns __Field {
    return {
        name: fieldName,
        'type: fieldType,
        args: []
    };
}
