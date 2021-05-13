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
    private int queryDepth = 1;
    private int maxQueryDepth = 0;
    private int queryDepthLimit;
    private ErrorDetail[] errors;

    public isolated function init(parser:DocumentNode documentNode, int queryDepthLimit){
        self.documentNode = documentNode;
        self.queryDepthLimit = queryDepthLimit;
        self.errors = [];
    }

    public isolated function validate() {
        self.visitDocument(self.documentNode);
        return;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode) {
        parser:OperationNode[] operations = documentNode.getOperations();
        foreach parser:OperationNode operationNode in operations {
            self.visitOperation(operationNode);
            if(self.maxQueryDepth > self.queryDepthLimit) {
                string message = string`Query has depth of ${self.maxQueryDepth.toString()}, which exceeds max depth of ${self.queryDepthLimit.toString()}`;
                self.errors.push(getErrorDetailRecord(message, operationNode.getLocation()));
                return;
            }
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode) {
        foreach parser:Selection selection in operationNode.getSelections() {
            self.visitSelection(selection);
            if(self.queryDepth > self.maxQueryDepth) {
                self.maxQueryDepth = self.queryDepth;
            }
            self.queryDepth = 0;
        }
    }

    public isolated function visitSelection(parser:Selection selection) {
        if(selection.isFragment) {
            parser:FragmentNode fragmentNode = self.documentNode.getFragments().get(selection.name);
            if(fragmentNode.getFields().length() != 0 || fragmentNode.getFragments().length() != 0) {
                self.visitFragment(fragmentNode);
            }
        } else {
            parser:FieldNode fieldNode = <parser:FieldNode>selection?.node;
            if(fieldNode.getFields().length() != 0 || fieldNode.getFragments().length() != 0) {
                self.queryDepth += 1;
                self.visitField(fieldNode);
            }
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode) {
        parser:Selection[] selections = fieldNode.getSelections();
        int i = self.queryDepth;
        foreach parser:Selection subSelection in selections {
            self.visitSelection(subSelection);
            if(self.queryDepth > self.maxQueryDepth ) {
                self.maxQueryDepth = self.queryDepth;
            }
            self.queryDepth = i;
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode) {
        int i = self.queryDepth;
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection);
            if(self.queryDepth > self.maxQueryDepth ) {
                self.maxQueryDepth = self.queryDepth;
            }
            self.queryDepth = i;
        }
    }

    isolated function getErrors() returns ErrorDetail[] {
        return self.errors;
    }
}