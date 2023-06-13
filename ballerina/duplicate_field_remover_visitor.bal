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

class DuplicateFieldRemoverVisitor {
    *parser:Visitor;

    private final map<()> removedNodes;
    private final map<parser:SelectionNode> modifiedSelections;
    private final ErrorDetail[] errors = [];

    isolated function init(map<()> removedNodes, map<parser:SelectionNode> modifiedSelections) {
        self.removedNodes = removedNodes;
        self.modifiedSelections = modifiedSelections;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        foreach parser:OperationNode operationNode in documentNode.getOperations() {
            if self.isRemovedNode(operationNode) {
                continue;
            }
            operationNode.accept(self);
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        self.removeDuplicateSelections(operationNode.getSelections());
        foreach parser:SelectionNode selection in operationNode.getSelections() {
            if self.isRemovedNode(selection) {
                continue;
            }
            selection.accept(self);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        parser:SelectionNode modifiedFieldNode = self.getModifiedNode(fieldNode);
        self.removeDuplicateSelections(modifiedFieldNode.getSelections());
        foreach parser:SelectionNode selection in modifiedFieldNode.getSelections() {
            if self.isRemovedNode(selection) {
                continue;
            }
            selection.accept(self);
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        parser:SelectionNode modifiedFragmentNode = self.getModifiedNode(fragmentNode);
        self.removeDuplicateSelections(modifiedFragmentNode.getSelections());
        foreach parser:SelectionNode selection in modifiedFragmentNode.getSelections() {
            if self.isRemovedNode((selection)) {
                continue;
            }
            selection.accept(self);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {}

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {}

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {}

    public isolated function getErrors() returns ErrorDetail[]? {
        return self.errors.length() > 0 ? self.errors : ();
    }

    private isolated function removeDuplicateSelections(parser:SelectionNode[] selections) {
        map<parser:FieldNode> visitedFields = {};
        map<parser:FragmentNode> visitedFragments = {};
        int i = 0;
        while i < selections.length() {
            if self.isRemovedNode(selections[i]) {
                i += 1;
                continue;
            }
            parser:SelectionNode modifiedSelectionNode = self.getModifiedNode(selections[i]);
            if modifiedSelectionNode is parser:FragmentNode {
                if visitedFragments.hasKey(modifiedSelectionNode.getOnType()) {
                    self.appendDuplicates(modifiedSelectionNode, visitedFragments.get(modifiedSelectionNode.getOnType()));
                    self.removeNode(selections[i]);
                } else {
                    visitedFragments[modifiedSelectionNode.getOnType()] = modifiedSelectionNode;
                }
            } else if modifiedSelectionNode is parser:FieldNode {
                if visitedFields.hasKey(modifiedSelectionNode.getAlias()) {
                    parser:FieldNode visitedField = visitedFields.get(modifiedSelectionNode.getAlias());
                    if self.hasDuplicateArguments(visitedField, modifiedSelectionNode) {
                        self.appendDuplicates(modifiedSelectionNode, visitedField);
                        self.removeNode(selections[i]);
                    } else {
                        string message = string `Fields "${modifiedSelectionNode.getAlias()}" conflict because they have differing arguments. ` +
                                         string `Use different aliases on the fields to fetch both if this was intentional.`;
                        self.errors.push(getErrorDetailRecord(message, modifiedSelectionNode.getLocation()));
                    }
                } else {
                    visitedFields[modifiedSelectionNode.getAlias()] = modifiedSelectionNode;
                }
            } else {
                panic error("Invalid selection node passed.");
            }
            i += 1;
        }
    }

    private isolated function appendDuplicates(parser:SelectionParentNode duplicate, parser:SelectionParentNode original) {
        if duplicate is parser:FieldNode && original is parser:FieldNode {
            string hashCode = parser:getHashCode(original);
            parser:FieldNode modifiedOriginalNode = self.modifiedSelections.hasKey(hashCode) ? <parser:FieldNode>self.modifiedSelections.get(hashCode) : original;
            parser:SelectionNode[] combinedSelections = [...modifiedOriginalNode.getSelections(), ...duplicate.getSelections()];
            parser:FieldNode latestModifiedOriginalNode = modifiedOriginalNode.modifyWithSelections(combinedSelections);
            self.modifiedSelections[hashCode] = latestModifiedOriginalNode;
        }
        if duplicate is parser:FragmentNode && original is parser:FragmentNode {
            string hashCode = parser:getHashCode(original);
            parser:FragmentNode modifiedOriginalNode = self.modifiedSelections.hasKey(hashCode) ? <parser:FragmentNode>self.modifiedSelections.get(hashCode) : original;
            parser:SelectionNode[] combinedSelections = [...modifiedOriginalNode.getSelections(), ...duplicate.getSelections()];
            parser:FragmentNode latestModifiedOriginalNode = modifiedOriginalNode.modifyWithSelections(combinedSelections);
            self.modifiedSelections[hashCode] = latestModifiedOriginalNode;
        }
    }

    private isolated function removeNode(parser:Node node) {
        self.removedNodes[parser:getHashCode(node)] = ();
    }

    private isolated function isRemovedNode(parser:Node node) returns boolean {
        return self.removedNodes.hasKey(parser:getHashCode(node));
    }

    private isolated function getModifiedNode(parser:SelectionNode selectionNode) returns parser:SelectionNode {
        string hashCode = parser:getHashCode(selectionNode);
        return self.modifiedSelections.hasKey(hashCode) ? self.modifiedSelections.get(hashCode) : selectionNode;
    }

    private isolated function hasDuplicateArguments(parser:FieldNode fieldNode, parser:FieldNode duplicateNode) returns boolean {
        if fieldNode.getArguments().length() != duplicateNode.getArguments().length() {
            return false;
        }
        foreach parser:ArgumentNode argNode in fieldNode.getArguments() {
            parser:ArgumentNode? duplicateArgNode = self.getArgNode(duplicateNode.getArguments(), argNode.getName());
            if duplicateArgNode is parser:ArgumentNode {
                if !self.isDuplicateArgValue(argNode, duplicateArgNode) {
                    return false;
                }
            } else {
                return false;
            }
        }
        return true;
    }

    private isolated function isDuplicateArgValue(parser:ArgumentNode original, parser:ArgumentNode duplicate) returns boolean {
        if original.getVariableName() is string || duplicate.getVariableName() is string  {
            return original.getVariableName() == duplicate.getVariableName();
        }
        parser:ArgumentValue|parser:ArgumentValue[] originalValue = original.getValue();
        parser:ArgumentValue|parser:ArgumentValue[] duplicateValue = duplicate.getValue();
        if originalValue is parser:ArgumentValue && duplicateValue is parser:ArgumentValue {
            if originalValue is parser:ArgumentNode && duplicateValue is parser:ArgumentNode {
                return self.isDuplicateArgValue(originalValue, duplicateValue);
            } else if originalValue is Scalar? && duplicateValue is Scalar? {
                return originalValue == duplicateValue;
            }
        } else if originalValue is parser:ArgumentValue[] && duplicateValue is parser:ArgumentValue[] {
            return self.isDuplicateArray(originalValue, duplicateValue);
        }
        return false;
    }

    private isolated function isDuplicateArray(parser:ArgumentValue[] originalValue, parser:ArgumentValue[] duplicateValue) returns boolean {
        if originalValue.length() != duplicateValue.length() {
            return false;
        }
        int i = 0;
        while i < originalValue.length() {
            parser:ArgumentValue originalArrayValue = originalValue[i];
            parser:ArgumentValue duplicateArrayValue = duplicateValue[i];
            if originalArrayValue is parser:ArgumentNode && duplicateArrayValue is parser:ArgumentNode {
                if !self.isDuplicateArgValue(originalArrayValue, duplicateArrayValue) {
                    return false;
                }
            } else if originalArrayValue is Scalar? && duplicateArrayValue is Scalar? {
                if originalArrayValue != duplicateArrayValue {
                    return false;
                }
            } else {
                return false;
            }
            i += 1;
        }
        return true;
    }

    private isolated function getArgNode(parser:ArgumentNode[] arguments, string argName) returns parser:ArgumentNode? {
        foreach parser:ArgumentNode argNode in arguments {
            if argNode.getName() == argName {
                return argNode;
            }
        }
        return;
    }
}
