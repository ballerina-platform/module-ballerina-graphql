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

class FieldValidatorVisitor {
    *ValidatorVisitor;

    private final ErrorDetail[] errors = [];
    private final map<string> usedFragments = {};
    private final (string|int)[] argumentPath = [];
    private final __Schema schema;
    private final NodeModifierContext nodeModifierContext;

    isolated function init(__Schema schema, NodeModifierContext nodeModifierContext) {
        self.schema = schema;
        self.nodeModifierContext = nodeModifierContext;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        foreach parser:OperationNode operationNode in documentNode.getOperations() {
            operationNode.accept(self);
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        __Field? operationField = createSchemaFieldFromOperation(self.schema.types, operationNode, self.errors,
                                                                 self.nodeModifierContext);
        if operationField is __Field {
            foreach parser:SelectionNode selection in operationNode.getSelections() {
                selection.accept(self, operationField);
            }
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
            foreach parser:SelectionNode selection in fieldNode.getSelections() {
                selection.accept(self, requiredField);
            }
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        parser:FragmentNode modifiedFragmentNode = self.nodeModifierContext.getModifiedFragmentNode(fragmentNode);
        __Field parentField = <__Field>data;
        __Type parentType = <__Type>getOfType(parentField.'type);
        __Type? fragmentOnType = self.validateFragment(modifiedFragmentNode, <string>parentType.name);

        if fragmentOnType is __Type {
            parentField = createField(getOfTypeName(fragmentOnType), fragmentOnType);
            self.validateDirectiveArguments(modifiedFragmentNode);
            foreach parser:SelectionNode selection in modifiedFragmentNode.getSelections() {
                selection.accept(self, data);
            }
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        parser:ArgumentNode modifiedArgNode = self.nodeModifierContext.getModifiedArgumentNode(argumentNode);
        if modifiedArgNode.hasInvalidVariableValue() {
            // This argument node is already validated to have an invalid value. No further validation is needed.
            return;
        }
        __InputValue schemaArg = <__InputValue>(<map<anydata>>data).get("input");
        string fieldName = <string>(<map<anydata>>data).get("fieldName");
        if modifiedArgNode.isVariableDefinition() {
            self.validateVariableValue(argumentNode, schemaArg, fieldName);
            self.modifyArgumentNode(argumentNode, kind = getArgumentTypeIdentifierFromType(schemaArg.'type));
        } else if getTypeKind(schemaArg.'type) == SCALAR && getOfTypeName(schemaArg.'type) == ANY {
            self.visistAnyValue(argumentNode, schemaArg);
        } else if modifiedArgNode.getKind() == parser:T_INPUT_OBJECT {
            self.visitInputObject(argumentNode, schemaArg, fieldName);
        } else if modifiedArgNode.getKind() == parser:T_LIST {
            self.visitListValue(argumentNode, schemaArg, fieldName);
        } else {
            parser:ArgumentValue|parser:ArgumentValue[] fieldValue = modifiedArgNode.getValue();
            if fieldValue is parser:ArgumentValue {
                self.coerceArgumentNodeValue(argumentNode, schemaArg);
                self.validateArgumentValue(fieldValue, modifiedArgNode.getValueLocation(), getTypeName(modifiedArgNode),
                                           schemaArg);
            }
        }
    }

    isolated function visistAnyValue(parser:ArgumentNode argumentNode, __InputValue schemaArg) {
        parser:ArgumentNode modifiedArgNode = self.nodeModifierContext.getModifiedArgumentNode(argumentNode);
        parser:ArgumentValue|parser:ArgumentValue[] value = modifiedArgNode.getValue();
        if value is () && schemaArg.'type.kind == NON_NULL {
            string expectedTypeName = getTypeNameFromType(schemaArg.'type);
            string message = string `${expectedTypeName} cannot represent non ${expectedTypeName} value: null`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, modifiedArgNode.getValueLocation());
            self.errors.push(errorDetail);
            return;
        }
        // _Any scalar is serialized as a generic JSON object, therefore it should be parsed as an array of type parser:ArgumentValue
        if value !is parser:ArgumentValue[] {
            string listError = getListElementError(self.argumentPath);
            string message = string `${listError} "${getTypeNameFromType(schemaArg.'type)}" cannot represent non ${getTypeNameFromType(schemaArg.'type)}` +
                            string ` value: "${value.toString()}"`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, modifiedArgNode.getValueLocation());
            self.errors.push(errorDetail);
            return;
        }
        boolean hasTypename = false;
        foreach parser:ArgumentValue argumentValue in value {
            if argumentValue !is parser:ArgumentNode {
                string listError = getListElementError(self.argumentPath);
                string message = string `${listError} "${getTypeNameFromType(schemaArg.'type)}" cannot represent non ${getTypeNameFromType(schemaArg.'type)}` +
                                string ` value: "${value.toString()}"`;
                ErrorDetail errorDetail = getErrorDetailRecord(message, modifiedArgNode.getValueLocation());
                self.errors.push(errorDetail);
                continue;
            }
            if argumentValue.getName() == TYPE_NAME_FIELD {
                hasTypename = true;
            }
        }
        if !hasTypename {
            string listError = getListElementError(self.argumentPath);
            string message = string `${listError} "${getTypeNameFromType(schemaArg.'type)}" cannot represent non ${getTypeNameFromType(schemaArg.'type)}` +
                            string ` value: "__typename" field is absent`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, modifiedArgNode.getValueLocation());
            self.errors.push(errorDetail);
        }
    }

    isolated function visitInputObject(parser:ArgumentNode argNode, __InputValue schemaArg, string fieldName) {
        parser:ArgumentNode modifiedArgumentNode = self.nodeModifierContext.getModifiedArgumentNode(argNode);
        __Type argType = getOfType(schemaArg.'type);
        __InputValue[]? inputFields = argType?.inputFields;
        if inputFields is __InputValue[] && getTypeKind(schemaArg.'type) == INPUT_OBJECT {
            self.updatePath(modifiedArgumentNode.getName());
            parser:ArgumentValue[] fields = <parser:ArgumentValue[]>modifiedArgumentNode.getValue();
            self.validateInputObjectFields(modifiedArgumentNode, inputFields);
            foreach __InputValue inputField in inputFields {
                self.updatePath(inputField.name);
                __InputValue subInputValue = inputField;
                boolean isProvidedField = false;
                parser:ArgumentValue[] value = [];
                foreach parser:ArgumentValue fieldValue in fields {
                    if fieldValue is parser:ArgumentNode && fieldValue.getName() == inputField.name {
                        fieldValue.accept(self, {input: subInputValue, fieldName: fieldName});
                        isProvidedField = true;
                        parser:ArgumentNode modfiedField = self.nodeModifierContext.getModifiedArgumentNode(fieldValue);
                        value.push(modfiedField);
                    } else {
                        value.push(fieldValue);
                    }
                }
                self.modifyArgumentNode(argNode, value = value);
                if !isProvidedField {
                    if subInputValue.'type.kind == NON_NULL && subInputValue.defaultValue is () {
                        string inputFieldName = getInputObjectFieldFormPath(self.argumentPath, subInputValue.name);
                        string message = string `Field "${inputFieldName}" of required type ` +
                                         string `"${getTypeNameFromType(subInputValue.'type)}" was not provided.`;
                        self.errors.push(getErrorDetailRecord(message, modifiedArgumentNode.getLocation()));
                    }
                }
                self.removePath();
            }
            self.removePath();
        } else {
            string listError = getListElementError(self.argumentPath);
            string message = getInvalidArgumentValueError(listError, getTypeNameFromType(schemaArg.'type),
                                                          modifiedArgumentNode);
            ErrorDetail errorDetail = getErrorDetailRecord(message, modifiedArgumentNode.getLocation());
            self.errors.push(errorDetail);
        }
    }

    isolated function visitListValue(parser:ArgumentNode argumentNode, __InputValue schemaArg, string fieldName) {
        parser:ArgumentNode modifiedArgNode = self.nodeModifierContext.getModifiedArgumentNode(argumentNode);
        self.updatePath(modifiedArgNode.getName());
        if getTypeKind(schemaArg.'type) == LIST {
            parser:ArgumentValue|parser:ArgumentValue[] listItems = modifiedArgNode.getValue();
            if listItems is parser:ArgumentValue[] {
                __InputValue listItemInputValue = createInputValueForListItem(schemaArg);
                if listItems.length() > 0 {
                    foreach int i in 0 ..< listItems.length() {
                        parser:ArgumentValue|parser:ArgumentValue[] item = listItems[i];
                        if item is parser:ArgumentNode {
                            self.updatePath(i);
                            item.accept(self, {input: listItemInputValue, fieldName: fieldName});
                            self.removePath();
                        }
                    }
                }
            } else if schemaArg.'type.kind == NON_NULL {
                string expectedTypeName = getTypeNameFromType(schemaArg.'type);
                string message = string `${expectedTypeName} cannot represent non ${expectedTypeName} value: null`;
                ErrorDetail errorDetail = getErrorDetailRecord(message, modifiedArgNode.getValueLocation());
                self.errors.push(errorDetail);
            }
        } else {
            string listError = getListElementError(self.argumentPath);
            string message = getInvalidArgumentValueError(listError, getTypeNameFromType(schemaArg.'type),
                                                          modifiedArgNode);
            ErrorDetail errorDetail = getErrorDetailRecord(message, modifiedArgNode.getLocation());
            self.errors.push(errorDetail);
        }
        self.removePath();
    }

    isolated function validateVariableValue(parser:ArgumentNode argumentNode, __InputValue schemaArg, string fieldName) {
        parser:ArgumentNode modifiedArgNode = self.nodeModifierContext.getModifiedArgumentNode(argumentNode);
        json variableValue = modifiedArgNode.getVariableValue();
        if getOfType(schemaArg.'type).name == UPLOAD {
            return;
        } else if variableValue is Scalar && (getTypeKind(schemaArg.'type) == SCALAR 
                  || getTypeKind(schemaArg.'type) == ENUM) {
            self.coerceArgumentNodeValue(argumentNode, schemaArg);
            self.validateArgumentValue(variableValue, modifiedArgNode.getValueLocation(), getTypeName(modifiedArgNode),
                                       schemaArg);
        } else if variableValue is map<json> && getTypeKind(schemaArg.'type) == INPUT_OBJECT {
            self.updatePath(modifiedArgNode.getName());
            map<json> variableValueClone = {...variableValue};
            self.validateInputObjectVariableValue(variableValueClone, schemaArg, modifiedArgNode.getValueLocation(),
                                                  fieldName);
            self.modifyArgumentNode(argumentNode, variableValue = variableValueClone);
            self.removePath();
        } else if variableValue is json[] && getTypeKind(schemaArg.'type) == LIST {
            self.updatePath(modifiedArgNode.getName());
            json[] clonedVariableValue = [...variableValue];
            self.validateListVariableValue(clonedVariableValue, schemaArg, modifiedArgNode.getValueLocation(),
                                           fieldName);
            self.modifyArgumentNode(argumentNode, variableValue = clonedVariableValue);
            self.removePath();
        } else if variableValue is () {
            self.validateArgumentValue(variableValue, modifiedArgNode.getValueLocation(), getTypeName(modifiedArgNode),
                                       schemaArg);
        } else {
            string expectedTypeName = getOfTypeName(schemaArg.'type);
            if variableValue is map<json> && getTypeKind(schemaArg.'type) == LIST {
                expectedTypeName = getTypeNameFromType(schemaArg.'type);
            }
            string listError = getListElementError(self.argumentPath);
            string value = variableValue is () ? "null" : variableValue.toString();
            string message = string `${listError}${expectedTypeName} cannot represent non ${expectedTypeName} value:` +
                             string ` ${value}`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, modifiedArgNode.getValueLocation());
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

    isolated function validateInputObjectVariableValue(map<json> variableValues, __InputValue inputValue,
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
                            string actualTypeName = getTypeNameFromScalarValue(fieldValue);
                            variableValues[subInputValue.name] = self.coerceValue(fieldValue, expectedTypeName,
                                                                                  actualTypeName, location);
                            self.validateArgumentValue(fieldValue, location, getTypeNameFromScalarValue(fieldValue),
                                                       subInputValue);
                        }
                    } else if fieldValue is map<json> {
                        self.updatePath(subInputValue.name);
                        map<json> fieldValueClone = {...fieldValue};
                        self.validateInputObjectVariableValue(fieldValueClone, subInputValue, location, fieldName);
                        variableValues[subInputValue.name] = fieldValueClone;
                        self.removePath();
                    } else if fieldValue is json[] {
                        self.updatePath(subInputValue.name);
                        json[] fieldValueClone = [...fieldValue];
                        self.validateListVariableValue(fieldValueClone, subInputValue, location, fieldName);
                        variableValues[subInputValue.name] = fieldValueClone;
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

    isolated function validateListVariableValue(json[] variableValues, __InputValue inputValue,
                                                Location location, string fieldName) {
        if getTypeKind(inputValue.'type) == LIST {
            __InputValue listItemInputValue = createInputValueForListItem(inputValue);
            if getOfType(listItemInputValue.'type).name == UPLOAD {
                return;
            }
            if variableValues.length() > 0 {
                foreach int i in 0 ..< variableValues.length() {
                    self.updatePath(i);
                    json listItemValue = variableValues[i];
                    if listItemValue is () {
                        string expectedTypeName = getOfTypeName(listItemInputValue.'type);
                        self.validateArgumentValue(listItemValue, location, expectedTypeName, listItemInputValue);
                    } else if getOfTypeName(listItemInputValue.'type) == ANY {
                        self.validateAnyScalarVariable(listItemValue, location, listItemInputValue);
                    } else if listItemValue is Scalar {
                        if getOfType(listItemInputValue.'type).kind == ENUM {
                            self.validateEnumArgument(listItemValue, location, ENUM, listItemInputValue);
                        } else {
                            string expectedTypeName = getOfTypeName(listItemInputValue.'type);
                            string actualTypeName = getTypeNameFromScalarValue(listItemValue);
                            variableValues[i] = self.coerceValue(listItemValue, expectedTypeName, actualTypeName,
                                                                 location);
                            self.validateArgumentValue(listItemValue, location,
                                                       getTypeNameFromScalarValue(listItemValue), listItemInputValue);
                        }
                    } else if listItemValue is map<json> {
                        self.updatePath(listItemInputValue.name);
                        map<json> listItemValueClone = {...listItemValue};
                        self.validateInputObjectVariableValue(listItemValueClone, listItemInputValue, location,
                                                              fieldName);
                        variableValues[i] = listItemValueClone;
                        self.removePath();
                    } else if listItemValue is json[] {
                        self.updatePath(listItemInputValue.name);
                        json[] listItemValueClone = [...listItemValue];
                        self.validateListVariableValue(listItemValueClone, listItemInputValue, location, fieldName);
                        variableValues[i] = listItemValueClone;
                        self.removePath();
                    }
                    self.removePath();
                }
            }
        } else {
            string expectedTypeName = getOfTypeName(inputValue.'type);
            string value = variableValues.toString();
            string message = string `${expectedTypeName} cannot represent non ${expectedTypeName} value: ${value}`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, location);
            self.errors.push(errorDetail);
        }
    }

    isolated function validateAnyScalarVariable(json value, Location valueLocation, __InputValue inputValue) {
        __Type argType = getOfType(inputValue.'type);
        string schemaTypeName = getTypeNameFromType(argType);
        if value !is map<json> {
            string listError = getListElementError(self.argumentPath);
            string message = string `${listError} "${schemaTypeName}" cannot represent non ${schemaTypeName}` +
                             string ` value: "${value.toString()}"`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, valueLocation);
            self.errors.push(errorDetail);
            return;
        }
        if value?.__typename == () {
            string listError = getListElementError(self.argumentPath);
            string message = string `${listError} "${schemaTypeName}" cannot represent non ${schemaTypeName}` +
                             string ` value: "__typename" field is absent`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, valueLocation);
            self.errors.push(errorDetail);
            return;
        }
    }

    isolated function coerceArgumentNodeValue(parser:ArgumentNode argumentNode, __InputValue schemaArg) {
        parser:ArgumentNode modifiedArgNode = self.nodeModifierContext.getModifiedArgumentNode(argumentNode);
        string expectedTypeName = getOfTypeName(schemaArg.'type);
        if modifiedArgNode.isVariableDefinition() && modifiedArgNode.getVariableValue() is Scalar {
            Scalar value = <Scalar>modifiedArgNode.getVariableValue();
            value = self.coerceValue(value, expectedTypeName, getTypeNameFromScalarValue(value),
                                     modifiedArgNode.getValueLocation());
            self.modifyArgumentNode(argumentNode, value = value);
            if value is decimal|float {
                self.modifyArgumentNode(argumentNode, kind = parser:T_FLOAT);
            }
        } else if modifiedArgNode.getValue() is Scalar {
            Scalar value = <Scalar>modifiedArgNode.getValue();
            value = self.coerceValue(value, expectedTypeName, getTypeNameFromScalarValue(value),
                                     modifiedArgNode.getValueLocation());
            self.modifyArgumentNode(argumentNode, value = value);
            if value is decimal|float {
                self.modifyArgumentNode(argumentNode, kind = parser:T_FLOAT);
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
                    argumentNode.accept(self, {input: inputValue, fieldName: fieldNode.getName()});
                } else {
                    string parentName = parentType.name is string ? <string>parentType.name : "";
                    string message = getUnknownArgumentErrorMessage(argName, parentName, fieldNode.getName());
                    self.errors.push(getErrorDetailRecord(message, argumentNode.getLocation()));
                }
            }
        }

        foreach __InputValue inputValue in notFoundInputValues {
            if inputValue.'type.kind == NON_NULL && inputValue?.defaultValue is () 
               && getOfType(inputValue.'type).name != UPLOAD {
                string message = getMissingRequiredArgError(fieldNode, inputValue);
                self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
            }
        }
    }

    isolated function validateFragment(parser:FragmentNode fragmentNode, string schemaTypeName) returns __Type? {
        if self.nodeModifierContext.isUnknownFragment(fragmentNode)
           || self.nodeModifierContext.isFragmentWithCycles(fragmentNode) {
            return;
        }
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
            } else {
                return fragmentOnType;
            }
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

    isolated function validateDirectiveArguments(parser:SelectionParentNode node) {
        foreach parser:DirectiveNode directive in node.getDirectives() {
            foreach __Directive defaultDirective in self.schema.directives {
                if directive.getName() == defaultDirective.name {
                    foreach parser:ArgumentNode argumentNode in directive.getArguments() {
                        string argName = argumentNode.getName();
                        __InputValue? inputValue = getInputValueFromArray(defaultDirective.args, argName);
                        if inputValue is __InputValue {
                            argumentNode.accept(self, {input: inputValue, fieldName: directive.getName()});
                        }
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

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {}

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {}

    public isolated function getErrors() returns ErrorDetail[]? {
        return self.errors.length() > 0 ? self.errors : ();
    }

    private isolated function modifyArgumentNode(parser:ArgumentNode originalNode, parser:ArgumentType? kind = (),
                                                 parser:ArgumentValue|parser:ArgumentValue[] value = (),
                                                 json variableValue = ()) {
        parser:ArgumentNode previouslyModifiedNode = self.nodeModifierContext.getModifiedArgumentNode(originalNode);
        parser:ArgumentNode newModifiedNode = previouslyModifiedNode.modifyWith(kind = kind, value = value,
                                                                                variableValue = variableValue);
        self.nodeModifierContext.addModifiedArgumentNode(originalNode, newModifiedNode);
        return;
    }
}

isolated function createSchemaFieldFromOperation(__Type[] typeArray, parser:OperationNode operationNode,
                                                 ErrorDetail[] errors, NodeModifierContext nodeModifierContext)
returns __Field? {
    if nodeModifierContext.isNonConfiguredOperation(operationNode) {
        return;
    }
    parser:RootOperationType operationType = operationNode.getKind();
    string operationTypeName = getOperationTypeNameFromOperationType(operationType);
    __Type? 'type = getTypeFromTypeArray(typeArray, operationTypeName);
    if 'type == () {
        string message = string `Schema is not configured for ${operationType.toString()}s.`;
        errors.push(getErrorDetailRecord(message, operationNode.getLocation()));
        nodeModifierContext.addNonConfiguredOperation(operationNode);
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
