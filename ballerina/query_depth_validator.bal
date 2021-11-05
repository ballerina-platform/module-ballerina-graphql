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

class QueryDepthValidator{
    *parser:Visitor;

    private parser:DocumentNode documentNode;
    private int queryDepth;
    private int maxQueryDepth;
    private int queryDepthLimit;
    private ErrorDetail[] errors;

    public isolated function init(parser:DocumentNode documentNode, int queryDepthLimit){
        self.documentNode = documentNode;
        self.queryDepth = 0;
        self.maxQueryDepth = 0;
        self.queryDepthLimit = queryDepthLimit;
        self.errors = [];
    }

    public isolated function validate() returns ErrorDetail[]? {
        self.visitDocument(self.documentNode);
        if (self.errors.length() > 0) {
            return self.errors;
        }
        return;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        parser:OperationNode[] operations = documentNode.getOperations();
        foreach parser:OperationNode operationNode in operations {
            self.visitOperation(operationNode);
            if (self.maxQueryDepth > self.queryDepthLimit) {
                if (operationNode.getName() != parser:ANONYMOUS_OPERATION) {
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
        self.queryDepth += 1;
        if (fieldNode.getSelections().length() > 0) {
            parser:Selection[] selections = fieldNode.getSelections();
            foreach parser:Selection subSelection in selections {
                self.visitSelection(subSelection);
            }
        } else {
            if (self.queryDepth > self.maxQueryDepth) {
                self.maxQueryDepth = self.queryDepth;
            }
        }
        self.queryDepth -= 1;
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        // Do nothing
    }

    isolated function getErrors() returns ErrorDetail[] {
        return self.errors;
    }
}
