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
        self.visitDocument(self.documentNode);
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        parser:OperationNode[] operations = documentNode.getOperations();
        foreach parser:OperationNode operationNode in operations {
            self.visitOperation(operationNode);
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        self.removeDuplicateSelections(operationNode.getSelections());
        foreach parser:Selection selection in operationNode.getSelections() {
            self.visitSelection(selection);
        }
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        if selection is parser:FragmentNode {
            self.visitFragment(selection);
        } else {
            self.visitField(selection);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        self.removeDuplicateSelections(fieldNode.getSelections());
        foreach parser:Selection selection in fieldNode.getSelections() {
            self.visitSelection(selection);
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        self.removeDuplicateSelections(fragmentNode.getSelections());
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        // Do nothing
    }

    private isolated function removeDuplicateSelections(parser:Selection[] selections) {
        map<parser:FieldNode> visitedFields = {};
        map<parser:FragmentNode> visitedFragments = {};
        int i = 0;
        while i < selections.length() {
            parser:Selection selection = selections[i];
            if selection is parser:FragmentNode {
                if visitedFragments.hasKey(selection.getOnType()) {
                    self.appendDuplicateFragments(selection, visitedFragments.get(selection.getOnType()));
                    _ = selections.remove(i);
                    i -= 1;
                } else {
                    visitedFragments[selection.getOnType()] = selection;
                }
            } else {
                if visitedFields.hasKey(selection.getAlias()) {
                    self.appendDuplicateFields(selection, visitedFields.get(selection.getAlias()));
                    _ = selections.remove(i);
                    i -= 1;
                } else {
                    visitedFields[selection.getAlias()] = selection;
                }
            }
            i += 1;
        }
    }

    private isolated function appendDuplicateFields(parser:FieldNode duplicate, parser:FieldNode original) {
        foreach parser:Selection selection in duplicate.getSelections() {
            original.addSelection(selection);
        }
    }

    private isolated function appendDuplicateFragments(parser:FragmentNode duplicate, parser:FragmentNode original) {
        foreach parser:Selection selection in duplicate.getSelections() {
            original.addSelection(selection);
        }
    }
}
