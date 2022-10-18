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

public isolated class FragmentNode {
    *SelectionNode;

    private string name;
    private Location location;
    private Location? spreadLocation;
    private string onType;
    private boolean inlineFragment;
    private SelectionNode[] selections;
    private DirectiveNode[] directives;
    private boolean unknownFragment;
    private boolean containsCycle;

    public isolated function init(string name, Location location, boolean inlineFragment, Location? spreadLocation = (),
                                string onType = "") {
        self.name = name;
        self.location = location.clone();
        self.spreadLocation = spreadLocation.clone();
        self.onType = onType;
        self.inlineFragment = inlineFragment;
        self.selections = [];
        self.directives = [];
        self.unknownFragment = false;
        self.containsCycle = false;
    }

    public isolated function accept(Visitor visitor, anydata data = ()) {
        visitor.visitFragment(self, data);
    }

    public isolated function getName() returns string {
        lock {
            return self.name;
        }
    }

    public isolated function getLocation() returns Location {
        lock {
            return self.location.cloneReadOnly();
        }
    }

    public isolated function getOnType() returns string {
        lock {
            return self.onType;
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

    public isolated function isInlineFragment() returns boolean {
        lock {
            return self.inlineFragment;
        }
    }

    public isolated function getSpreadLocation() returns Location? {
        lock {
            return self.spreadLocation.cloneReadOnly();
        }
    }

    public isolated function setLocation(Location location) {
        lock {
            self.location = location.clone();
        }
    }

    public isolated function setOnType(string onType) {
        lock {
            self.onType = onType;
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

    public isolated function setUnknown() {
        lock {
            self.unknownFragment = true;
        }
    }

    public isolated function isUnknown() returns boolean {
        lock {
            return self.unknownFragment;
        }
    }

    public isolated function setHasCycle() {
        lock {
            self.containsCycle = true;
        }
    }

    public isolated function hasCycle() returns boolean {
        lock {
            return self.containsCycle;
        }
    }
}
