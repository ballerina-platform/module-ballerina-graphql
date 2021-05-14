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
    private parser:DocumentNode documentNode;
    private int queryDepth = 0;
    private int maxQueryDepth = 0;
    private int queryDepthLimit;
    private ErrorDetail[] errors;

    public isolated function init(parser:DocumentNode documentNode, int queryDepthLimit){
        self.documentNode = documentNode;
        self.queryDepthLimit = queryDepthLimit;
        self.errors = [];
    }

    public isolated function validate() returns ErrorDetail[]? {
        self.visitDocument(self.documentNode);
        if (self.errors.length() > 0) {
            return self.errors;
        }
    }

    public isolated function visitDocument(parser:DocumentNode documentNode) {
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
            self.queryDepth = 0;
            self.maxQueryDepth = 0;
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode) {
        foreach parser:Selection selection in operationNode.getSelections() {
            self.visitSelection(selection);
        }
    }

    public isolated function visitSelection(parser:Selection selection) {
        if (selection.isFragment) {
            parser:FragmentNode fragmentNode = self.documentNode.getFragments().get(selection.name);
            self.visitFragment(fragmentNode);
        } else {
            parser:FieldNode fieldNode = <parser:FieldNode>selection?.node;
            self.visitField(fieldNode);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode) {
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

    public isolated function visitFragment(parser:FragmentNode fragmentNode) {
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection);
        }
    }

    isolated function getErrors() returns ErrorDetail[] {
        return self.errors;
    }
}
