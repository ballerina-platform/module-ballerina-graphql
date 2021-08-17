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

    private final __Schema schema;
    private final Engine engine;
    private Data data;
    private ErrorDetail[] errors;

    isolated function init(Engine engine, __Schema schema) {
        self.engine = engine;
        self.schema = schema;
        self.data = {};
        self.errors = [];
    }

    isolated function getExecutorResult(parser:OperationNode operationNode) returns OutputObject {
        self.visitOperation(operationNode, operationNode.getKind());
        return getOutputObject(self.data, self.errors);
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        // Do nothing
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        foreach parser:Selection selection in operationNode.getSelections() {
            self.visitSelection(selection, data);
        }
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        if (selection.isFragment) {
            parser:FragmentNode fragmentNode = <parser:FragmentNode>selection?.node;
            self.visitFragment(fragmentNode, data);
        } else {
            parser:FieldNode fieldNode = <parser:FieldNode>selection?.node;
            self.visitField(fieldNode, data);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        parser:RootOperationType operationType = <parser:RootOperationType>data;
        if (fieldNode.getName() == SCHEMA_FIELD) {
            executeIntrospection(self, fieldNode);
        } else {
            if (operationType == parser:QUERY) {
                executeQuery(self, fieldNode);
            } else if (operationType == parser:MUTATION) {
                executeMutation(self, fieldNode);
            }
        }
    }

    public isolated function visitArgument(parser:InputObjectNode argumentNode, anydata data = ()) {
        // Do nothing
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        foreach parser:Selection selection in fragmentNode.getSelections() {
            self.visitSelection(selection, data);
        }
    }
}
