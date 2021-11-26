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

    private final __Schema schema;
    private final parser:DocumentNode documentNode;
    private ErrorDetail[] errors;
    private map<string> usedFragments;
    private __Directive[] defaultDirectives;

    isolated function init(__Schema schema, parser:DocumentNode documentNode) {
        self.schema = schema;
        self.documentNode = documentNode;
        self.errors = [];
        self.usedFragments = {};
        self.defaultDirectives = schema.directives;
    }

    public isolated function validate() returns ErrorDetail[]? {
        self.visitDocument(self.documentNode);
        if (self.errors.length() > 0) {
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
        __Field? schemaFieldForOperation =
            createSchemaFieldFromOperation(self.schema.types, operationNode, self.errors);
        self.validateDirectiveArguments(operationNode);
        if schemaFieldForOperation is __Field {
            foreach parser:Selection selection in operationNode.getSelections() {
                self.visitSelection(selection, schemaFieldForOperation);
            }
        }
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        __Field parentField = <__Field>data;
        __Type parentType = <__Type>getOfType(parentField.'type);
        if parentType.kind == UNION {
            self.validateUnionTypeField(selection, parentType, parentField);
            return;
        }
        if selection is parser:FragmentNode {
            __Type? fragmentOnType = self.validateFragment(selection, <string>parentType.name);
            if fragmentOnType is __Type {
                parentField = createField(fragmentOnType.name.toString(), fragmentOnType);
                self.visitFragment(selection, parentField);
            }
        } else {
            self.visitField(selection, parentField);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        __Field parentField = <__Field>data;
        __Type parentType = getOfType(parentField.'type);
        __Field? requiredFieldValue = getRequierdFieldFromType(parentType, self.schema.types, fieldNode);
        if requiredFieldValue is () {
            string message = getFieldNotFoundErrorMessageFromType(fieldNode.getName(), parentType);
            self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
            return;
        }
        __Field requiredField = <__Field>requiredFieldValue;
        __Type fieldType = getOfType(requiredField.'type);
        self.checkArguments(parentType, fieldNode, requiredField);
        self.validateDirectiveArguments(fieldNode);
        if !hasFields(fieldType) && fieldNode.getSelections().length() == 0 {
            return;
        } else if !hasFields(fieldType) && fieldNode.getSelections().length() > 0 {
            string message = getNoSubfieldsErrorMessage(requiredField);
            self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
            return;
        } else if hasFields(fieldType) && fieldNode.getSelections().length() == 0 {
            // TODO: The location of this error should be the location of open brace after the field node.
            // Currently, we use the field location for this.
            string message = getMissingSubfieldsErrorFromType(requiredField);
            self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
            return;
        } else {
            foreach parser:Selection selection in fieldNode.getSelections() {
                self.visitSelection(selection, requiredField);
            }
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        __InputValue schemaArg = <__InputValue>(<map<anydata>>data).get("input");
        string fieldName = <string>(<map<anydata>>data).get("fieldName");
        if argumentNode.isVariableDefinition() {
            self.validateVariableValue(argumentNode, schemaArg, fieldName);
        } else if argumentNode.getKind() == parser:T_INPUT_OBJECT {
            self.visitInputObject(argumentNode, schemaArg, fieldName);
        } else {
            parser:ArgumentValue|parser:ArgumentNode fieldValue = argumentNode.getValue().get(schemaArg.name);
            if fieldValue is parser:ArgumentValue {
                self.validateArgumentValue(fieldValue, getTypeName(argumentNode), schemaArg);
            }
        }
    }

    isolated function visitInputObject(parser:ArgumentNode argumentNode, __InputValue schemaArg, string fieldName) {
        __Type argType = getOfType(schemaArg.'type);
        __InputValue[]? inputFields = argType?.inputFields;
        if inputFields is __InputValue[] {
            self.validateInputObjectFields(argumentNode, inputFields);
            foreach __InputValue inputField in inputFields {
                __InputValue subInputValue = inputField;
                if argumentNode.getValue().hasKey(inputField.name) {
                    parser:ArgumentValue|parser:ArgumentNode fieldValue = argumentNode.getValue().get(inputField.name);
                    if fieldValue is parser:ArgumentNode {
                        self.visitArgument(fieldValue, {input:subInputValue, fieldName:fieldName});
                    }
                } else {
                    if ((subInputValue.'type).kind == NON_NULL && schemaArg?.defaultValue is ()) {
                        string message = string`Field "${fieldName}" argument "${subInputValue.name}" of type ` +
                        string`"${getTypeNameFromType(subInputValue.'type)}" is required, but it was not provided.`;
                        self.errors.push(getErrorDetailRecord(message, argumentNode.getLocation()));
                    }
                }
            }
        } else {
            string expectedTypeName = getOfType(schemaArg.'type).name.toString();
            string message = string`${expectedTypeName} cannot represent non ${expectedTypeName} value: {}`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, argumentNode.getLocation());
            self.errors.push(errorDetail);
        }
    }

    isolated function validateVariableValue(parser:ArgumentNode argumentNode, __InputValue schemaArg, string fieldName) {
        anydata variableValue = argumentNode.getVariableValue();
        if variableValue is Scalar {
            parser:ArgumentValue argValue =
                <parser:ArgumentValue> {value: variableValue, location: argumentNode.getLocation()};
            self.validateArgumentValue(argValue, getTypeName(argumentNode), schemaArg);
        } else if variableValue is map<anydata> {
            self.validateInputObjectVariableValue(variableValue, schemaArg, argumentNode.getLocation(), fieldName);
        } else {
            string expectedTypeName = getOfType(schemaArg.'type).name.toString();
            string message = string`${expectedTypeName} cannot represent non ${expectedTypeName} ` +
            string`value: ${variableValue.toString()}`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, argumentNode.getLocation());
            self.errors.push(errorDetail);
        }
    }

    isolated function validateArgumentValue(parser:ArgumentValue value, string actualTypeName, __InputValue schemaArg) {
        if value.value == () {
            if schemaArg.'type.kind == NON_NULL {
                string message = string`Expected value of type "${getTypeNameFromType(schemaArg.'type)}", found null.`;
                ErrorDetail errorDetail = getErrorDetailRecord(message, value.location);
                self.errors.push(errorDetail);
            }
            return;
        }
        if getOfType(schemaArg.'type).kind == ENUM {
            self.validateEnumArgument(value, actualTypeName, schemaArg);
        } else {
            string expectedTypeName = getOfType(schemaArg.'type).name.toString();
            if (expectedTypeName == actualTypeName) {
                return;
            }
            if (expectedTypeName == FLOAT && actualTypeName == INT) {
                self.coerceInputIntToFloat(value);
                return;
            }
            string message = string`${expectedTypeName} cannot represent non ${expectedTypeName} value: ${value.value.toString()}`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, value.location);
            self.errors.push(errorDetail);
        }
    }

    isolated function validateInputObjectVariableValue(map<anydata> variableValues, __InputValue inputValue,
                                                       Location location, string fieldName) {
        __Type argType = getOfType(inputValue.'type);
        __InputValue[]? inputFields = argType?.inputFields;
        if inputFields is __InputValue[] {
            foreach __InputValue subInputValue in inputFields {
                if variableValues.hasKey(subInputValue.name) {
                    anydata fieldValue = variableValues.get(subInputValue.name);
                    if fieldValue is Scalar {
                        parser:ArgumentValue argValue = {value: fieldValue, location: location};
                        if getOfType(subInputValue.'type).kind == ENUM {
                            //validate input object field with enum value
                            self.validateEnumArgument(argValue, ENUM, subInputValue);
                        } else {
                            self.validateArgumentValue(argValue, getTypeNameFromValue(fieldValue), subInputValue);
                        }
                    } else if fieldValue is decimal {
                        //coerce decimal to float since float value change over the network
                        self.coerceInputVariableDecimalToFloat(fieldValue, subInputValue, location);
                    } else if fieldValue is map<anydata> {
                        self.validateInputObjectVariableValue(fieldValue, subInputValue, location, fieldName);
                    }
                } else {
                    if ((subInputValue.'type).kind == NON_NULL && inputValue?.defaultValue is ()) {
                        string message = string`Field "${fieldName}" argument "${subInputValue.name}" of type `+
                        string`"${getTypeNameFromType(subInputValue.'type)}" is required, but it was not provided.`;
                        self.errors.push(getErrorDetailRecord(message, location));
                    }
                }
            }
        } else {
            string expectedTypeName = getOfType(inputValue.'type).name.toString();
            string message = string`${expectedTypeName} cannot represent non ${expectedTypeName} value: {}`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, location);
            self.errors.push(errorDetail);
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        self.validateDirectiveArguments(fragmentNode);
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection, data);
        }
    }

    isolated function validateUnionTypeField(parser:Selection selection, __Type parentType, __Field parentField) {
        if selection is parser:FieldNode {
            __Field? subField = getRequierdFieldFromType(parentType, self.schema.types, selection);
            if subField is __Field {
                self.visitField(selection, subField);
            } else {
                string message = getInvalidFieldOnUnionTypeError(selection.getAlias(), parentType);
                self.errors.push(getErrorDetailRecord(message, selection.getLocation()));
            }
        } else {
            __Type? requiredType = getTypeFromTypeArray(<__Type[]>parentType?.possibleTypes, selection.getOnType());
            if requiredType is __Type {
                __Field subField = createField(parentField.name, requiredType);
                self.visitFragment(selection, subField);
            } else {
                string message = getFragmetCannotSpreadError(selection, selection.getName(), parentType);
                self.errors.push(getErrorDetailRecord(message, <Location>selection.getSpreadLocation()));
            }
        }
    }

    isolated function coerceInputIntToFloat(parser:ArgumentValue argument) {
        argument.value = <float>argument.value;
    }

    isolated function coerceInputVariableDecimalToFloat(decimal value, __InputValue inputValue, Location location) {
        string expectedTypeName = getOfType(inputValue.'type).name.toString();
        if expectedTypeName == FLOAT {
            parser:ArgumentValue argValue = {value: <float>value, location: location};
            self.validateArgumentValue(argValue, FLOAT, inputValue);
        } else {
            string message = string`${expectedTypeName} cannot represent non ${expectedTypeName} value: `+
            string`${value.toString()}`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, location);
            self.errors.push(errorDetail);
        }
    }

    isolated function coerceInputVariableIntToFloat(string name, map<anydata> inputValues) {
        inputValues[name] = <float>inputValues.get(name);
    }

    isolated function getErrors() returns ErrorDetail[] {
        return self.errors;
    }

    isolated function checkArguments(__Type parentType, parser:FieldNode fieldNode, __Field schemaField) {
        parser:ArgumentNode[] arguments = fieldNode.getArguments();
        __InputValue[] inputValues = schemaField.args;
        __InputValue[] notFoundInputValues = [];
        if inputValues.length() == 0 {
            if arguments.length() > 0 {
                foreach parser:ArgumentNode argumentNode in arguments {
                    string argName = argumentNode.getName();
                    string parentName = parentType.name is string ? <string>parentType.name : "";
                    string message = getUnknownArgumentErrorMessage(argName, parentName, fieldNode.getName());
                    self.errors.push(getErrorDetailRecord(message, argumentNode.getLocation()));
                }
            }
        } else {
            notFoundInputValues = copyInputValueArray(inputValues);
            foreach parser:ArgumentNode argumentNode in arguments {
                string argName = argumentNode.getName();
                __InputValue? inputValue = getInputValueFromArray(inputValues, argName);
                if inputValue is __InputValue {
                    _ = notFoundInputValues.remove(<int>notFoundInputValues.indexOf(inputValue));
                    self.visitArgument(argumentNode, {input:inputValue, fieldName:fieldNode.getName()});
                } else {
                    string parentName = parentType.name is string ? <string>parentType.name : "";
                    string message = getUnknownArgumentErrorMessage(argName, parentName, fieldNode.getName());
                    self.errors.push(getErrorDetailRecord(message, argumentNode.getLocation()));
                }
            }
        }

        foreach __InputValue inputValue in notFoundInputValues {
            if inputValue.'type.kind == NON_NULL && inputValue?.defaultValue is () {
                string message = getMissingRequiredArgError(fieldNode, inputValue);
                self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
            }
        }
    }

    isolated function validateFragment(parser:FragmentNode fragmentNode, string schemaTypeName) returns __Type? {
        string fragmentOnTypeName = fragmentNode.getOnType();
        __Type? fragmentOnType = getTypeFromTypeArray(self.schema.types, fragmentOnTypeName);
        if (fragmentOnType is ()) {
            string message = string`Unknown type "${fragmentOnTypeName}".`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, fragmentNode.getLocation());
            self.errors.push(errorDetail);
        } else {
            __Type schemaType = <__Type>getTypeFromTypeArray(self.schema.types, schemaTypeName);
            __Type ofType = getOfType(schemaType);
            if (fragmentOnType != ofType) {
                string message = getFragmetCannotSpreadError(fragmentNode, fragmentNode.getName(), ofType);
                ErrorDetail errorDetail = getErrorDetailRecord(message, <Location> fragmentNode.getSpreadLocation());
                self.errors.push(errorDetail);
            }
            return fragmentOnType;
        }
        return;
    }

    isolated function validateInputObjectFields(parser:ArgumentNode node, __InputValue[] schemaFields) {
        map<parser:ArgumentValue|parser:ArgumentNode> inputObjectFields = node.getValue();
        string[] undefinedFields = inputObjectFields.keys();
        foreach __InputValue fields in schemaFields {
            int? index = undefinedFields.indexOf(fields.name);
            if index is int {
                _ = undefinedFields.remove(index);
            }
        }
        foreach string name in undefinedFields {
            string message = string`Field "${name}" is not defined by type "${node.getName()}".`;
            parser:ArgumentValue|parser:ArgumentNode fieldValue = inputObjectFields.get(name);
            if fieldValue is parser:ArgumentNode {
                self.errors.push(getErrorDetailRecord(message, fieldValue.getLocation()));
            }
        }
    }

    isolated function validateEnumArgument(parser:ArgumentValue value, string actualArgType, __InputValue inputValue) {
        __Type argType = getOfType(inputValue.'type);
        if (getArgumentTypeKind(actualArgType) != parser:T_IDENTIFIER) {
            string message = string`Enum "${getTypeNameFromType(argType)}" cannot represent non-enum value: `+
            string`"${value.value.toString()}"`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, value.location);
            self.errors.push(errorDetail);
            return;
        }
        __EnumValue[] enumValues = <__EnumValue[]> argType?.enumValues;
        foreach __EnumValue enumValue in enumValues {
            if (enumValue.name == value.value) {
                return;
            }
        }
        string message = string`Value "${value.value.toString()}" does not exist in "${inputValue.name}" enum.`;
        ErrorDetail errorDetail = getErrorDetailRecord(message, value.location);
        self.errors.push(errorDetail);
    }

    isolated function validateDirectiveArguments(parser:ParentNode node) {
        foreach parser:DirectiveNode directive in node.getDirectives() {
            foreach __Directive defaultDirective in self.defaultDirectives {
                if directive.getName() == defaultDirective.name {
                    __InputValue[] notFoundInputValues = copyInputValueArray(defaultDirective.args);
                    foreach parser:ArgumentNode argumentNode in directive.getArguments() {
                        string argName = argumentNode.getName();
                        __InputValue? inputValue = getInputValueFromArray(defaultDirective.args, argName);
                        if inputValue is __InputValue {
                            _ = notFoundInputValues.remove(<int>notFoundInputValues.indexOf(inputValue));
                            self.visitArgument(argumentNode, {input:inputValue, fieldName:directive.getName()});
                        } else {
                            string message = string`Unknown argument "${argName}" on directive` +
                            string`"${directive.getName()}".`;
                            self.errors.push(getErrorDetailRecord(message, argumentNode.getLocation()));
                        }
                    }
                    foreach __InputValue arg in notFoundInputValues {
                        string message = string`Directive "${directive.getName()}" argument "${arg.name}" of type` +
                        string`"${getTypeNameFromType(arg.'type)}" is required but not provided.`;
                        self.errors.push(getErrorDetailRecord(message, directive.getLocation()));
                    }
                    break;
                }
            }
        }
    }

}

isolated function createSchemaFieldFromOperation(__Type[] typeArray, parser:OperationNode operationNode,
                                                 ErrorDetail[] errors) returns __Field? {
    parser:RootOperationType operationType = operationNode.getKind();
    string operationTypeName = getOperationTypeNameFromOperationType(operationType);
    __Type? 'type = getTypeFromTypeArray(typeArray, operationTypeName);
    if 'type == () {
        string message = string`Schema is not configured for ${operationType.toString()}s.`;
        errors.push(getErrorDetailRecord(message, operationNode.getLocation()));
    } else {
        return createField(operationTypeName, 'type);
    }
    return;
}

isolated function getRequierdFieldFromType(__Type parentType, __Type[] typeArray,
                                           parser:FieldNode fieldNode) returns __Field? {
    __Field[] fields = getFieldsArrayFromType(parentType);
    __Field? requiredField = getFieldFromFieldArray(fields, fieldNode.getName());
    if requiredField is () {
        if fieldNode.getName() == SCHEMA_FIELD && parentType.name == QUERY_TYPE_NAME {
            __Type fieldType = <__Type>getTypeFromTypeArray(typeArray, SCHEMA_TYPE_NAME);
            requiredField = createField(SCHEMA_FIELD, fieldType);
        } else if fieldNode.getName() == TYPE_FIELD && parentType.name == QUERY_TYPE_NAME {
            __Type fieldType = <__Type>getTypeFromTypeArray(typeArray, TYPE_TYPE_NAME);
            __Type argumentType = <__Type>getTypeFromTypeArray(typeArray, STRING);
            __Type wrapperType = { kind: NON_NULL, ofType: argumentType };
            __InputValue[] args = [{ name: NAME_ARGUMENT, 'type: wrapperType }];
            requiredField = createField(TYPE_FIELD, fieldType, args);
        } else if fieldNode.getName() == TYPE_NAME_FIELD {
            __Type ofType = <__Type>getTypeFromTypeArray(typeArray, STRING);
            __Type wrappingType = { kind: NON_NULL, ofType: ofType };
            requiredField = createField(TYPE_NAME_FIELD, wrappingType);
        }
    }
    return requiredField;
}

isolated function getFieldFromFieldArray(__Field[] fields, string fieldName) returns __Field? {
    foreach __Field schemaField in fields {
        if schemaField.name == fieldName {
            return schemaField;
        }
    }
    return;
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
        if inputValue.name == name {
            return inputValue;
        }
    }
    return;
}

isolated function getTypeFromTypeArray(__Type[] types, string typeName) returns __Type? {
    foreach __Type schemaType in types {
        __Type ofType = getOfType(schemaType);
        if ofType.name.toString() == typeName {
            return ofType;
        }
    }
    return;
}

isolated function hasFields(__Type fieldType) returns boolean {
    if fieldType.kind == OBJECT || fieldType.kind == UNION {
        return true;
    }
    return false;
}

isolated function getOperationTypeNameFromOperationType(parser:RootOperationType rootOperationType) returns string {
    match rootOperationType {
        parser:OPERATION_MUTATION => {
            return MUTATION_TYPE_NAME;
        }
        parser:OPERATION_SUBSCRIPTION => {
            return SUBSCRIPTION_TYPE_NAME;
        }
        _ => {
            return QUERY_TYPE_NAME;
        }
    }
}

isolated function createField(string fieldName, __Type fieldType, __InputValue[] args = []) returns __Field {
    return {
        name: fieldName,
        'type: fieldType,
        args: args
    };
}

isolated function getFieldsArrayFromType(__Type 'type) returns __Field[] {
    __Field[]? fields = 'type?.fields;
    return fields == () ? [] : fields;
}
