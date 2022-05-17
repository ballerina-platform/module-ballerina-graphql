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
    private (string|int)[] argumentPath;

    isolated function init(__Schema schema, parser:DocumentNode documentNode) {
        self.schema = schema;
        self.documentNode = documentNode;
        self.errors = [];
        self.usedFragments = {};
        self.argumentPath = [];
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
        __Field? operationField = createSchemaFieldFromOperation(self.schema.types, operationNode, self.errors);
        self.validateDirectiveArguments(operationNode);
        if operationField is __Field {
            foreach parser:Selection selection in operationNode.getSelections() {
                self.visitSelection(selection, operationField);
            }
        }
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        __Field parentField = <__Field>data;
        __Type parentType = <__Type>getOfType(parentField.'type);
        if selection is parser:FragmentNode {
            __Type? fragmentOnType = self.validateFragment(selection, <string>parentType.name);
            if fragmentOnType is __Type {
                parentField = createField(getOfTypeName(fragmentOnType), fragmentOnType);
                self.visitFragment(selection, parentField);
            }
        } else if selection is parser:FieldNode {
            self.visitField(selection, parentField);
        } else {
            panic error("Invalid selection node passed.");
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
            argumentNode.setKind(getArgumentTypeIdentifierFromType(schemaArg.'type));
        } else if argumentNode.getKind() == parser:T_INPUT_OBJECT {
            self.visitInputObject(argumentNode, schemaArg, fieldName);
        } else if argumentNode.getKind() == parser:T_LIST {
            self.visitListValue(argumentNode, schemaArg, fieldName);
        } else {
            parser:ArgumentValue|parser:ArgumentValue[] fieldValue = argumentNode.getValue();
            if fieldValue is parser:ArgumentValue {
                self.coerceArgumentNodeValue(argumentNode, schemaArg);
                self.validateArgumentValue(fieldValue, argumentNode.getValueLocation(), getTypeName(argumentNode),
                                           schemaArg);
            }
        }
    }

    isolated function visitInputObject(parser:ArgumentNode argumentNode, __InputValue schemaArg, string fieldName) {
        __Type argType = getOfType(schemaArg.'type);
        __InputValue[]? inputFields = argType?.inputFields;
        if inputFields is __InputValue[] && getTypeKind(schemaArg.'type) == INPUT_OBJECT {
            self.updatePath(argumentNode.getName());
            parser:ArgumentValue[] fields = <parser:ArgumentValue[]>argumentNode.getValue();
            self.validateInputObjectFields(argumentNode, inputFields);
            foreach __InputValue inputField in inputFields {
                self.updatePath(inputField.name);
                __InputValue subInputValue = inputField;
                boolean isProvidedField = false;
                foreach parser:ArgumentValue fieldValue in fields {
                    if fieldValue is parser:ArgumentNode && fieldValue.getName() == inputField.name {
                        self.visitArgument(fieldValue, {input: subInputValue, fieldName: fieldName});
                        isProvidedField = true;
                    }
                }
                if !isProvidedField {
                    if subInputValue.'type.kind == NON_NULL && schemaArg?.defaultValue is () {
                        string inputFieldName = getInputObjectFieldFormPath(self.argumentPath, subInputValue.name);
                        string message = string `Field "${inputFieldName}" of required type ` +
                                         string `"${getTypeNameFromType(subInputValue.'type)}" was not provided.`;
                        self.errors.push(getErrorDetailRecord(message, argumentNode.getLocation()));
                    }
                }
                self.removePath();
            }
            self.removePath();
        } else {
            string listError = getListElementError(self.argumentPath);
            string message = getInvalidArgumentValueError(listError, getTypeNameFromType(schemaArg.'type), argumentNode);
            ErrorDetail errorDetail = getErrorDetailRecord(message, argumentNode.getLocation());
            self.errors.push(errorDetail);
        }
    }

    isolated function visitListValue(parser:ArgumentNode argumentNode, __InputValue schemaArg, string fieldName) {
        self.updatePath(argumentNode.getName());
        if getTypeKind(schemaArg.'type) == LIST {
            parser:ArgumentValue|parser:ArgumentValue[] listItems = argumentNode.getValue();
            if listItems is parser:ArgumentValue[] {
                __InputValue listItemInputValue = createInputValueForListItem(schemaArg);
                if listItems.length() > 0 {
                    foreach int i in 0..< listItems.length() {
                        parser:ArgumentValue|parser:ArgumentValue[] item = listItems[i];
                        if item is parser:ArgumentNode {
                            self.updatePath(i);
                            self.visitArgument(item, {input: listItemInputValue, fieldName: fieldName});
                            self.removePath();
                        }
                    }
                } else if listItemInputValue.'type.kind == NON_NULL {
                    string expectedTypeName = getTypeNameFromType(schemaArg.'type);
                    string message = string `${expectedTypeName} cannot represent non ${expectedTypeName} value: []`;
                    ErrorDetail errorDetail = getErrorDetailRecord(message, argumentNode.getValueLocation());
                    self.errors.push(errorDetail);
                }
            } else if schemaArg.'type.kind == NON_NULL {
                string expectedTypeName = getTypeNameFromType(schemaArg.'type);
                string message = string `${expectedTypeName} cannot represent non ${expectedTypeName} value: null`;
                ErrorDetail errorDetail = getErrorDetailRecord(message, argumentNode.getValueLocation());
                self.errors.push(errorDetail);
            }
        } else {
            string listError = getListElementError(self.argumentPath);
            string message = getInvalidArgumentValueError(listError, getTypeNameFromType(schemaArg.'type), argumentNode);
            ErrorDetail errorDetail = getErrorDetailRecord(message, argumentNode.getLocation());
            self.errors.push(errorDetail);
        }
        self.removePath();
    }

    isolated function validateVariableValue(parser:ArgumentNode argumentNode, __InputValue schemaArg, string fieldName) {
        anydata variableValue = argumentNode.getVariableValue();
        if getOfType(schemaArg.'type).name == UPLOAD {
            return;
        } else if variableValue is Scalar && (getTypeKind(schemaArg.'type) == SCALAR || getTypeKind(schemaArg.'type) == ENUM) {
            self.coerceArgumentNodeValue(argumentNode, schemaArg);
            self.validateArgumentValue(variableValue, argumentNode.getValueLocation(), getTypeName(argumentNode), schemaArg);
        } else if variableValue is map<anydata> && getTypeKind(schemaArg.'type) == INPUT_OBJECT {
            self.updatePath(argumentNode.getName());
            self.validateInputObjectVariableValue(variableValue, schemaArg, argumentNode.getValueLocation(), fieldName);
            self.removePath();
        } else if variableValue is anydata[] && getTypeKind(schemaArg.'type) == LIST {
            self.updatePath(argumentNode.getName());
            self.validateListVariableValue(variableValue, schemaArg, argumentNode.getValueLocation(), fieldName);
            self.removePath();
        } else if variableValue is () {
            self.validateArgumentValue(variableValue, argumentNode.getValueLocation(), getTypeName(argumentNode), schemaArg);
        } else {
            string expectedTypeName = getOfTypeName(schemaArg.'type);
            string listError = getListElementError(self.argumentPath);
            string value = variableValue is () ? "null" : variableValue.toString();
            string message = string`${listError}${expectedTypeName} cannot represent non ${expectedTypeName} value:` +
                             string` ${value}`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, argumentNode.getValueLocation());
            self.errors.push(errorDetail);
        }
    }

    isolated function validateArgumentValue(parser:ArgumentValue value, Location valueLocation, string actualTypeName,
                                            __InputValue schemaArg) {
        if value is () {
            if schemaArg.'type.kind == NON_NULL {
                string listError = getListElementError(self.argumentPath);
                string message = string `${listError}Expected value of type "${getTypeNameFromType(schemaArg.'type)}"` +
                                 string `, found null.`;
                ErrorDetail errorDetail = getErrorDetailRecord(message, valueLocation);
                self.errors.push(errorDetail);
            }
            return;
        }
        if getTypeKind(schemaArg.'type) == ENUM {
            self.validateEnumArgument(value, valueLocation, actualTypeName, schemaArg);
        } else if getTypeKind(schemaArg.'type) == SCALAR {
            string expectedTypeName = getOfTypeName(schemaArg.'type);
            if expectedTypeName == actualTypeName {
                return;
            }
            if (expectedTypeName == FLOAT || expectedTypeName == DECIMAL) && value is int|float|decimal {
                return;
            }
            string listError = getListElementError(self.argumentPath);
            string message = string `${listError}${expectedTypeName} cannot represent non ${expectedTypeName} value: ` +
                             string `${value.toString()}`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, valueLocation);
            self.errors.push(errorDetail);
        } else {
            string listError = getListElementError(self.argumentPath);
            string message = getInvalidArgumentValueError(listError, getTypeNameFromType(schemaArg.'type), value);
            ErrorDetail errorDetail = getErrorDetailRecord(message, valueLocation);
            self.errors.push(errorDetail);
        }
    }

    isolated function validateInputObjectVariableValue(map<anydata> variableValues, __InputValue inputValue,
                                                       Location location, string fieldName) {
        __Type argType = getOfType(inputValue.'type);
        __InputValue[]? inputFields = argType?.inputFields;
        if inputFields is __InputValue[] {
            foreach __InputValue subInputValue in inputFields {
                if getOfType(subInputValue.'type).name == UPLOAD {
                    return;
                }
                if variableValues.hasKey(subInputValue.name) {
                    anydata fieldValue = variableValues.get(subInputValue.name);
                    if fieldValue is Scalar {
                        if getOfType(subInputValue.'type).kind == ENUM {
                            //validate input object field with enum value
                            self.validateEnumArgument(fieldValue, location, ENUM, subInputValue);
                        } else {
                            string expectedTypeName = getOfTypeName(subInputValue.'type);
                            string actualTypeName = getTypeNameFromValue(fieldValue);
                            variableValues[subInputValue.name] = self.coerceValue(fieldValue, expectedTypeName,
                                                                                  actualTypeName, location);
                            self.validateArgumentValue(fieldValue, location, getTypeNameFromValue(fieldValue),
                                                       subInputValue);
                        }
                    } else if fieldValue is map<anydata> {
                        self.updatePath(subInputValue.name);
                        self.validateInputObjectVariableValue(fieldValue, subInputValue, location, fieldName);
                        self.removePath();
                    } else if fieldValue is anydata[] {
                        self.updatePath(subInputValue.name);
                        self.validateListVariableValue(fieldValue, subInputValue, location, fieldName);
                        self.removePath();
                    } else if fieldValue is () {
                        string expectedTypeName = getOfTypeName(inputValue.'type);
                        self.validateArgumentValue(fieldValue, location, expectedTypeName, subInputValue);
                    }
                } else {
                    if subInputValue.'type.kind == NON_NULL && inputValue?.defaultValue is () {
                        string inputField = getInputObjectFieldFormPath(self.argumentPath, subInputValue.name);
                        string message = string `Field "${inputField}" of required type ` +
                                         string `"${getTypeNameFromType(subInputValue.'type)}" was not provided.`;
                        self.errors.push(getErrorDetailRecord(message, location));
                    }
                }
            }
        } else {
            string expectedTypeName = getOfTypeName(inputValue.'type);
            string listError = getListElementError(self.argumentPath);
            string message = string `${listError}${expectedTypeName} cannot represent non ${expectedTypeName} value: {}`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, location);
            self.errors.push(errorDetail);
        }
    }

    isolated function validateListVariableValue(anydata[] variableValues, __InputValue inputValue,
                                                Location location, string fieldName) {
        if getTypeKind(inputValue.'type) == LIST {
            __InputValue listItemInputValue = createInputValueForListItem(inputValue);
            if getOfType(listItemInputValue.'type).name == UPLOAD {
                return;
            }
            if variableValues.length() > 0 {
                foreach int i in 0..< variableValues.length() {
                    self.updatePath(i);
                    anydata listItemValue = variableValues[i];
                    if listItemValue is Scalar {
                        if getOfType(listItemInputValue.'type).kind == ENUM {
                            self.validateEnumArgument(listItemValue, location, ENUM, listItemInputValue);
                        } else {
                            string expectedTypeName = getOfTypeName(listItemInputValue.'type);
                            string actualTypeName = getTypeNameFromValue(listItemValue);
                            variableValues[i] = self.coerceValue(listItemValue, expectedTypeName, actualTypeName,
                                                                 location);
                            self.validateArgumentValue(listItemValue, location, getTypeNameFromValue(listItemValue),
                                                       listItemInputValue);
                        }
                    } else if listItemValue is map<json> {
                        self.updatePath(listItemInputValue.name);
                        self.validateInputObjectVariableValue(listItemValue, listItemInputValue, location, fieldName);
                        self.removePath();
                    } else if listItemValue is json[] {
                        self.updatePath(listItemInputValue.name);
                        self.validateListVariableValue(listItemValue, listItemInputValue, location, fieldName);
                        self.removePath();
                    } else if listItemValue is () {
                        string expectedTypeName = getOfTypeName(listItemInputValue.'type);
                        self.validateArgumentValue(listItemValue, location, expectedTypeName, listItemInputValue);
                    }
                    self.removePath();
                }
            } else if listItemInputValue.'type.kind == NON_NULL {
                string expectedTypeName = getTypeNameFromType(inputValue.'type);
                string message = string `${expectedTypeName} cannot represent non ${expectedTypeName} value: []`;
                ErrorDetail errorDetail = getErrorDetailRecord(message, location);
                self.errors.push(errorDetail);
            }
        } else {
            string expectedTypeName = getOfTypeName(inputValue.'type);
            string value = variableValues.toString();
            string message = string `${expectedTypeName} cannot represent non ${expectedTypeName} value: ${value}`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, location);
            self.errors.push(errorDetail);
        }
    }

    isolated function coerceArgumentNodeValue(parser:ArgumentNode argNode, __InputValue schemaArg) {
        string expectedTypeName = getOfTypeName(schemaArg.'type);
        if argNode.isVariableDefinition() && argNode.getVariableValue() is Scalar {
            Scalar value = <Scalar>argNode.getVariableValue();
            value = self.coerceValue(value, expectedTypeName, getTypeNameFromValue(value), argNode.getValueLocation());
            argNode.setVariableValue(value);
            if value is decimal|float {
                argNode.setKind(parser:T_FLOAT);
            }
        } else if argNode.getValue() is Scalar {
            Scalar value = <Scalar>argNode.getValue();
            value = self.coerceValue(value, expectedTypeName, getTypeNameFromValue(value), argNode.getValueLocation());
            argNode.setValue(value);
            if value is decimal|float {
                argNode.setKind(parser:T_FLOAT);
            }
        }
    }

    isolated function coerceValue(Scalar value, string expectedTypeName, string actualTypeName, Location location)
        returns Scalar {
        if expectedTypeName == FLOAT {
            if actualTypeName == INT || actualTypeName == DECIMAL {
                float|error coerceValue = float:fromString(value.toString());
                if coerceValue is float {
                    return coerceValue;
                } else {
                    string message = string `${expectedTypeName} cannot represent non ${expectedTypeName} value: ` +
                                     string `${value}`;
                    ErrorDetail errorDetail = getErrorDetailRecord(message, location);
                    self.errors.push(errorDetail);
                }
            }
        } else if expectedTypeName == DECIMAL {
            if actualTypeName == INT || actualTypeName == FLOAT {
                decimal|error coerceValue = decimal:fromString(value.toString());
                if coerceValue is decimal {
                    return coerceValue;
                } else {
                    string message = string `${expectedTypeName} cannot represent non ${expectedTypeName} value: ` +
                                     string `${value}`;
                    ErrorDetail errorDetail = getErrorDetailRecord(message, location);
                    self.errors.push(errorDetail);
                }
            }
        }
        return value;
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        self.validateDirectiveArguments(fragmentNode);
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection, data);
        }
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
                    self.visitArgument(argumentNode, {input: inputValue, fieldName: fieldNode.getName()});
                } else {
                    string parentName = parentType.name is string ? <string>parentType.name : "";
                    string message = getUnknownArgumentErrorMessage(argName, parentName, fieldNode.getName());
                    self.errors.push(getErrorDetailRecord(message, argumentNode.getLocation()));
                }
            }
        }

        foreach __InputValue inputValue in notFoundInputValues {
            if inputValue.'type.kind == NON_NULL && inputValue?.defaultValue is () && getOfType(inputValue.'type).name != UPLOAD {
                string message = getMissingRequiredArgError(fieldNode, inputValue);
                self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
            }
        }
    }

    isolated function validateFragment(parser:FragmentNode fragmentNode, string schemaTypeName) returns __Type? {
        string fragmentOnTypeName = fragmentNode.getOnType();
        __Type? fragmentOnType = getTypeFromTypeArray(self.schema.types, fragmentOnTypeName);
        if fragmentOnType is () {
            string message = string `Unknown type "${fragmentOnTypeName}".`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, fragmentNode.getLocation());
            self.errors.push(errorDetail);
        } else {
            __Type schemaType = <__Type>getTypeFromTypeArray(self.schema.types, schemaTypeName);
            __Type ofType = getOfType(schemaType);
            if fragmentOnType != ofType {
                if ofType.kind == INTERFACE || ofType.kind == UNION {
                    __Type[] possibleTypes = <__Type[]>ofType.possibleTypes;
                    __Type? possibleType = getTypeFromTypeArray(possibleTypes, fragmentOnTypeName);
                    if possibleType == fragmentOnType {
                        return;
                    }
                }
                string message = getFragmetCannotSpreadError(fragmentNode, fragmentNode.getName(), ofType);
                ErrorDetail errorDetail = getErrorDetailRecord(message, <Location>fragmentNode.getSpreadLocation());
                self.errors.push(errorDetail);
            }
            return fragmentOnType;
        }
        return;
    }

    isolated function validateInputObjectFields(parser:ArgumentNode node, __InputValue[] schemaFields) {
        string[] definedFields = self.getInputObjectFieldNamesFromInputValue(schemaFields);
        if node.getValue() is parser:ArgumentValue[] {
            parser:ArgumentValue[] inputObjectFields = <parser:ArgumentValue[]>node.getValue();
            foreach parser:ArgumentValue 'field in inputObjectFields {
                if 'field is parser:ArgumentNode {
                    int? index = definedFields.indexOf('field.getName());
                    if index is () {
                        string message = string `Field "${'field.getName()}" is not defined by type ` +
                                         string `"${node.getName()}".`;
                        self.errors.push(getErrorDetailRecord(message, 'field.getLocation()));
                    }
                }
            }
        }
    }

    isolated function getInputObjectFieldNamesFromInputValue(__InputValue[] schemaFields) returns string[] {
        string[] fieldNames = [];
        foreach __InputValue 'field in schemaFields {
            fieldNames.push('field.name);
        }
        return fieldNames;
    }

    isolated function validateEnumArgument(parser:ArgumentValue value, Location valueLocation, string actualArgType,
                                           __InputValue inputValue) {
        __Type argType = getOfType(inputValue.'type);
        if getArgumentTypeKind(actualArgType) != parser:T_IDENTIFIER {
            string listError = getListElementError(self.argumentPath);
            string message = string `${listError}Enum "${getTypeNameFromType(argType)}" cannot represent non-enum` +
                             string ` value: "${value.toString()}"`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, valueLocation);
            self.errors.push(errorDetail);
            return;
        }
        __EnumValue[] enumValues = <__EnumValue[]>argType?.enumValues;
        foreach __EnumValue enumValue in enumValues {
            if enumValue.name == value {
                return;
            }
        }
        string message = string `Value "${value.toString()}" does not exist in "${inputValue.name}" enum.`;
        ErrorDetail errorDetail = getErrorDetailRecord(message, valueLocation);
        self.errors.push(errorDetail);
    }

    isolated function validateDirectiveArguments(parser:ParentNode node) {
        foreach parser:DirectiveNode directive in node.getDirectives() {
            foreach __Directive defaultDirective in self.schema.directives {
                if directive.getName() == defaultDirective.name {
                    __InputValue[] notFoundInputValues = copyInputValueArray(defaultDirective.args);
                    foreach parser:ArgumentNode argumentNode in directive.getArguments() {
                        string argName = argumentNode.getName();
                        __InputValue? inputValue = getInputValueFromArray(defaultDirective.args, argName);
                        if inputValue is __InputValue {
                            _ = notFoundInputValues.remove(<int>notFoundInputValues.indexOf(inputValue));
                            self.visitArgument(argumentNode, {input: inputValue, fieldName: directive.getName()});
                        } else {
                            string message = string `Unknown argument "${argName}" on directive` +
                                             string `"${directive.getName()}".`;
                            self.errors.push(getErrorDetailRecord(message, argumentNode.getLocation()));
                        }
                    }
                    foreach __InputValue arg in notFoundInputValues {
                        string message = string `Directive "${directive.getName()}" argument "${arg.name}" of type` +
                                         string `"${getTypeNameFromType(arg.'type)}" is required but not provided.`;
                        self.errors.push(getErrorDetailRecord(message, directive.getLocation()));
                    }
                    break;
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

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {

    }

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {

    }
}

isolated function createSchemaFieldFromOperation(__Type[] typeArray, parser:OperationNode operationNode,
                                                 ErrorDetail[] errors) returns __Field? {
    parser:RootOperationType operationType = operationNode.getKind();
    string operationTypeName = getOperationTypeNameFromOperationType(operationType);
    __Type? 'type = getTypeFromTypeArray(typeArray, operationTypeName);
    if 'type == () {
        string message = string `Schema is not configured for ${operationType.toString()}s.`;
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
            __Type wrapperType = {kind: NON_NULL, ofType: argumentType};
            __InputValue[] args = [{name: NAME_ARGUMENT, 'type: wrapperType}];
            requiredField = createField(TYPE_FIELD, fieldType, args);
        } else if fieldNode.getName() == TYPE_NAME_FIELD {
            __Type ofType = <__Type>getTypeFromTypeArray(typeArray, STRING);
            __Type wrappingType = {kind: NON_NULL, ofType: ofType};
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
        if getOfTypeName(ofType) == typeName {
            return ofType;
        }
    }
    return;
}

isolated function hasFields(__Type fieldType) returns boolean {
    if fieldType.kind == OBJECT || fieldType.kind == UNION || fieldType.kind == INTERFACE {
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

isolated function createInputValueForListItem(__InputValue inputValue) returns __InputValue {
    __Type listItemInputValueType = getListMemberTypeFromType(inputValue.'type);
    return {
        name: inputValue.name,
        'type: listItemInputValueType
    };
}
