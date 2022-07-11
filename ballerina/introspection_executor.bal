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

    isolated function getTypeIntrospection(parser:FieldNode fieldNode) returns Data {
        Data result = {};
        parser:ArgumentNode argNode = fieldNode.getArguments()[0];
        parser:ArgumentValue argValue = <parser:ArgumentValue> argNode.getValue();
        string requiredTypeName = argValue.toString();
        __Type? requiredType = getTypeFromTypeArray(self.schema.types, requiredTypeName);
        if requiredType is () {
            return result;
        }
        foreach parser:SelectionNode selectionNode in fieldNode.getSelections() {
            self.getValueFromSelectionNode(selectionNode, requiredType, result);
        }
        return result;
    }

    isolated function getValueFromSelectionNode(parser:SelectionNode selectionNode, map<anydata> value, Data result) {
        if selectionNode is parser:FieldNode {
            self.getValueFromFieldNode(selectionNode, value, result);
        } else if selectionNode is parser:FragmentNode {
            self.getValueFromFragmentNode(selectionNode, value, result);
        }
    }

    isolated function getValueFromFieldNode(parser:FieldNode fieldNode, map<anydata> parentValue, Data result) {
        anydata fieldValue = parentValue.get(fieldNode.getName());
        self.getFieldValue(fieldNode, fieldValue, result);
    }

    isolated function getValueFromFragmentNode(parser:FragmentNode fragmentNode, map<anydata> value, Data result) {
        foreach parser:SelectionNode selectionNode in fragmentNode.getSelections() {
            self.getValueFromSelectionNode(selectionNode, value, result);
        }
    }

    isolated function getFieldValue(parser:FieldNode fieldNode, anydata fieldValue, Data result) {
        if fieldValue is anydata[] {
            self.getValueFromArray(fieldNode, fieldValue, result);
        } else if fieldValue is map<anydata> {
            self.getValueFromMap(fieldNode, fieldValue, result);
        } else {
            result[fieldNode.getAlias()] = fieldValue;
        }
    }

    isolated function getValueFromMap(parser:FieldNode fieldNode, map<anydata> fieldValue, Data result) {
        Data child = {};
        boolean includeDeprecatedValue = includeDeprecated(fieldNode);
        boolean isDeprecatedValue = isDeprecated(fieldValue);
        if isDeprecatedValue && !includeDeprecatedValue {
            return;
        }
        foreach parser:SelectionNode selectionNode in fieldNode.getSelections() {
            self.getValueFromSelectionNode(selectionNode, fieldValue, child);
        }
        result[fieldNode.getAlias()] = child;
    }

    isolated function getValueFromArray(parser:FieldNode fieldNode, anydata[] values, Data result) {
        anydata[] resultArray = [];
        foreach anydata element in values {
            Data elementResult = {};
            self.getFieldValue(fieldNode, element, elementResult);
            if elementResult.hasKey(fieldNode.getAlias()) {
                resultArray.push(elementResult.get(fieldNode.getAlias()));
            }
        }
        result[fieldNode.getAlias()] = resultArray;
    }
}


isolated function isDeprecated(map<anydata> value) returns boolean {
    return value.hasKey(IS_DEPRECATED_FIELD) && <boolean>value.get(IS_DEPRECATED_FIELD);
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
