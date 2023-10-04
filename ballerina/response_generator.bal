// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/log;

import graphql.parser;

class ResponseGenerator {
    private final Engine engine;
    private final Context context;
    private (string|int)[] path;
    private final __Type fieldType;

    private final string functionNameGetFragmentFromService = "";

    isolated function init(Engine engine, Context context, __Type fieldType, (string|int)[] path = []) {
        self.engine = engine;
        self.context = context;
        self.path = path;
        self.fieldType = fieldType;
    }

    isolated function getResult(any|error parentValue, parser:FieldNode parentNode)
    returns anydata {
        if parentValue is ErrorDetail {
            return;
        }
        if parentValue is error {
            return self.addError(parentValue, parentNode);
        }
        if parentValue is Scalar || parentValue is Scalar[] {
            return parentValue;
        }
        if parentValue is map<any> {
            if isMap(parentValue) {
                return self.getResultFromMap(parentValue, parentNode);
            }
            return self.getResultFromRecord(parentValue, parentNode);
        }
        if parentValue is (any|error)[] {
            return self.getResultFromArray(parentValue, parentNode);
        }
        if parentValue is table<map<any>> {
            return self.getResultFromTable(parentValue, parentNode);
        }
        if parentValue is service object {} {
            return self.getResultFromService(parentValue, parentNode);
        }
    }

    isolated function getResultFromObject(any parentValue, parser:FieldNode fieldNode) returns anydata {
        if fieldNode.getName() == TYPE_NAME_FIELD {
            return getTypeNameFromValue(parentValue);
        } else if parentValue is map<anydata> {
            if parentValue.hasKey(fieldNode.getName()) {
                return self.getResult(parentValue.get(fieldNode.getName()), fieldNode);
            } else if parentValue.hasKey(fieldNode.getAlias()) {
                // TODO: This is to handle results from hierarchical paths. Should find a better way to handle this.
                return self.getResult(parentValue.get(fieldNode.getAlias()), fieldNode);
            } else {
                return;
            }
        } else if parentValue is service object {} {
            (string|int)[] clonedPath = self.path.clone();
            clonedPath.push(fieldNode.getAlias());
            __Type fieldType = getFieldTypeFromParentType(self.fieldType, self.engine.getSchema().types, fieldNode);
            Field 'field = new (fieldNode, fieldType, parentValue, clonedPath);
            self.context.resetInterceptorCount();
            return self.engine.resolve(self.context, 'field);
        }
    }

    isolated function addError(error err, parser:FieldNode fieldNode) returns ErrorDetail {
        log:printError(err.message(), stackTrace = err.stackTrace());
        ErrorDetail errorDetail = {
            message: err.message(),
            locations: [fieldNode.getLocation()],
            path: self.path.clone()
        };
        self.context.addError(errorDetail);
        return errorDetail;
    }

    isolated function addConstraintValidationErrors(error[] errors, parser:FieldNode fieldNode) {
        ErrorDetail[] errorDetails = [];
        foreach error err in errors {
            string formattedErrorMsg = string `Input validation failed in the field "${fieldNode.getAlias()}": ${err.message()}`;
            log:printError(formattedErrorMsg, stackTrace = err.stackTrace());
            ErrorDetail errorDetail = {
                message: formattedErrorMsg,
                locations: [fieldNode.getLocation()],
                path: self.path.clone()
            };
            errorDetails.push(errorDetail);
        }
        self.context.addErrors(errorDetails);
    }

    isolated function getResultFromMap(map<any> parentValue, parser:FieldNode parentNode)
    returns anydata {
        string? mapKey = getKeyArgument(parentNode);
        if mapKey is string {
            if parentValue.hasKey(mapKey) {
                return self.getResult(parentValue.get(mapKey), parentNode);
            } else {
                string message = string `The field "${parentNode.getName()}" is a map, but it does not contain the key "${mapKey}"`;
                var result = self.getResult(error(message), parentNode);
                return result;
            }
        } else if parentValue is map<anydata> {
            return parentValue;
        }
    }

    isolated function getResultFromRecord(map<any> parentValue, parser:FieldNode parentNode)
    returns anydata {
        Data result = {};
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            if selection is parser:FieldNode {
                anydata fieldValue = self.getRecordResult(parentValue, selection);
                result[selection.getAlias()] = fieldValue is ErrorDetail ? () : fieldValue;
            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromMap(parentValue, selection, result);
            }
        }
        return result;
    }

    isolated function getRecordResult(map<any> parentValue, parser:FieldNode fieldNode) returns anydata {
        if fieldNode.getName() == TYPE_NAME_FIELD {
            return getTypeNameFromValue(parentValue);
        }
        any fieldValue = parentValue.hasKey(fieldNode.getName()) ? parentValue.get(fieldNode.getName()): ();
        __Type fieldType = getFieldTypeFromParentType(self.fieldType, self.engine.getSchema().types, fieldNode);
        (string|int)[] clonedPath = self.path.clone();
        clonedPath.push(fieldNode.getAlias());
        Field 'field = new (fieldNode, fieldType, path = clonedPath, fieldValue = fieldValue);
        self.context.resetInterceptorCount();
        return self.engine.resolve(self.context, 'field);
    }

    isolated function getResultFromArray((any|error)[] parentValue, parser:FieldNode parentNode) returns anydata {
        int i = 0;
        anydata[] result = [];
        foreach any|error element in parentValue {
            self.path.push(i);
            anydata elementValue = self.getResult(element, parentNode);
            i += 1;
            _ = self.path.pop();
            if elementValue is ErrorDetail {
                result.push(());
            } else {
                result.push(elementValue);
            }
        }
        return result;
    }

    isolated function getResultFromTable(table<map<any>> parentValue, parser:FieldNode parentNode) returns anydata {
        anydata[] result = [];
        foreach map<any> element in parentValue {
            anydata elementValue = self.getResult(element, parentNode);
            if elementValue is ErrorDetail {
                result.push(());
            } else {
                result.push(elementValue);
            }
        }
        return result;
    }

    isolated function getResultFromService(service object {} serviceObject, parser:FieldNode parentNode) returns anydata {
        Data result = {};
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            if selection is parser:FieldNode {
                anydata selectionValue = self.getResultFromObject(serviceObject, selection);
                result[selection.getAlias()] = selectionValue is ErrorDetail ? () : selectionValue;
            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromService(serviceObject, selection, result);
            }
        }
        return result;
    }

    isolated function getResultForFragmentFromMap(map<any> parentValue, parser:FragmentNode parentNode, Data result) {
        string typeName = getTypeNameFromValue(parentValue);
        if parentNode.getOnType() != typeName {
            return;
        }
        foreach parser:SelectionNode selection in parentNode.getSelections() {
           if selection is parser:FieldNode {
                anydata fieldValue = self.getRecordResult(parentValue, selection);
                result[selection.getAlias()] = fieldValue is ErrorDetail ? () : fieldValue;
            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromMap(parentValue, selection, result);
            }
        }
    }

    isolated function getResultForFragmentFromService(service object {} parentValue, parser:FragmentNode parentNode,
                                                      Data result) {
        string typeName = getTypeNameFromValue(parentValue);
        if parentNode.getOnType() != typeName && !self.isPossibleTypeOfInterface(parentNode.getOnType(), typeName) {
            return;
        }
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            if selection is parser:FieldNode {
                anydata selectionValue = self.getResultFromObject(parentValue, selection);
                result[selection.getAlias()] = selectionValue is ErrorDetail ? () : selectionValue;
            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromService(parentValue, selection, result);
            }
        }
    }

    private isolated function isPossibleTypeOfInterface(string interfaceName, 
                                                        string implementedTypeName) returns boolean {
        __Type? interfaceType = getTypeFromTypeArray(self.engine.getSchema().types, interfaceName);
        if interfaceType is () || interfaceType.kind != INTERFACE {
            return false;
        }
        __Type[]? possibleTypes = interfaceType.possibleTypes;
        if possibleTypes is () {
            return false;
        }
        return getTypeFromTypeArray(possibleTypes, implementedTypeName) is __Type;
    }
}
