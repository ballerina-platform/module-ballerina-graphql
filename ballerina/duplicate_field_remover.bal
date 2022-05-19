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

class DuplicateFieldRemover {
    *parser:Visitor;

    private parser:DocumentNode documentNode;

    public isolated function init(parser:DocumentNode documentNode) {
        self.documentNode = documentNode;
    }

    public isolated function remove() {
        self.documentNode.accept(self);
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        foreach parser:OperationNode operationNode in documentNode.getOperations() {
            operationNode.accept(self);
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        self.removeDuplicateSelections(operationNode.getSelections());
        foreach parser:SelectionNode selection in operationNode.getSelections() {
            selection.accept(self);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        self.removeDuplicateSelections(fieldNode.getSelections());
        foreach parser:SelectionNode selection in fieldNode.getSelections() {
            selection.accept(self);
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        self.removeDuplicateSelections(fragmentNode.getSelections());
        foreach parser:SelectionNode selection in fragmentNode.getSelections() {
            selection.accept(self);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        // Do nothing
    }

    private isolated function removeDuplicateSelections(parser:SelectionNode[] selections) {
        map<parser:FieldNode> visitedFields = {};
        map<parser:FragmentNode> visitedFragments = {};
        int i = 0;
        while i < selections.length() {
            parser:SelectionNode selection = selections[i];
            if selection is parser:FragmentNode {
                if visitedFragments.hasKey(selection.getOnType()) {
                    self.appendDuplicates(selection, visitedFragments.get(selection.getOnType()));
                    _ = selections.remove(i);
                    i -= 1;
                } else {
                    visitedFragments[selection.getOnType()] = selection;
                }
            } else if selection is parser:FieldNode {
                if visitedFields.hasKey(selection.getAlias()) {
                    self.appendDuplicates(selection, visitedFields.get(selection.getAlias()));
                    _ = selections.remove(i);
                    i -= 1;
                } else {
                    visitedFields[selection.getAlias()] = selection;
                }
            } else {
                panic error("Invalid selection node passed.");
            }
            i += 1;
        }
    }

    private isolated function appendDuplicates(parser:SelectionParentNode duplicate, parser:SelectionParentNode original) {
        foreach parser:SelectionNode selection in duplicate.getSelections() {
            original.addSelection(selection);
        }
    }

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {
        // Do nothing
    }

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {
        // Do nothing
    }
}
