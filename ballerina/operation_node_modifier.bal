// Copyright (c) 2022 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

class OperationNodeModifierVisitor {
    *parser:Visitor;

    private map<parser:SelectionNode> modifiedSelections;
    private parser:OperationNode? operation;
    private map<()> removedNodes;

    isolated function init(map<parser:SelectionNode> modifiedSelections, map<()> removedNodes) {
        self.modifiedSelections = modifiedSelections;
        self.operation = ();
        self.removedNodes = removedNodes;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {}

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        parser:SelectionNode[] selections = self.getModifiedSelections(operationNode);
        self.operation = operationNode.modifyWithSelections(selections);
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        parser:FieldNode modifiedFieldNode = <parser:FieldNode>self.getModifiedNode(fieldNode);
        parser:SelectionNode[] selections = self.getModifiedSelections(modifiedFieldNode);
        modifiedFieldNode = modifiedFieldNode.modifyWithSelections(selections);
        self.addModifiedNode(fieldNode, modifiedFieldNode);
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        parser:FragmentNode modifiedFragmentNode = <parser:FragmentNode>self.getModifiedNode(fragmentNode);
        parser:SelectionNode[] selections = self.getModifiedSelections(modifiedFragmentNode);
        modifiedFragmentNode = modifiedFragmentNode.modifyWithSelections(selections);
        self.addModifiedNode(fragmentNode, modifiedFragmentNode);
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {}

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {}

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {}

    public isolated function getOperationNode() returns parser:OperationNode {
        return <parser:OperationNode>self.operation;
    }

    private isolated function addModifiedNode(parser:SelectionNode originalNode, parser:SelectionNode modifiedNode) {
        string hashCode = parser:getHashCode(originalNode);
        self.modifiedSelections[hashCode] = modifiedNode;
    }

    private isolated function getModifiedSelections(parser:SelectionParentNode parentNode)
    returns parser:SelectionNode[] {
        parser:SelectionNode[] selections = [];
        foreach parser:SelectionNode selectionNode in parentNode.getSelections() {
            if self.isRemovedNode(selectionNode) {
                continue;
            }
            selectionNode.accept(self);
            parser:SelectionNode selection = self.getModifiedNode(selectionNode);
            selections.push(selection);
        }
        return selections;
    }

    private isolated function isRemovedNode(parser:Node node) returns boolean {
        return self.removedNodes.hasKey(parser:getHashCode(node));
    }

    private isolated function getModifiedNode(parser:SelectionNode node) returns parser:SelectionNode {
        string hashCode = parser:getHashCode(node);
        return self.modifiedSelections.hasKey(hashCode) ? self.modifiedSelections.get(hashCode) : node;
    }
}
