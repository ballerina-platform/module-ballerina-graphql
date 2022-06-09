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

class IntrospectionExecutor {

    private __Schema schema;

    isolated function init(__Schema schema) {
        self.schema = schema;
    }

    isolated function getSchemaIntrospection(parser:FieldNode fieldNode) returns Data {
        Data result = {};
        foreach parser:SelectionNode selectionNode in fieldNode.getSelections() {
            self.getValueFromSelectionNode(selectionNode, self.schema, result);
        }
        return result;
    }

    isolated function getTypeIntrospection(parser:FieldNode fieldNode) {

    }

    isolated function getValueFromSelectionNode(parser:SelectionNode selectionNode, map<anydata> value, Data parent) {
        if selectionNode is parser:FieldNode {
            self.getValueFromFieldNode(selectionNode, value, parent);
        } else if selectionNode is parser:FragmentNode {
            self.getValueFromFragmentNode(selectionNode, value, parent);
        }
    }

    isolated function getValueFromFieldNode(parser:FieldNode fieldNode, map<anydata> parentValue, Data parent) {
        anydata fieldValue = parentValue.get(fieldNode.getName());
        if fieldValue is anydata[] {
            self.getValueFromArray(fieldNode, fieldValue, parent);
        } else if fieldValue is map<anydata> {
            boolean includeDeprecatedValue = includeDeprecated(fieldNode);
            boolean isDeprecatedValue = isDeprecated(fieldValue);
            if isDeprecatedValue && !includeDeprecatedValue {
                return;
            }
            self.getValueFromMap(fieldNode, fieldValue, parent);
        } else {
            parent[fieldNode.getAlias()] = fieldValue;
        }
    }

    isolated function getValueFromFragmentNode(parser:FragmentNode fragmentNode, map<anydata> value, Data parent) {
        foreach parser:SelectionNode selectionNode in fragmentNode.getSelections() {
            self.getValueFromSelectionNode(selectionNode, value, parent);
        }
    }

    isolated function getValueFromMap(parser:FieldNode fieldNode, map<anydata> fieldValue, Data parent) {
        Data child = {};
        foreach parser:SelectionNode selectionNode in fieldNode.getSelections() {
            self.getValueFromSelectionNode(selectionNode, fieldValue, child);
        }
        parent[fieldNode.getAlias()] = child;
    }

    isolated function getValueFromArray(parser:FieldNode fieldNode, anydata[] values, Data parent) {
        anydata[] children = [];
        foreach anydata data in values {
            if data is map<anydata> {
                Data child = {};
                foreach parser:SelectionNode selectionNode in fieldNode.getSelections() {
                    self.getValueFromSelectionNode(selectionNode, data, child);
                }
                children.push(child);
            } else {
                children.push(data);
            }
        }
        parent[fieldNode.getAlias()] = children;
    }
}


isolated function isDeprecated(map<anydata> value) returns boolean {
    if value.hasKey(IS_DEPRECATED_FIELD) {
        return <boolean>value.get(IS_DEPRECATED_FIELD);
    }
    return false;
}

isolated function includeDeprecated(parser:FieldNode fieldNode) returns boolean {
    parser:ArgumentNode[] arguments = fieldNode.getArguments();
    foreach parser:ArgumentNode argumentNode in arguments {
        if argumentNode.getName() == INCLUDE_DEPRECATED_ARGUMENT {
            if argumentNode.isVariableDefinition() {
                return <boolean>argumentNode.getVariableValue();
            } else {
                return <boolean>argumentNode.getValue();
            }
        }
    }
    return false;
}
