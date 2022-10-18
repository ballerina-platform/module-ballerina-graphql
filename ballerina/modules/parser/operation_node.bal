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

public isolated class OperationNode {
    *SelectionParentNode;

    private string name;
    private RootOperationType kind;
    private Location location;
    private SelectionNode[] selections;
    private map<VariableNode> variables;
    private ErrorDetail[] errors;
    private DirectiveNode[] directives;
    private boolean cofiguredInSchema;

    public isolated function init(string name, RootOperationType kind, Location location) {
        self.name = name;
        self.kind = kind;
        self.location = location.clone();
        self.selections = [];
        self.variables = {};
        self.errors = [];
        self.directives = [];
        self.cofiguredInSchema = true;
    }

    public isolated function accept(Visitor visitor, anydata data = ()) {
        visitor.visitOperation(self, data);
    }

    public isolated function getName() returns string {
        lock {
            return self.name;
        }
    }

    public isolated function getKind() returns RootOperationType {
        lock {
            return self.kind;

        }
    }

    public isolated function getLocation() returns Location {
        lock {
            return self.location.cloneReadOnly();
        }
    }

    public isolated function addSelection(SelectionNode selection) {
        lock {
            self.selections.push(selection);
        }
    }

    public isolated function removeSelection(int index) {
        lock {
            _ = self.selections.remove(index);
        }
    }

    public isolated function getSelections() returns SelectionNode[] {
        SelectionNode[] selectionNodes = [];
        lock {
            foreach int i in 0 ..< self.selections.length() {
                selectionNodes[i] = self.selections[i];
            }
        }
        return selectionNodes;
    }

    public isolated function addVariableDefinition(VariableNode variable) {
        lock {
            if self.variables.hasKey(variable.getName()) {
                string message = string `There can be only one variable named "$${variable.getName()}"`;
                Location location = variable.getLocation();
                self.errors.push({message: message, locations: [location]});
            } else {
                self.variables[variable.getName()] = variable;
            }
        }
    }

    public isolated function getVaribleDefinitions() returns map<VariableNode> {
        map<VariableNode> variableNodeMap = {};
        lock {
            foreach [string, VariableNode] [name, node] in self.variables.entries() {
                variableNodeMap[name] = node;
            }
        }
        return variableNodeMap;
    }

    public isolated function getErrors() returns ErrorDetail[] {
        lock {
            return self.errors.cloneReadOnly();
        }
    }

    public isolated function addDirective(DirectiveNode directive) {
        lock {
            self.directives.push(directive);
        }
    }

    public isolated function getDirectives() returns DirectiveNode[] {
        DirectiveNode[] directiveNodes = [];
        lock {
            foreach int i in 0 ..< self.directives.length() {
                directiveNodes[i] = self.directives[i];
            }
        }
        return directiveNodes;
    }

    public isolated function setNotConfiguredOperationInSchema() {
        lock {
            self.cofiguredInSchema = false;
        }
    }

    public isolated function isConfiguredOperationInSchema() returns boolean {
        lock {
            return self.cofiguredInSchema;
        }
    }
}
