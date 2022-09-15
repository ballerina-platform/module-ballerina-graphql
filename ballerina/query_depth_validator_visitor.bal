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

class QueryDepthValidatorVisitor {
    *ValidatorVisitor;

    private int queryDepth;
    private int maxQueryDepth;
    private int queryDepthLimit;
    private ErrorDetail[] errors;

    public isolated function init(int? queryDepthLimit) {
        self.queryDepth = 0;
        self.maxQueryDepth = 0;
        self.queryDepthLimit = queryDepthLimit is int ? queryDepthLimit : 0;
        self.errors = [];
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        if self.queryDepthLimit == 0 {
            return;
        }
        parser:OperationNode[] operations = documentNode.getOperations();
        foreach parser:OperationNode operationNode in operations {
            operationNode.accept(self);
            if self.maxQueryDepth > self.queryDepthLimit {
                if operationNode.getName() != parser:ANONYMOUS_OPERATION {
                    string message = string
                    `Query "${operationNode.getName()}" has depth of ${self.maxQueryDepth}, which exceeds max depth of ${self.queryDepthLimit}`;
                    self.errors.push(getErrorDetailRecord(message, operationNode.getLocation()));
                } else {
                    string message = string
                    `Query has depth of ${self.maxQueryDepth}, which exceeds max depth of ${self.queryDepthLimit}`;
                    self.errors.push(getErrorDetailRecord(message, operationNode.getLocation()));
                }
            }
            self.maxQueryDepth = 0;
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        foreach parser:SelectionNode selection in operationNode.getSelections() {
            selection.accept(self);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        self.queryDepth += 1;
        if fieldNode.getSelections().length() > 0 {
            parser:SelectionNode[] selections = fieldNode.getSelections();
            foreach parser:SelectionNode subSelection in selections {
                subSelection.accept(self);
            }
        } else {
            if self.queryDepth > self.maxQueryDepth {
                self.maxQueryDepth = self.queryDepth;
            }
        }
        self.queryDepth -= 1;
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        foreach parser:SelectionNode selection in fragmentNode.getSelections() {
            selection.accept(self);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {}

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {}

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {}

    public isolated function getErrors() returns ErrorDetail[]? {
        return self.errors.length() > 0 ? self.errors : ();
    }
}
