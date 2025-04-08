// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/lang.array;

import graphql.parser;

class ResponseFormatter {
    private final readonly & __Schema schema;
    private OutputObject coercedOutputObject;

    isolated function init(readonly & __Schema schema) {
        self.schema = schema;
        self.coercedOutputObject = {};
    }

    isolated function getCoercedOutputObject(OutputObject outputObject, parser:OperationNode operationNode)
    returns OutputObject {
        self.coerceErrors(outputObject);
        self.coerceData(outputObject, operationNode);
        return self.coercedOutputObject;
    }

    isolated function coerceErrors(OutputObject outputObject) {
        ErrorDetail[]? originalErrors = outputObject?.errors;
        if originalErrors == () {
            return;
        } else {
            addObservabilityMetricsTags(GRAPHQL_ERRORS, GRAPHQL_EXECUTION_ERROR);
            ErrorDetail[] sortedErrors = array:sort(originalErrors, array:ASCENDING, sortErrorDetail);
            self.coercedOutputObject[ERRORS_FIELD] = sortedErrors;
        }
    }

    isolated function coerceData(OutputObject outputObject, parser:OperationNode operationNode) {
        if outputObject.hasKey(DATA_FIELD) {
            Data? originalData = outputObject?.data;
            readonly & __Type parentType = getTypeForOperationNode(self.schema, operationNode);
            self.coercedOutputObject[DATA_FIELD] = self.coerceObject(originalData, operationNode, parentType);
        }
    }

    isolated function coerceObject(Data? data, parser:SelectionParentNode parentNode, readonly & __Type parentType,
    string? onType = ()) returns Data? {
        if data == () {
            return ();
        } else {
            Data result = {};
            foreach parser:SelectionNode selection in parentNode.getSelections() {
                if selection is parser:FragmentNode {
                    Data? fieldResult = self.coerceFragmentValues(data, result, selection, parentType, selection.getOnType());
                    if fieldResult == () {
                        return;
                    }
                } else if selection is parser:FieldNode {
                    __Type fieldType = self.getFieldType(selection.getName(), parentType, onType);
                    anydata|anydata[] fieldResult = ();
                    if data.hasKey(selection.getAlias()) || data.hasKey(selection.getName()) {
                        fieldResult = self.coerceObjectField(data, selection, parentType, onType);
                    }
                    if fieldType.kind == NON_NULL && fieldResult == () {
                        return ();
                    } else {
                        result[selection.getAlias()] = fieldResult;
                    }
                } else {
                    panic error("Invalid selection node passed.");
                }
            }
            return result;
        }
    }

    isolated function coerceFragmentValues(Data data, Data result, parser:FragmentNode fragmentNode,
            readonly & __Type parentType, string onType) returns Data? {
        foreach parser:SelectionNode selection in fragmentNode.getSelections() {
            if selection is parser:FragmentNode {
                Data? fieldResult = self.coerceFragmentValues(data, result, selection, parentType, selection.getOnType());
                if fieldResult == () {
                    return;
                }
            } else if selection is parser:FieldNode {
                if data.hasKey(selection.getAlias()) || data.hasKey(selection.getName()) {
                    anydata|anydata[] fieldResult = self.coerceObjectField(data, selection, parentType, onType);
                    __Type fieldType = self.getFieldType(selection.getName(), parentType, onType);
                    if fieldType.kind == NON_NULL && fieldResult == () {
                        return;
                    } else {
                        result[selection.getAlias()] = fieldResult;
                    }
                }
            } else {
                panic error("Invalid selection node passed.");
            }
        }
        return result;
    }

    isolated function coerceArray(anydata[] value, parser:FieldNode fieldNode, readonly & __Type fieldType, string? onType)
    returns anydata[]? {
        anydata[] result = [];
        readonly & __Type elementType = fieldType;
        if fieldType.kind == NON_NULL {
            __Type listType = <__Type>fieldType?.ofType;
            elementType = <readonly & __Type>listType?.ofType;
        } else if fieldType.kind == LIST {
            elementType = <readonly & __Type>fieldType?.ofType;
        }
        foreach anydata element in value {
            if element is Data {
                anydata|anydata[] elementResult = self.coerceObject(element, fieldNode, elementType, onType);
                if elementResult == () && elementType.kind == NON_NULL {
                    return ();
                }
                result.push(elementResult);
            } else {
                if element == () && elementType.kind == NON_NULL {
                    return ();
                }
                result.push(element);
            }
        }
        return result;
    }

    isolated function coerceObjectField(Data data, parser:FieldNode fieldNode, readonly & __Type parentType,
            string? onType) returns anydata|anydata[] {
        readonly & __Type objectType = unwrapNonNullType(parentType);
        anydata|anydata[] fieldValue = self.getFieldValue(data, fieldNode);
        if fieldValue == () {
            return fieldValue;
        } else if fieldValue is anydata[] {
            readonly & __Type fieldType = self.getFieldType(fieldNode.getName(), objectType, onType);
            return self.coerceArray(fieldValue, fieldNode, fieldType, onType);
        } else if fieldValue is Data {
            readonly & __Type fieldType = self.getFieldType(fieldNode.getName(), parentType, onType);
            if isMap(fieldValue) && getKeyArgument(fieldNode) is string {
                Data updatedData = {};
                fieldValue = fieldValue[<string>getKeyArgument(fieldNode)];
                updatedData[fieldNode.getAlias()] = fieldValue;
                return self.coerceObjectField(updatedData, fieldNode, parentType, onType);
            }
            return self.coerceObject(fieldValue, fieldNode, fieldType, onType);
        } else {
            return fieldValue;
        }
    }

    isolated function getFieldType(string fieldName, readonly & __Type parentType, string? onType)
    returns readonly & __Type {
        readonly & __Type objectType = getOfType(parentType);
        readonly & __Field selectionField = self.getField(objectType, fieldName, onType);
        return selectionField.'type;
    }

    isolated function getField(readonly & __Type parentType, string fieldName, string? onType)
    returns readonly & __Field {
        if fieldName == SCHEMA_FIELD {
            readonly & __Type fieldType = <readonly & __Type>getTypeFromTypeArray(self.schema.types, SCHEMA_TYPE_NAME);
            return createField(SCHEMA_FIELD, fieldType);
        } else if fieldName == TYPE_FIELD {
            readonly & __Type fieldType = <readonly & __Type>getTypeFromTypeArray(self.schema.types, TYPE_TYPE_NAME);
            readonly & __Type argumentType = <readonly & __Type>getTypeFromTypeArray(self.schema.types, STRING);
            readonly & __Type wrapperType = { kind: NON_NULL, ofType: argumentType };
            readonly & __InputValue[] args = [{ name: NAME_ARGUMENT, 'type: wrapperType }];
            return createField(TYPE_FIELD, fieldType, args);
        } else if fieldName == TYPE_NAME_FIELD {
            readonly & __Type ofType = <readonly & __Type>getTypeFromTypeArray(self.schema.types, STRING);
            readonly & __Type wrappingType = { kind: NON_NULL, ofType };
            return createField(TYPE_NAME_FIELD, wrappingType);
        } else {
            if parentType.kind is UNION && onType is string {
                __Type[] possibleTypes = <__Type[]>parentType?.possibleTypes;
                readonly & __Type exactType = <readonly & __Type>getTypeFromPossibleTypes(possibleTypes, onType);
                return self.getField(exactType, fieldName, onType);
            } else if parentType.kind is INTERFACE {
                readonly & __Field[] fields = <readonly & __Field[]>parentType?.fields;
                readonly & __Field? exactField = getFieldFromFieldArray(fields, fieldName);
                if exactField is __Field {
                    return exactField;
                }
                __Type[] possibleTypes = <__Type[]>parentType?.possibleTypes;
                readonly & __Type exactType = <readonly & __Type>getTypeFromPossibleTypes(possibleTypes, <string>onType);
                return self.getField(exactType, fieldName, onType);
            }
            readonly & __Field[] fields = <readonly & __Field[]>parentType?.fields;
            return <readonly & __Field>getFieldFromFieldArray(fields, fieldName);
        }
    }

    isolated function getFieldValue(Data data, parser:FieldNode fieldNode) returns anydata|anydata[] {
        if data.hasKey(fieldNode.getAlias()) {
            return data[fieldNode.getAlias()];
        }
        return data[fieldNode.getName()];
    }
}

isolated function sortErrorDetail(ErrorDetail errorDetail) returns int {
    Location[]? locations = errorDetail?.locations;
    if locations == () {
        return 0;
    } else {
        return locations[locations.length() - 1].line;
    }
}

isolated function getTypeForOperationNode(readonly & __Schema schema, parser:OperationNode operationNode)
returns readonly & __Type {
    parser:RootOperationType operationType = operationNode.getKind();
    if operationType == parser:OPERATION_QUERY {
        return schema.queryType;
    } else if operationType == parser:OPERATION_MUTATION {
        return <readonly & __Type>schema?.mutationType;
    } else {
        return <readonly & __Type>schema?.subscriptionType;
    }
}

isolated function unwrapNonNullType(readonly & __Type 'type) returns readonly & __Type {
    if 'type.kind == NON_NULL {
        return <readonly & __Type>'type?.ofType;
    }
    return 'type;
}

isolated function getTypeFromPossibleTypes(__Type[] possibleTypes, string onType) returns __Type? {
    foreach __Type possibleType in possibleTypes {
        if possibleType.name == onType {
            return possibleType;
        }
    }
    return;
}
