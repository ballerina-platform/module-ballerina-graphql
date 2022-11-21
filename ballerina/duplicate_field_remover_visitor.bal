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
    private map<()> removedNodes;
    private map<parser:SelectionNode> modifiedSelections;

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
                    self.appendDuplicates(modifiedSelectionNode, visitedFields.get(modifiedSelectionNode.getAlias()));
                    self.removeNode(selections[i]);
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
}
