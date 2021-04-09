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
    private map<string> usedFragments;
    private parser:DocumentNode? documentNode;

    public isolated function init() {
        self.errors = [];
        self.usedFragments = {};
        self.documentNode = ();
    }

    public isolated function visitDocument(parser:DocumentNode documentNode) {
        self.documentNode = documentNode;
        foreach parser:OperationNode operation in documentNode.getOperations() {
            self.visitOperation(operation);
        }

        foreach parser:FragmentNode fragmentNode in documentNode.getFragments().toArray() {
            if (!self.usedFragments.hasKey(fragmentNode.getName())) {
                string message = string`Fragment "${fragmentNode.getName()}" is never used.`;
                ErrorDetail errorDetail = getErrorDetailRecord(message, fragmentNode.getLocation());
                self.errors.push(errorDetail);
            }
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode) {
        foreach parser:Selection selection in operationNode.getSelections() {
            self.visitSelection(selection);
        }
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        if (selection.isFragment) {
            parser:FragmentNode? fragmentNode = self.getFragment(selection);
            if (fragmentNode is parser:FragmentNode) {
                self.visitFragment(fragmentNode);
                selection.node = fragmentNode;
            }
        } else {
            parser:FieldNode fieldNode = <parser:FieldNode>selection?.node;
            var result = self.visitField(fieldNode);
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
        self.usedFragments[fragmentNode.getName()] = fragmentNode.getName();
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection);
        }
    }

    isolated function getFragment(parser:Selection selection) returns parser:FragmentNode? {
        parser:DocumentNode documentNode = <parser:DocumentNode>self.documentNode;
        parser:FragmentNode? fragmentNode = documentNode.getFragment(selection.name);
        if (fragmentNode is ()) {
            string message = string`Unknown fragment "${selection.name}".`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, selection.location);
            self.errors.push(errorDetail);
        }
        return fragmentNode;
    }

    isolated function getErrors() returns ErrorDetail[] {
        return self.errors;
    }
}
