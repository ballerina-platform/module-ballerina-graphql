// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

class DefaultDirectiveProcessorVisitor {
    *parser:Visitor;

    private final __Schema schema;

    isolated function init(__Schema schema) {
        self.schema = schema;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        self.updateSelections(documentNode.getOperations());
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        self.updateSelections(operationNode.getSelections());
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        self.updateSelections(fieldNode.getSelections());
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        self.updateSelections(fragmentNode.getSelections());
    }

    private isolated function updateSelections(parser:SelectionParentNode[] selections) {
        int i = 0;
        while i < selections.length() {
            boolean isIncluded = self.includeField(selections[i].getDirectives());
            if isIncluded {
                selections[i].accept(self);
                i += 1;
            } else {
                _ = selections.remove(i);
            }
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {}

    private isolated function includeField(parser:DirectiveNode[] directives) returns boolean {
        boolean isSkipped = false;
        boolean isIncluded = true;
        foreach parser:DirectiveNode directive in directives {
            if directive.getName() == SKIP {
                isSkipped = self.getDirectiveArgumentValue(directive);
            } else if directive.getName() == INCLUDE {
                isIncluded = self.getDirectiveArgumentValue(directive);
            }
        }
        return !isSkipped && isIncluded;
    }

    private isolated function getDirectiveArgumentValue(parser:DirectiveNode directiveNode) returns boolean {
        parser:ArgumentNode argumentNode = directiveNode.getArguments()[0];
        if argumentNode.isVariableDefinition() {
            return <boolean>argumentNode.getVariableValue();
        } else {
            parser:ArgumentValue value = <parser:ArgumentValue> argumentNode.getValue();
            return <boolean>value;
        }
    }

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {}

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {}
}
