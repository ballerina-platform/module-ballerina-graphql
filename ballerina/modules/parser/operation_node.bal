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

public readonly class OperationNode {
    *SelectionParentNode;

    private string name;
    private RootOperationType kind;
    private Location location;
    private SelectionNode[] selections;
    private map<VariableNode> variables;
    private DirectiveNode[] directives;
    private boolean cofiguredInSchema;

    public isolated function init(string name, RootOperationType kind, Location location,
                                  map<VariableNode> variables = {}, SelectionNode[] selections = [], 
                                  DirectiveNode[] directives = []) {
        self.name = name;
        self.kind = kind;
        self.location = location.cloneReadOnly();
        self.selections = selections.cloneReadOnly();
        self.variables = variables.cloneReadOnly();
        self.directives = directives.cloneReadOnly();
        self.cofiguredInSchema = true;
    }

    public isolated function accept(Visitor visitor, anydata data = ()) {
        visitor.visitOperation(self, data);
    }

    public isolated function getName() returns string {
        return self.name;
    }

    public isolated function getKind() returns RootOperationType {
        return self.kind;
    }

    public isolated function getLocation() returns Location {
        return self.location;
    }

    public isolated function getSelections() returns SelectionNode[] {
        return self.selections;
    }

    public isolated function getVaribleDefinitions() returns map<VariableNode> {
        return self.variables;
    }

    public isolated function getDirectives() returns DirectiveNode[] {
        return self.directives;
    }

    public isolated function isConfiguredOperationInSchema() returns boolean {
        return self.cofiguredInSchema;
    }

    public isolated function modifyWith(map<VariableNode> variables, SelectionNode[] selections,
                                        DirectiveNode[] directives) returns OperationNode {
        return new (self.name, self.kind, self.location, variables, selections, directives);
    }

    public isolated function modifyWithSelections(SelectionNode[] selections) returns OperationNode {
        return new (self.name, self.kind, self.location, self.variables, selections, self.directives);
    }
}
