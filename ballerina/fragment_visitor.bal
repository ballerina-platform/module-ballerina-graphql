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

class FragmentVisitor {
    *parser:Visitor;

    private ErrorDetail[] errors;
    private map<parser:FragmentNode> usedFragments;
    private parser:DocumentNode documentNode;
    private string[] visitedFragments;

    public isolated function init(parser:DocumentNode documentNode) {
        self.errors = [];
        self.usedFragments = {};
        self.documentNode = documentNode;
        self.visitedFragments = [];
    }

    public isolated function validate() returns ErrorDetail[]? {
        foreach parser:FragmentNode fragmentNode in self.documentNode.getFragments() {
            map<parser:FragmentNode> visitedSpreads = {};
            if !fragmentNode.isInlineFragment() && self.visitedFragments.indexOf(fragmentNode.getName()) is () {
                visitedSpreads[fragmentNode.getName()] = fragmentNode;
                self.detectCycles(fragmentNode, visitedSpreads);
            }
        }
        if self.errors.length() > 0 {
            return self.errors;
        }
        self.documentNode.accept(self);
        if self.errors.length() > 0 {
            return self.errors;
        }
        return;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        self.documentNode = documentNode;
        foreach parser:OperationNode operation in documentNode.getOperations() {
            operation.accept(self);
        }

        foreach [string, parser:FragmentNode] entry in documentNode.getFragments().entries() {
            if !self.usedFragments.hasKey(entry[0]) {
                string message = string`Fragment "${entry[0]}" is never used.`;
                ErrorDetail errorDetail = getErrorDetailRecord(message, entry[1].getLocation());
                self.errors.push(errorDetail);
            }
            _ = documentNode.getFragments().remove(entry[0]);
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        foreach parser:SelectionNode selection in operationNode.getSelections() {
            selection.accept(self);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        foreach parser:SelectionNode selection in fieldNode.getSelections() {
            selection.accept(self);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        // Do Nothing
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        self.appendNamedFragmentFields(fragmentNode);
        self.usedFragments[fragmentNode.getName()] = fragmentNode;
        foreach parser:SelectionNode selection in fragmentNode.getSelections() {
            selection.accept(self);
        }
    }

    isolated function appendNamedFragmentFields(parser:FragmentNode fragmentNode) {
        parser:DocumentNode documentNode = self.documentNode;
        parser:FragmentNode? actualFragmentNode = documentNode.getFragment(fragmentNode.getName());
        if actualFragmentNode is () {
            string message = string`Unknown fragment "${fragmentNode.getName()}".`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, fragmentNode.getLocation());
            self.errors.push(errorDetail);
        } else {
            if !fragmentNode.isInlineFragment() && fragmentNode.getSelections().length() == 0 {
                self.appendFields(actualFragmentNode, fragmentNode);
            }
        }
    }

    isolated function appendFields(parser:FragmentNode actualFragmentNode, parser:FragmentNode fragmentNode) {
        fragmentNode.setOnType(actualFragmentNode.getOnType());
        foreach parser:SelectionNode fragmentSelection in actualFragmentNode.getSelections() {
            fragmentNode.addSelection(fragmentSelection);
        }
        foreach parser:DirectiveNode directive in actualFragmentNode.getDirectives() {
            fragmentNode.addDirective(directive);
        }
    }

    isolated function detectCycles(parser:SelectionParentNode fragmentNode, map<parser:FragmentNode> visitedSpreads) {
        foreach parser:SelectionNode selectionNode in fragmentNode.getSelections() {
            if selectionNode is parser:FragmentNode {
                if visitedSpreads.hasKey(selectionNode.getName()) {
                    ErrorDetail errorDetail = getCycleRecursiveFragmentError(selectionNode, visitedSpreads);
                    self.errors.push(errorDetail);
                } else {
                    self.visitedFragments.push(selectionNode.getName());
                    visitedSpreads[selectionNode.getName()] = selectionNode;
                    parser:FragmentNode? nextFragmentDefinition =
                        self.documentNode.getFragment(selectionNode.getName());
                    if nextFragmentDefinition is parser:FragmentNode {
                        self.detectCycles(nextFragmentDefinition, visitedSpreads);
                    }
                    _ = visitedSpreads.remove(selectionNode.getName());
                }
            } else if selectionNode is parser:FieldNode {
                self.detectCycles(selectionNode, visitedSpreads);
            } else {
                panic error("Invalid selection node passed.");
            }
        }
    }

    isolated function getErrors() returns ErrorDetail[] {
        return self.errors;
    }

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {
        // Do nothing
    }

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {
        // Do nothing
    }
}
