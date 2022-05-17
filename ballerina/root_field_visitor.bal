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

class RootFieldVisitor {
    *parser:Visitor;

    private parser:FieldNode? fieldNode;
    private parser:OperationNode operationNode;

    public isolated function init(parser:OperationNode operationNode) {
        self.operationNode = operationNode;
        self.fieldNode = ();
    }

    public isolated function getRootFieldNode() returns parser:FieldNode? {
        self.visitOperation(self.operationNode);
        return self.fieldNode;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        // Do nothing
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        parser:Selection[] selections = operationNode.getSelections();
        foreach parser:Selection selection in selections {
            self.visitSelection(selection);
        }
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        if selection is parser:FragmentNode {
            self.visitFragment(selection);
        } else if selection is parser:FieldNode {
            self.visitField(selection);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        self.fieldNode = fieldNode;
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        self.visitSelection(fragmentNode.getSelections()[0]);
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        // Do nothing
    }

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {

    }

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {

    }
}
