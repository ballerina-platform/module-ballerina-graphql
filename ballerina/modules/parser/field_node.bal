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

public isolated class FieldNode {
    *SelectionNode;

    private final string name;
    private final string alias;
    private Location location;
    private ArgumentNode[] arguments;
    private SelectionNode[] selections;
    private DirectiveNode[] directives;

    public isolated function init(string name, Location location, string alias) {
        self.name = name;
        self.alias = alias;
        self.location = location.clone();
        self.arguments = [];
        self.selections = [];
        self.directives = [];
    }

    public isolated function accept(Visitor visitor, anydata data = ()) {
        visitor.visitField(self, data);
    }

    public isolated function getName() returns string {
        lock {
            return self.name;
        }
    }

    public isolated function getAlias() returns string {
        lock {
            return self.alias;
        }
    }

    public isolated function getLocation() returns Location {
        lock {
            return self.location.cloneReadOnly();
        }
    }

    public isolated function addArgument(ArgumentNode argument) {
        lock {
            self.arguments.push(argument);
        }
    }

    public isolated function getArguments() returns ArgumentNode[] {
        ArgumentNode[] argumentNodes = [];
        lock {
            foreach int i in 0 ..< self.arguments.length() {
                argumentNodes[i] = self.arguments[i];
            }
        }
        return argumentNodes;
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
}
