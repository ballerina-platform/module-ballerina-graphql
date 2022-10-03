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

class FragmentCycleFinderVisitor {
    *ValidatorVisitor;

    private ErrorDetail[] errors;
    private map<parser:FragmentNode> fragments;
    private map<parser:FragmentNode> visitedSpreads;
    private map<parser:FragmentNode> visitedFragments;

    isolated function init(map<parser:FragmentNode> fragments) {
        self.errors = [];
        self.fragments = fragments;
        self.visitedSpreads = {};
        self.visitedFragments = {};
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data) {
        foreach parser:FragmentNode fragmentNode in documentNode.getFragments() {
            self.visitedSpreads = {};
            if fragmentNode.isInlineFragment() {
                continue;
            }
            if self.visitedFragments.hasKey(fragmentNode.getName()) {
                continue;
            }
            self.visitedSpreads[fragmentNode.getName()] = fragmentNode;
            foreach parser:SelectionNode selectionNode in fragmentNode.getSelections() {
                selectionNode.accept(self);
            }
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data) {}

    public isolated function visitField(parser:FieldNode fieldNode, anydata data) {
        foreach parser:SelectionNode selectionNode in fieldNode.getSelections() {
            selectionNode.accept(self);
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data) {
        if self.visitedSpreads.hasKey(fragmentNode.getName()) {
            ErrorDetail errorDetail = getCycleRecursiveFragmentError(fragmentNode, self.visitedSpreads);
            self.errors.push(errorDetail);
            fragmentNode.setHasCycle();
        } else {
            self.visitedFragments[fragmentNode.getName()] = fragmentNode;
            self.visitedSpreads[fragmentNode.getName()] = fragmentNode;
            if self.fragments.hasKey(fragmentNode.getName()) {
                parser:FragmentNode fragmentDefinition = self.fragments.get(fragmentNode.getName());
                foreach parser:SelectionNode selectionNode in fragmentDefinition.getSelections() {
                    selectionNode.accept(self);
                }
            }
            _ = self.visitedSpreads.remove(fragmentNode.getName());
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data) {}

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data) {}

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data) {}

    public isolated function getErrors() returns ErrorDetail[]? {
        return self.errors.length() > 0 ? self.errors : ();
    }
}
