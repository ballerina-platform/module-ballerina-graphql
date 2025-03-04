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

import graphql.parser;

import ballerina/log;

isolated class ResponseGenerator {
    private final Engine engine;
    private final Context context;
    private final readonly & (string|int)[] path;
    private final readonly & __Type fieldType;
    private final readonly & ServerCacheConfig? cacheConfig;
    private final readonly & string[] parentArgHashes;

    private final string functionNameGetFragmentFromService = "";

    isolated function init(Engine engine, Context context, readonly & __Type fieldType,
            readonly & (string|int)[] path = [], ServerCacheConfig? cacheConfig = (),
            readonly & string[] parentArgHashes = []) {
        self.engine = engine;
        self.context = context;
        self.path = path;
        self.fieldType = fieldType;
        self.cacheConfig = cacheConfig;
        self.parentArgHashes = parentArgHashes;
    }

    isolated function getResult(any|error parentValue, parser:FieldNode parentNode, (string|int)[] path = [])
    returns anydata {
        if parentValue is ErrorDetail {
            return;
        }
        if parentValue is error {
            return self.addError(parentValue, parentNode, path);
        }
        if parentValue is Scalar || parentValue is Scalar[] {
            return parentValue;
        }
        if parentValue is map<any> {
            if isMap(parentValue) {
                return self.getResultFromMap(parentValue, parentNode, path);
            }
            return self.getResultFromRecord(parentValue, parentNode, path);
        }
        if parentValue is (any|error)[] {
            return self.getResultFromArray(parentValue, parentNode, path);
        }
        if parentValue is table<map<any>> {
            return self.getResultFromTable(parentValue, parentNode, path);
        }
        if parentValue is service object {} {
            return self.getResultFromService(parentValue, parentNode, path);
        }
    }

    isolated function getResultFromObject(any parentValue, parser:FieldNode fieldNode, (string|int)[] path = [])
    returns anydata {
        if fieldNode.getName() == TYPE_NAME_FIELD {
            return getTypeNameFromValue(parentValue);
        } else if parentValue is map<anydata> {
            if parentValue.hasKey(fieldNode.getName()) {
                return self.getResult(parentValue.get(fieldNode.getName()), fieldNode, path);
            } else if parentValue.hasKey(fieldNode.getAlias()) {
                // TODO: This is to handle results from hierarchical paths. Should find a better way to handle this.
                return self.getResult(parentValue.get(fieldNode.getAlias()), fieldNode, path);
            } else {
                return;
            }
        } else if parentValue is service object {} {
            readonly & (string|int)[] clonedPath = [...self.path, ...path, fieldNode.getAlias()];
            readonly & __Type parentType = self.fieldType;
            readonly & __Type fieldType = getFieldTypeFromParentType(parentType, self.engine.getSchema().types, fieldNode);
            Field 'field = new (fieldNode, fieldType, parentType, parentValue, clonedPath,
                cacheConfig = self.cacheConfig, parentArgHashes = self.parentArgHashes
            );
            return self.engine.resolve(self.context, 'field);
        }
    }

    isolated function addError(error err, parser:FieldNode fieldNode, (string|int)[] path = []) returns ErrorDetail {
        log:printError(err.message(), stackTrace = err.stackTrace());
        ErrorDetail errorDetail = {
            message: err.message(),
            locations: [fieldNode.getLocation()],
            path: path.length() == 0 ? self.path.clone() : [...self.path, ...path]
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

    isolated function getResultFromMap(map<any> parentValue, parser:FieldNode parentNode, (string|int)[] path = [])
    returns anydata {
        string? mapKey = getKeyArgument(parentNode);
        if mapKey is string {
            if parentValue.hasKey(mapKey) {
                return self.getResult(parentValue.get(mapKey), parentNode, path);
            } else {
                string message = string `The field "${parentNode.getName()}" is a map, but it does not contain the key "${mapKey}"`;
                return self.getResult(error(message), parentNode, path);
            }
        } else if parentValue is map<anydata> {
            return parentValue;
        }
    }

    isolated function getResultFromRecord(map<any> parentValue, parser:FieldNode parentNode, (string|int)[] path = [])
    returns anydata {
        Data result = {};
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            if selection is parser:FieldNode {
                anydata fieldValue = self.getRecordResult(parentValue, selection, path);
                result[selection.getAlias()] = fieldValue is ErrorDetail ? () : fieldValue;
            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromMap(parentValue, selection, result, path);
            }
        }
        return result;
    }

    isolated function getRecordResult(map<any> parentValue, parser:FieldNode fieldNode, (string|int)[] path = [])
        returns anydata {
        if fieldNode.getName() == TYPE_NAME_FIELD {
            return getTypeNameFromValue(parentValue);
        }
        any fieldValue = parentValue.hasKey(fieldNode.getName()) ? parentValue.get(fieldNode.getName()) : ();
        readonly & __Type parentType = self.fieldType;
        readonly & __Type fieldType = getFieldTypeFromParentType(parentType, self.engine.getSchema().types, fieldNode);
        boolean isAlreadyCached = isRecordWithNoOptionalFields(parentValue);
        readonly & (string|int)[] clonedPath = [...self.path, ...path, fieldNode.getAlias()];
        Field 'field = new (fieldNode, fieldType, parentType, path = clonedPath, fieldValue = fieldValue,
            cacheConfig = self.cacheConfig, parentArgHashes = self.parentArgHashes,
            isAlreadyCached = isAlreadyCached
        );
        return self.engine.resolve(self.context, 'field);
    }

    isolated function getResultFromArray((any|error)[] parentValue, parser:FieldNode parentNode,
            (string|int)[] path = []) returns anydata {
        int i = 0;
        anydata[] result = [];
        foreach any|error element in parentValue {
            path.push(i);
            anydata elementValue = self.getResult(element, parentNode, path);
            if elementValue is ErrorDetail {
                result.push(());
            } else {
                result.push(elementValue);
            }
            _ = path.pop();
            i += 1;
        }
        return result;
    }

    isolated function getResultFromTable(table<map<any>> parentValue, parser:FieldNode parentNode,
            (string|int)[] path = []) returns anydata {
        anydata[] result = [];
        foreach map<any> element in parentValue {
            anydata elementValue = self.getResult(element, parentNode, path);
            if elementValue is ErrorDetail {
                result.push(());
            } else {
                result.push(elementValue);
            }
        }
        return result;
    }

    isolated function getResultFromService(service object {} serviceObject, parser:FieldNode parentNode,
            (string|int)[] path = []) returns anydata {
        Data result = {};
        if serviceObject is isolated service object {} {
            return self.executeResourcesParallely(serviceObject, parentNode, path);
        }
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            if selection is parser:FieldNode {
                anydata selectionValue = self.getResultFromObject(serviceObject, selection, path);
                result[selection.getAlias()] = selectionValue is ErrorDetail ? () : selectionValue;
            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromService(serviceObject, selection, result, path);
            }
        }
        return result;
    }

    isolated function executeResourcesParallely(isolated service object {} serviceObject,
            parser:SelectionNode parentNode, (string|int)[] path = []) returns Data {
        Data result = {};
        [parser:FieldNode, future<anydata>][] selectionFutures = [];
        readonly & (string|int)[] clonedPath = [...path];
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            if selection is parser:FieldNode {
                future<anydata> 'future = start self.getResultFromObject(serviceObject, selection, clonedPath);
                selectionFutures.push([selection, 'future]);
            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromServiceParallely(serviceObject, selection, result, clonedPath);
            }
        }
        foreach [parser:FieldNode, future<anydata>] [selection, 'future] in selectionFutures {
            anydata|error fieldValue = wait 'future;
            if fieldValue is error {
                result[selection.getAlias()] = ();
                ErrorDetail errorDetail = {
                    message: fieldValue.message(),
                    locations: [selection.getLocation()],
                    path: clonedPath
                };
                self.context.addError(errorDetail);
                continue;
            }
            result[selection.getAlias()] = fieldValue is ErrorDetail ? () : fieldValue;
        }
        return result;
    }

    isolated function getResultForFragmentFromServiceParallely(isolated service object {} parentValue,
            parser:FragmentNode parentNode, Data result, (string|int)[] path = []) {
        string typeName = getTypeNameFromValue(parentValue);
        if parentNode.getOnType() != typeName && !self.isPossibleTypeOfInterface(parentNode.getOnType(), typeName) {
            return;
        }
        [parser:FieldNode, future<anydata>][] selections = [];
        readonly & (string|int)[] clonedPath = [...path];
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            if selection is parser:FieldNode {
                future<anydata> 'future = start self.getResultFromObject(parentValue, selection, clonedPath);
                selections.push([selection, 'future]);
            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromServiceParallely(parentValue, selection, result, clonedPath);
            }
        }
        foreach [parser:FieldNode, future<anydata>] [selection, 'future] in selections {
            anydata|error fieldValue = wait 'future;
            if fieldValue is error {
                result[selection.getAlias()] = ();
                ErrorDetail errorDetail = {
                    message: fieldValue.message(),
                    locations: [selection.getLocation()],
                    path: clonedPath
                };
                self.context.addError(errorDetail);
                continue;
            }
            result[selection.getAlias()] = fieldValue is ErrorDetail ? () : fieldValue;
        }
    }

    isolated function getResultForFragmentFromMap(map<any> parentValue, parser:FragmentNode parentNode, Data result,
            (string|int)[] path = []) {
        string typeName = getTypeNameFromValue(parentValue);
        if parentNode.getOnType() != typeName {
            return;
        }
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            if selection is parser:FieldNode {
                anydata fieldValue = self.getRecordResult(parentValue, selection, path);
                result[selection.getAlias()] = fieldValue is ErrorDetail ? () : fieldValue;
            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromMap(parentValue, selection, result, path);
            }
        }
    }

    isolated function getResultForFragmentFromService(service object {} parentValue, parser:FragmentNode parentNode,
            Data result, (string|int)[] path = []) {
        string typeName = getTypeNameFromValue(parentValue);
        if parentNode.getOnType() != typeName && !self.isPossibleTypeOfInterface(parentNode.getOnType(), typeName) {
            return;
        }
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            if selection is parser:FieldNode {
                anydata selectionValue = self.getResultFromObject(parentValue, selection, path);
                result[selection.getAlias()] = selectionValue is ErrorDetail ? () : selectionValue;
            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromService(parentValue, selection, result, path);
            }
        }
    }

    private isolated function isPossibleTypeOfInterface(string interfaceName,
            string implementedTypeName) returns boolean {
        readonly & __Type? interfaceType = getTypeFromTypeArray(self.engine.getSchema().types, interfaceName);
        if interfaceType is () || interfaceType.kind != INTERFACE {
            return false;
        }
        readonly & __Type[]? possibleTypes = interfaceType.possibleTypes;
        if possibleTypes is () {
            return false;
        }
        return getTypeFromTypeArray(possibleTypes, implementedTypeName) is __Type;
    }
}
