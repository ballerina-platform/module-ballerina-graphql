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

class ResponseGenerator {
    private final Engine engine;
    private final Context context;
    private ErrorDetail[] errors;
    private (string|int)[] path;
    private final __Type fieldType;

    isolated function init(Engine engine, Context context, __Type fieldType, (string|int)[] path = []) {
        self.engine = engine;
        self.context = context;
        self.errors = [];
        self.path = path;
        self.fieldType = fieldType;
    }

    isolated function getResult(any|error parentValue, parser:FieldNode parentNode) returns anydata {
        if parentValue is ErrorDetail {
            return;
        }
        if parentValue is error {
            return self.addError(parentValue, parentNode);
        }
        if parentValue is Scalar || parentValue is Scalar[] {
            return parentValue;
        }
        if parentValue is map<anydata> {
            return self.getResultFromMap(parentValue, parentNode);
        }
        if parentValue is (any|error)[] {
            return self.getResultFromArray(parentValue, parentNode);
        }
        if parentValue is table<map<anydata>> {
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
            (string|int)[] path = self.path.clone();
            path.push(fieldNode.getName());
            __Type fieldType = getFieldTypeFromParentType(self.fieldType, self.engine.getSchema().types, fieldNode);
            Field 'field = new (fieldNode, parentValue, fieldType, path);
            self.context.resetInterceptorCount();
            return self.engine.resolve(self.context, 'field);
        }
    }

    isolated function addError(error err, parser:FieldNode fieldNode) returns ErrorDetail {
        ErrorDetail errorDetail = {
            message: err.message(),
            locations: [fieldNode.getLocation()],
            path: self.path.clone()
        };
        self.context.addError(errorDetail);
        return errorDetail;
    }

    isolated function getResultFromMap(map<anydata> parentValue, parser:FieldNode parentNode) returns anydata {
        if isMap(parentValue) {
            string? mapKey = self.getKeyArgument(parentNode);
            if mapKey is string {
                return self.getResult(parentValue.get(mapKey), parentNode);
            } else {
                return parentValue;
            }
        }
        Data result = {};
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            if selection is parser:FieldNode {
                anydata selectionValue = self.getResultFromObject(parentValue, selection);
                result[selection.getAlias()] = selectionValue is ErrorDetail ? () : selectionValue;
            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromMap(parentValue, selection, result);
            }
        }
        return result;
    }

    isolated function getResultFromArray((any|error)[] parentValue, parser:FieldNode parentNode) returns anydata {
        anydata[] result = [];
        int i = 0;
        foreach any|error element in parentValue {
            self.path.push(i);
            anydata elementValue = self.getResult(element, parentNode);
            if elementValue is ErrorDetail {
                result.push(());
            } else {
                result.push(elementValue);
            }
            i += 1;
            _ = self.path.pop();
        }
        return result;
    }

    isolated function getResultFromTable(table<map<anydata>> parentValue, parser:FieldNode parentNode) returns anydata {
        anydata[] result = [];
        foreach anydata element in parentValue {
            anydata elementValue = self.getResult(element, parentNode);
            if elementValue is ErrorDetail {
                result.push(());
            } else {
                result.push(elementValue);
            }
        }
        return result;
    }

    isolated function getResultFromService(service object {} serviceObject, parser:FieldNode parentNode)
    returns anydata {
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

    isolated function getResultForFragmentFromMap(map<anydata> parentValue,
                                                  parser:FragmentNode parentNode, Data result) {
        string typeName = getTypeNameFromValue(parentValue);
        if parentNode.getOnType() != typeName {
            return;
        }
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            if selection is parser:FieldNode {
                anydata selectionValue = self.getResultFromObject(parentValue, selection);
                result[selection.getAlias()] = selectionValue is ErrorDetail ? () : selectionValue;
            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromMap(parentValue, selection, result);
            }
        }
    }

    isolated function getResultForFragmentFromService(service object {} parentValue,
                                                      parser:FragmentNode parentNode, Data result) {
        string typeName = getTypeNameFromValue(parentValue);
        if parentNode.getOnType() != typeName {
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
