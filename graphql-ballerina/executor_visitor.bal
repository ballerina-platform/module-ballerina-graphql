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

class ExecutorVisitor {
    *parser:Visitor;

    private Service serviceType;
    private Data data;
    private ErrorDetail[] errors;
    private __Schema schema;

    isolated function init(Service serviceType, __Schema schema) {
        self.serviceType = serviceType;
        self.schema = schema;
        self.data = {};
        self.errors = [];
    }

    isolated function getExecutorResult(parser:OperationNode operationNode) returns OutputObject {
        self.visitOperation(operationNode);
        return getOutputObject(self.data, self.errors);
    }

    public isolated function visitDocument(parser:DocumentNode documentNode) {
        // Do nothing
    }

    public isolated function visitOperation(parser:OperationNode operationNode) {
        foreach parser:Selection selection in operationNode.getSelections() {
            self.visitSelection(selection);
        }
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        if (selection.isFragment) {
            parser:FragmentNode fragmentNode = <parser:FragmentNode>selection?.node;
            self.visitFragment(fragmentNode);
        } else {
            parser:FieldNode fieldNode = <parser:FieldNode>selection?.node;
            self.visitField(fieldNode);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        if (fieldNode.getName() == SCHEMA_FIELD) {
            getDataFromResult(self, fieldNode, self.schema, self.data);
        } else {
            self.executeResource(fieldNode);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        // Do nothing
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection);
        }
    }

    isolated function executeResource(parser:FieldNode fieldNode) {
        executeResource(self.serviceType, self, fieldNode, self.data);
    }
}
