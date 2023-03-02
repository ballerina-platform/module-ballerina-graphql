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
    private final boolean isMutationOperation;

    private final string functionNameGetSelectionFromRecord = "getSelectionFromRecord";
    private final string functionNameGetSelectionFromService = "getSelectionFromService";
    private final string functionNameGetFragmentFromService = "getFragmentFromService";

    isolated function init(Engine engine, Context context, __Type fieldType, (string|int)[] path = [],
                           boolean isMutationOperation = false) {
        self.engine = engine;
        self.context = context;
        self.path = path;
        self.fieldType = fieldType;
        self.isMutationOperation = isMutationOperation;
    }

    isolated function getResult(any|error parentValue, parser:FieldNode parentNode, (string|int)[] path = [])
    returns anydata {
        (string|int)[] clonedPath = path.length() > 0 ? path.clone() : self.path.clone();
        if parentValue is ErrorDetail {
            return;
        }
        if parentValue is error {
            return self.addError(parentValue, parentNode, clonedPath);
        }
        if parentValue is Scalar || parentValue is Scalar[] {
            return parentValue;
        }
        if parentValue is map<any> {
            if isMap(parentValue) {
                return self.getResultFromMap(parentValue, parentNode, clonedPath);
            }
            return self.getResultFromRecord(parentValue, parentNode, clonedPath);
        }
        if parentValue is (any|error)[] {
            return self.getResultFromArray(parentValue, parentNode, clonedPath);
        }
        if parentValue is table<map<any>> {
            return self.getResultFromTable(parentValue, parentNode, clonedPath);
        }
        if parentValue is service object {} {
            return self.getResultFromService(parentValue, parentNode, clonedPath);
        }
    }

    isolated function getResultFromObject(any parentValue, parser:FieldNode fieldNode, (string|int)[] path)
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
            (string|int)[] clonedPath = path.clone();
            clonedPath.push(fieldNode.getName());
            __Type fieldType = getFieldTypeFromParentType(self.fieldType, self.engine.getSchema().types, fieldNode);
            Field 'field = new (fieldNode, fieldType, parentValue, clonedPath);
            Context context = self.context.cloneWithoutErrors();
            context.resetInterceptorCount();
            anydata result = self.engine.resolve(context, 'field);
            self.context.addErrors(context.getErrors());
            return result;
        }
    }

    isolated function addError(error err, parser:FieldNode fieldNode, (string|int)[] path) returns ErrorDetail {
        log:printError(err.message(), stackTrace = err.stackTrace());
        ErrorDetail errorDetail = {
            message: err.message(),
            locations: [fieldNode.getLocation()],
            path: path.clone()
        };
        self.context.addError(errorDetail);
        return errorDetail;
    }

    isolated function getResultFromMap(map<any> parentValue, parser:FieldNode parentNode, (string|int)[] path)
    returns anydata {
        string? mapKey = self.getKeyArgument(parentNode);
        if mapKey is string {
            if parentValue.hasKey(mapKey) {
                return self.getResult(parentValue.get(mapKey), parentNode, path);
            } else {
                path.push(parentNode.getName());
                string message = string `The field "${parentNode.getName()}" is a map, but it does not contain the key "${mapKey}"`;
                var result = self.getResult(error(message), parentNode, path);
                _ = path.pop();
                return result;
            }
        } else if parentValue is map<anydata> {
            return parentValue;
        }
    }

    isolated function getResultFromRecord(map<any> parentValue, parser:FieldNode parentNode, (string|int)[] path)
    returns anydata {
        Data result = {};
        self.resolveSelections(self.functionNameGetSelectionFromRecord, parentValue, parentNode, result, path);
        return result;
    }

    isolated function getSelectionFromRecord(map<any> parentValue, parser:SelectionNode selection, Data result,
                                             (string|int)[] path) {
        if selection is parser:FieldNode {
            anydata fieldValue = self.getRecordResult(parentValue, selection, path);
            result[selection.getAlias()] = fieldValue is ErrorDetail ? () : fieldValue;
        } else if selection is parser:FragmentNode {
            self.getResultForFragmentFromMap(parentValue, selection, result, path.clone());
        }
    }

    isolated function getRecordResult(map<any> parentValue, parser:FieldNode fieldNode, (string|int)[] path)
    returns anydata {
        if fieldNode.getName() == TYPE_NAME_FIELD {
            return getTypeNameFromValue(parentValue);
        }
        any fieldValue = parentValue.hasKey(fieldNode.getName()) ? parentValue.get(fieldNode.getName()): ();
        __Type fieldType = getFieldTypeFromParentType(self.fieldType, self.engine.getSchema().types, fieldNode);
        Field 'field = new (fieldNode, fieldType, path = path.clone(), fieldValue = fieldValue);
        Context context = self.context.cloneWithoutErrors();
        context.resetInterceptorCount();
        anydata result = self.engine.resolve(context, 'field);
        self.context.addErrors(context.getErrors());
        return result;
    }

    isolated function getResultFromArray((any|error)[] parentValue, parser:FieldNode parentNode, (string|int)[] path)
    returns anydata {
        if !self.isMutationOperation {
            return self.getResultFromArrayParallelly(parentValue, parentNode, path);
        }
        int i = 0;
        anydata[] result = [];
        foreach any|error element in parentValue {
            path.push(i);
            anydata elementValue = self.getResult(element, parentNode, path.clone());
            i += 1;
            _ = path.pop();
            if elementValue is ErrorDetail {
                result.push(());
            } else {
                result.push(elementValue);
            }
        }
        return result;
    }

    isolated function getResultFromArrayParallelly((any|error)[] parentValue, parser:FieldNode parentNode, (string|int)[] path)
    returns anydata {
        int i = 0;
        anydata[] result = [];
        future<anydata>[] futures = [];
        var getResult = self.getResult;
        foreach any|error element in parentValue {
            path.push(i);
            future<anydata> 'future = start getResult(element, parentNode, path.clone());
            futures.push('future);
            i += 1;
            _ = path.pop();
        }
        foreach future<anydata> elementFuture in futures {
            anydata elementValue = checkpanic wait elementFuture;
            if elementValue is ErrorDetail {
                result.push(());
            } else {
                result.push(elementValue);
            }
        }
        return result;
    }

    isolated function getResultFromTable(table<map<any>> parentValue, parser:FieldNode parentNode, (string|int)[] path)
    returns anydata {
        if !self.isMutationOperation {
            return self.getResultFromTableParallelly(parentValue, parentNode, path);
        }
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

    isolated function getResultFromTableParallelly(table<map<any>> parentValue, parser:FieldNode parentNode,
                                                  (string|int)[] path) returns anydata {
        anydata[] result = [];
        future<anydata>[] futures = [];
        var getResult = self.getResult;
        foreach any element in parentValue {
            future<anydata> 'future = start getResult(element, parentNode, path);
            futures.push('future);
        }
        foreach future<anydata> elementFuture in futures {
            anydata elementValue = checkpanic wait elementFuture;
            if elementValue is ErrorDetail {
                result.push(());
            } else {
                result.push(elementValue);
            }
        }
        return result;
    }

    isolated function getResultFromService(service object {} serviceObject, parser:FieldNode parentNode,
                                           (string|int)[] path) returns anydata {
        Data result = {};
        self.resolveSelections(self.functionNameGetSelectionFromService, serviceObject, parentNode, result, path);
        return result;
    }

    isolated function getSelectionFromService(service object {} serviceObject, parser:SelectionNode selection,
                                              Data result, (string|int)[] path) {
        if selection is parser:FieldNode {
            anydata selectionValue = self.getResultFromObject(serviceObject, selection, path.clone());
            result[selection.getAlias()] = selectionValue is ErrorDetail ? () : selectionValue;
        } else if selection is parser:FragmentNode {
            self.getResultForFragmentFromService(serviceObject, selection, result, path.clone());
        }
    }

    isolated function getResultForFragmentFromMap(map<any> parentValue, parser:FragmentNode parentNode, Data result,
                                                  (string|int)[] path) {
        string typeName = getTypeNameFromValue(parentValue);
        if parentNode.getOnType() != typeName {
            return;
        }
        self.resolveSelections(self.functionNameGetSelectionFromRecord, parentValue, parentNode, result, path);
    }

    isolated function getResultForFragmentFromService(service object {} parentValue, parser:FragmentNode parentNode,
                                                      Data result, (string|int)[] path) {
        string typeName = getTypeNameFromValue(parentValue);
        if parentNode.getOnType() != typeName && !self.isPossibleTypeOfInterface(parentNode.getOnType(), typeName) {
            return;
        }
        self.resolveSelections(self.functionNameGetFragmentFromService, parentValue, parentNode, result, path);
    }

    isolated function getFragmentFromService(service object {} parentValue, parser:SelectionNode selection, Data result,
                                             (string|int)[] path) {
        if selection is parser:FieldNode {
            anydata selectionValue = self.getResultFromObject(parentValue, selection, path.clone());
            result[selection.getAlias()] = selectionValue is ErrorDetail ? () : selectionValue;
        } else if selection is parser:FragmentNode {
            self.getResultForFragmentFromService(parentValue, selection, result, path.clone());
        }
    }

    private isolated function resolveSelections(string selectionFunctionName,
                                                        map<any>|service object {} parentValue,
                                                        parser:SelectionNode parentNode, Data result,
                                                        (string|int)[] path) {
        if !self.isMutationOperation {
            return self.resolveSelectionsParalley(selectionFunctionName, parentValue, parentNode, result, path);
        }
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            var executeSelectionFunction = self.executeSelectionFunction;
            executeSelectionFunction(selectionFunctionName, parentValue, selection, result, path);
        }
        return;
    }

    private isolated function resolveSelectionsParalley(string selectionFunctionName,
                                                        map<any>|service object {} parentValue,
                                                        parser:SelectionNode parentNode, Data result,
                                                        (string|int)[] path) {
        future<()>[] futures = [];
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            var executeSelectionFunction = self.executeSelectionFunction;
            future<()> 'future = start executeSelectionFunction(selectionFunctionName, parentValue, selection, result,
                                                                path);
            futures.push('future);
        }
        foreach future<()> 'future in futures {
            _ = checkpanic wait 'future;
        }
    }

    private isolated function executeSelectionFunction(string functionName, map<any>|service object {} parentValue,
                                                       parser:SelectionNode selection, Data result, (string|int)[] path)
     {
            if functionName == self.functionNameGetSelectionFromRecord {
                return self.getSelectionFromRecord(<map<any>>parentValue, selection, result, path.clone());
            }
            if functionName ==  self.functionNameGetSelectionFromService {
                return self.getSelectionFromService(<service object {}>parentValue, selection, result, path.clone());
            }
            if functionName ==  self.functionNameGetFragmentFromService {
                return self.getFragmentFromService(<service object {}>parentValue, selection, result, path.clone());
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

    // TODO: This returns () for the hierarchiacal paths. Find a better way to handle this.
    isolated function getKeyArgument(parser:FieldNode fieldNode) returns string? {
        if fieldNode.getArguments().length() == 0 {
            return;
        }
        parser:ArgumentNode argumentNode = fieldNode.getArguments()[0];
        if argumentNode.isVariableDefinition() {
            return <string>argumentNode.getVariableValue();
        } else {
            return <string>argumentNode.getValue();
        }
    }
}
