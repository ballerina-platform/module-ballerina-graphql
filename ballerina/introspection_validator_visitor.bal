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

class IntrospectionValidatorVisitor {
    *ValidatorVisitor;

    private final boolean introspection;
    private ErrorDetail[] errors;
    private NodeModifierContext nodeModifierContext;

    isolated function init(boolean introspection, NodeModifierContext nodeModifierContext) {
        self.introspection = introspection;
        self.errors = [];
        self.nodeModifierContext = nodeModifierContext;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        parser:OperationNode[] operations = documentNode.getOperations();
        foreach parser:OperationNode operationNode in operations {
            operationNode.accept(self);
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        foreach parser:SelectionNode selection in operationNode.getSelections() {
            selection.accept(self, operationNode.getKind());
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        if fieldNode.getName() == SCHEMA_FIELD {
            string message = string `GraphQL introspection is not allowed by the GraphQL Service, but the query` +
                             string ` contained __schema.`;
            self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
        } else if fieldNode.getName() == TYPE_FIELD {
            string message = string `GraphQL introspection is not allowed by the GraphQL Service, but the query` +
                             string ` contained __type.`;
            self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        parser:FragmentNode modifiedFragmentNode = self.nodeModifierContext.getModifiedFragmentNode(fragmentNode);
        foreach parser:SelectionNode selection in modifiedFragmentNode.getSelections() {
            selection.accept(self, data);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {}

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {}

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {}

    public isolated function getErrors() returns ErrorDetail[]? {
        return self.errors.length() > 0 ? self.errors : ();
    }
}
