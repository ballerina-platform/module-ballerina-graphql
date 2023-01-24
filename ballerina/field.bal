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

# Represents the information about a particular field of a GraphQL document.
public class Field {
    private final parser:RootOperationType operationType;
    private final parser:FieldNode internalNode;
    private final service object {}? serviceObject;
    private final any|error fieldValue;
    private final __Type fieldType;
    private (string|int)[] path;
    private string[] resourcePath;

    isolated function init(parser:FieldNode internalNode, __Type fieldType, service object {}? serviceObject = (),
                           (string|int)[] path = [], parser:RootOperationType operationType = parser:OPERATION_QUERY,
                           string[] resourcePath = [], any|error fieldValue = ()) {
        self.internalNode = internalNode;
        self.serviceObject = serviceObject;
        self.fieldType = fieldType;
        self.path = path;
        self.operationType = operationType;
        self.resourcePath = resourcePath;
        self.fieldValue = fieldValue;
        self.resourcePath.push(internalNode.getName());
    }

    # Returns the name of the field.
    # + return - The name of the field
    public isolated function getName() returns string {
        return self.internalNode.getName();
    }

    # Returns the effective alias of the field.
    # + return - The alias of the field. If an alias is not present, the field name will be returned
    public isolated function getAlias() returns string {
        return self.internalNode.getAlias();
    }

    # Returns the current path of the field. If the field returns an array, the path will include the index of the
    # element.
    # + return - The path of the field
    public isolated function getPath() returns (string|int)[] {
        return self.path;
    }

    # Returns the names of the subfields of this field as a string array.
    # + return - The names of the subfields of this field
    public isolated function getSubFieldNames() returns string[] {
        return self.getFieldNames(self.internalNode);
    }

    # Returns the type of the field.
    # + return - The type of the field
    public isolated function getType() returns __Type {
        return self.fieldType;
    }

    isolated function getInternalNode() returns parser:FieldNode {
        return self.internalNode;
    }

    isolated function getServiceObject() returns service object {}? {
        return self.serviceObject;
    }

    isolated function getOperationType() returns parser:RootOperationType {
        return self.operationType;
    }

    isolated function getResourcePath() returns string[] {
        return self.resourcePath;
    }

    isolated function getFieldType() returns __Type {
        return self.fieldType;
    }

    isolated function getFieldValue() returns any|error {
        return self.fieldValue;
    }

    isolated function getFieldNames(parser:SelectionNode selectionNode) returns string[] {
        string[] result = [];
        foreach parser:SelectionNode selection in selectionNode.getSelections() {
            if selection is parser:FieldNode {
                result.push(selection.getName());
            } else {
                foreach parser:SelectionNode fragmentSelectionNode in selectionNode.getSelections() {
                    result.push(...self.getFieldNames(fragmentSelectionNode));
                }
            }
        }
        return result;
    }
}
