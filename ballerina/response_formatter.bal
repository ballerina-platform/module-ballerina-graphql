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
            ErrorDetail[] sortedErrors = array:sort(originalErrors, array:ASCENDING, sortErrorDetail);
            self.coercedOutputObject[ERRORS_FIELD] = sortedErrors;
        }
    }

    isolated function coerceData(OutputObject outputObject, parser:OperationNode operationNode) {
        if outputObject.hasKey(DATA_FIELD) {
            Data? originalData = outputObject?.data;
            __Type parentType = getTypeForOperationNode(self.schema, operationNode);
            self.coercedOutputObject[DATA_FIELD] = self.coerceObject(originalData, operationNode, parentType);
        }
    }

    isolated function coerceObject(Data? data, parser:ParentNode parentNode, __Type parentType) returns Data? {
        if data == () {
            return ();
        } else {
            Data result = {};
            foreach parser:Selection selection in parentNode.getSelections() {
                if selection is parser:FragmentNode {
                    self.coerceFragmentValues(data, result, selection, parentType);
                } else {
                    __Type fieldType = self.getFieldType(selection.getName(), parentType);
                    anydata|anydata[] fieldResult = ();
                    if data.hasKey(selection.getAlias()) {
                        fieldResult = self.coerceObjectField(data, selection, parentType);
                    }
                    if fieldType.kind == NON_NULL && fieldResult == () {
                        return ();
                    } else {
                        result[selection.getAlias()] = fieldResult;
                    }
                }
            }
            return result;
        }
    }

    isolated function coerceFragmentValues(Data data, Data result, parser:FragmentNode fragmentNode, __Type parentType) {
        foreach parser:Selection selection in fragmentNode.getSelections() {
            if selection is parser:FragmentNode {
                self.coerceFragmentValues(data, result, selection, parentType);
            } else {
                if data.hasKey(selection.getAlias()) {
                    result[selection.getAlias()] = self.coerceObjectField(data, selection, parentType);
                }
            }
        }
    }

    isolated function coerceArray(anydata[] value, parser:FieldNode fieldNode, __Type fieldType) returns anydata[]? {
        anydata[] result = [];
        __Type elementType = fieldType;
        if fieldType.kind == NON_NULL {
            __Type listType = <__Type>fieldType?.ofType;
            elementType = <__Type>listType?.ofType;
        } else if fieldType.kind == LIST {
            elementType = <__Type>fieldType?.ofType;
        }
        foreach anydata element in value {
            if element is Data {
                anydata|anydata[] elementResult = self.coerceObject(element, fieldNode, elementType);
                if elementResult == () && elementType.kind == NON_NULL {
                    return ();
                }
                result.push(elementResult);
            } else {
                result.push(element);
            }
        }
        return result;
    }

    isolated function coerceObjectField(Data data, parser:FieldNode fieldNode, __Type parentType)
    returns anydata|anydata[] {
        __Type objectType = unwrapNonNullype(parentType);
        anydata|anydata[] fieldValue = data.get(fieldNode.getAlias());
        if fieldValue == () {
            return fieldValue;
        } else if fieldValue is anydata[] {
            __Type fieldType = self.getFieldType(fieldNode.getName(), objectType);
            return self.coerceArray(fieldValue, fieldNode, fieldType);
        } else if fieldValue is Data {
            __Type fieldType = self.getFieldType(fieldNode.getName(), parentType);
            return self.coerceObject(fieldValue, fieldNode, fieldType);
        } else {
            return fieldValue;
        }
    }

    isolated function getFieldType(string fieldName, __Type parentType) returns __Type {
        __Type objectType = getOfType(parentType);
        __Field selectionField = self.getField(objectType, fieldName);
        return selectionField.'type;
    }

    isolated function getField(__Type parentType, string fieldName) returns __Field {
        if fieldName == SCHEMA_FIELD {
            __Type fieldType = <__Type>getTypeFromTypeArray(self.schema.types, SCHEMA_TYPE_NAME);
            return createField(SCHEMA_FIELD, fieldType);
        } else if fieldName == TYPE_FIELD {
            __Type fieldType = <__Type>getTypeFromTypeArray(self.schema.types, TYPE_TYPE_NAME);
            __Type argumentType = <__Type>getTypeFromTypeArray(self.schema.types, STRING);
            __Type wrapperType = { kind: NON_NULL, ofType: argumentType };
            __InputValue[] args = [{ name: NAME_ARGUMENT, 'type: wrapperType }];
            return createField(TYPE_FIELD, fieldType, args);
        } else if fieldName == TYPE_NAME_FIELD {
            __Type ofType = <__Type>getTypeFromTypeArray(self.schema.types, STRING);
            __Type wrappingType = { kind: NON_NULL, ofType: ofType };
            return createField(TYPE_NAME_FIELD, wrappingType);
        } else {
            __Field[] fields = <__Field[]>parentType?.fields;
            return <__Field>getFieldFromFieldArray(fields, fieldName);
        }
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

isolated function getTypeForOperationNode(__Schema schema, parser:OperationNode operationNode) returns __Type {
    parser:RootOperationType operationType = operationNode.getKind();
    if operationType == parser:OPERATION_QUERY {
        return schema.queryType;
    } else if operationType == parser:OPERATION_MUTATION {
        return <__Type>schema?.mutationType;
    } else {
        return <__Type>schema?.subscriptionType;
    }
}

isolated function unwrapNonNullype(__Type 'type) returns __Type {
    if 'type.kind == NON_NULL {
        return <__Type>'type?.ofType;
    }
    return 'type;
}
