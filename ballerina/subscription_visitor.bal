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

class SubscriptionVisitor {
    *parser:Visitor;

    private ErrorDetail[] errors;

    public isolated function init() {
        self.errors = [];
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        parser:OperationNode[] operations = documentNode.getOperations();
        foreach parser:OperationNode operationNode in operations {
            operationNode.accept(self);
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        if operationNode.getKind() != parser:OPERATION_SUBSCRIPTION {
            return;
        }
        parser:SelectionNode[] selections = operationNode.getSelections();
        if selections.length() > 1 {
            self.addErrorDetail(selections[1], operationNode.getName());
        }
        foreach parser:SelectionNode selection in selections {
            selection.accept(self, operationNode.getName());
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        if fieldNode.getName() == SCHEMA_FIELD || fieldNode.getName() == TYPE_FIELD ||
            fieldNode.getName() == TYPE_NAME_FIELD {
            self.addIntrospectionErrorDetail(fieldNode, <string>data);
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        if fragmentNode.getSelections().length() > 1 {
            self.addErrorDetail(fragmentNode.getSelections()[1], <string>data);
        } else {
            fragmentNode.getSelections()[0].accept(self, data);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {}

    public isolated function addErrorDetail(parser:SelectionNode selection, string operationName) {
        string message = operationName != "<anonymous>"
                        ? string `Subscription "${operationName}" must select only one top level field.`
                        : string `Anonymous Subscription must select only one top level field.`;
        if selection is parser:FragmentNode {
            ErrorDetail errorDetail = getErrorDetailRecord(message, selection.getLocation());
            self.errors.push(errorDetail);
        } else if selection is parser:FieldNode {
            ErrorDetail errorDetail = getErrorDetailRecord(message, selection.getLocation());
            self.errors.push(errorDetail);
        }
    }

    public isolated function addIntrospectionErrorDetail(parser:FieldNode fieldNode, string operationName) {
        string message = operationName != "<anonymous>"
                        ? string `Subscription "${operationName}" must not select an introspection top level field.`
                        : string `Anonymous Subscription must not select an introspection top level field.`;
        ErrorDetail errorDetail = getErrorDetailRecord(message, fieldNode.getLocation());
        self.errors.push(errorDetail);
    }

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {}

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {}

    isolated function getErrors() returns ErrorDetail[]? {
        return self.errors.length() > 0 ? self.errors : ();
    }
}
