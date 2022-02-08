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
    private string[] usedFragments;
    private parser:DocumentNode documentNode;
    private string[] visitedFragments;

    public isolated function init(parser:DocumentNode documentNode) {
        self.errors = [];
        self.usedFragments = [];
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
        self.visitDocument(self.documentNode);
        if self.errors.length() > 0 {
            return self.errors;
        }
        return;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        self.documentNode = documentNode;
        foreach parser:OperationNode operation in documentNode.getOperations() {
            self.visitOperation(operation);
        }

        foreach parser:FragmentNode fragmentNode in documentNode.getFragments().toArray() {
            if self.usedFragments.indexOf(fragmentNode.getName()) is () {
                string message = string`Fragment "${fragmentNode.getName()}" is never used.`;
                ErrorDetail errorDetail = getErrorDetailRecord(message, fragmentNode.getLocation());
                self.errors.push(errorDetail);
            }
            _ = documentNode.getFragments().remove(fragmentNode.getName());
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        foreach parser:Selection selection in operationNode.getSelections() {
            self.visitSelection(selection);
        }
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        if selection is parser:FragmentNode {
            self.appendNamedFragmentFields(selection);
            self.visitFragment(selection);
        } else if selection is parser:FieldNode {
            self.visitField(selection);
        } else {
            panic error("Invalid selection node passed.");
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        foreach parser:Selection selection in fieldNode.getSelections() {
            self.visitSelection(selection);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        // Do Nothing
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        self.usedFragments.push(fragmentNode.getName());
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection);
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
        foreach parser:Selection fragmentSelection in actualFragmentNode.getSelections() {
            fragmentNode.addSelection(fragmentSelection);
        }
        foreach parser:DirectiveNode directive in actualFragmentNode.getDirectives() {
            fragmentNode.addDirective(directive);
        }
    }

    isolated function detectCycles(parser:ParentNode fragmentDefinition, map<parser:FragmentNode> visitedSpreads) {
        foreach parser:Selection fragmentSelection in fragmentDefinition.getSelections() {
            if fragmentSelection is parser:FragmentNode {
                if visitedSpreads.hasKey(fragmentSelection.getName()) {
                    ErrorDetail errorDetail = getCycleRecursiveFragmentError(fragmentSelection, visitedSpreads);
                    self.errors.push(errorDetail);
                } else {
                    self.visitedFragments.push(fragmentSelection.getName());
                    visitedSpreads[fragmentSelection.getName()] = fragmentSelection;
                    parser:FragmentNode? nextFragmentDefinition =
                        self.documentNode.getFragment(fragmentSelection.getName());
                    if nextFragmentDefinition is parser:FragmentNode {
                        self.detectCycles(nextFragmentDefinition, visitedSpreads);
                    }
                    _ = visitedSpreads.remove(fragmentSelection.getName());
                }
            } else if fragmentSelection is parser:FieldNode {
                self.detectCycles(fragmentSelection, visitedSpreads);
            } else {
                panic error("Invalid selection node passed.");
            }
        }
    }

    isolated function getErrors() returns ErrorDetail[] {
        return self.errors;
    }
}
