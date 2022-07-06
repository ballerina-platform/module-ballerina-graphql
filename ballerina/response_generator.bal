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

    isolated function init(Engine engine, Context context) {
        self.engine = engine;
        self.context = context;
        self.errors = [];
    }

    isolated function getResult(any|error parentValue, parser:FieldNode parentNode) returns anydata {
        if parentValue is error {
            return self.addError(parentValue, parentNode);
        }
        if parentValue is Scalar || parentValue is Scalar[] {
            return parentValue;
        }
        if parentValue is map<anydata> {
            return self.getResultFromMap(parentValue, parentNode);
        }
        if parentValue is any[] {
            return self.getResultFromArray(parentValue, parentNode);
        }
        if parentValue is service object {} {
            return self.getResultFromService(parentValue, parentNode);
        }
    }

    isolated function addError(error err, parser:FieldNode fieldNode) returns ErrorDetail {
        ErrorDetail errorDetail = {
            message: err.message(),
            locations: [fieldNode.getLocation()],
            path: [] // TODO: Path
        };
        self.context.addError(errorDetail);
        return errorDetail;
    }

    isolated function getResultFromMap(map<anydata> parentValue, parser:FieldNode parentNode) returns anydata {
        Data result = {};
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            if selection is parser:FieldNode {
                anydata selectionValue = self.getResult(parentValue.get(selection.getName()), selection);
                result[selection.getAlias()] = selectionValue is ErrorDetail ? () : selectionValue;

            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromMap(parentValue, selection, result);
            }
        }
        return result;
    }

    isolated function getResultFromArray(any[] parentValue, parser:FieldNode parentNode) returns anydata {
        anydata[] result = [];
        foreach any element in parentValue {
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
                Field 'field = new (selection, serviceObject);
                anydata selectionValue = self.engine.resolve(self.context, 'field);
                result[selection.getAlias()] = selectionValue is ErrorDetail ? () : selectionValue;
            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromService(serviceObject, selection, result);
            }
        }
        return result;
    }

    isolated function getResultForFragmentFromMap(map<anydata> parentValue,
                                                  parser:FragmentNode parentNode, Data result) {
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            if selection is parser:FieldNode {
                anydata selectionValue = self.getResult(parentValue.get(selection.getName()), selection);
                result[selection.getAlias()] = selectionValue is ErrorDetail ? () : selectionValue;
            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromMap(parentValue, selection, result);
            }
        }
    }

    isolated function getResultForFragmentFromService(service object {} parentValue,
                                                      parser:FragmentNode parentNode, Data result) {
        foreach parser:SelectionNode selection in parentNode.getSelections() {
            if selection is parser:FieldNode {
                Field 'field = new (selection, parentValue);
                anydata selectionValue = self.getResult(self.engine.resolve(self.context, 'field), selection);
                result[selection.getAlias()] = selectionValue is ErrorDetail ? () : selectionValue;
            } else if selection is parser:FragmentNode {
                self.getResultForFragmentFromService(parentValue, selection, result);
            }
        }
    }
}
