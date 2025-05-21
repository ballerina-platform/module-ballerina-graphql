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

public readonly class FragmentNode {
    *SelectionNode;

    private string name;
    private Location location;
    private Location? spreadLocation;
    private string onType;
    private boolean inlineFragment;
    private SelectionNode[] selections;
    private DirectiveNode[] directives;

    public isolated function init(string name, Location location, boolean inlineFragment, Location? spreadLocation = (),
                                  string onType = "", SelectionNode[] selections = [], DirectiveNode[] directives = []) {
        self.name = name;
        self.location = location.cloneReadOnly();
        self.spreadLocation = spreadLocation.cloneReadOnly();
        self.onType = onType;
        self.inlineFragment = inlineFragment;
        self.selections = selections.cloneReadOnly();
        self.directives = directives.cloneReadOnly();
    }

    public isolated function accept(Visitor visitor, anydata data = ()) {
        visitor.visitFragment(self, data);
    }

    public isolated function getName() returns string {
        return self.name;
    }

    public isolated function getLocation() returns Location {
        return self.location;
    }

    public isolated function getOnType() returns string {
        return self.onType;
    }

    public isolated function getSelections() returns SelectionNode[] {
        return self.selections;
    }

    public isolated function isInlineFragment() returns boolean {
        return self.inlineFragment;
    }

    public isolated function getSpreadLocation() returns Location? {
        return self.spreadLocation;
    }

    public isolated function getDirectives() returns DirectiveNode[] {
        return self.directives;
    }

    public isolated function modifyWith(SelectionNode[] selections, DirectiveNode[] directives, string? onType = ())
    returns FragmentNode {
        string onTypeValue = onType is () ? self.onType : onType;
        return new (self.name, self.location, self.inlineFragment, self.spreadLocation, onTypeValue, selections,
                    directives);
    }

    public isolated function modifyWithSelections(SelectionNode[] selections) returns FragmentNode {
        return new (self.name, self.location, self.inlineFragment, self.spreadLocation, self.onType, selections, self.directives);
    }
}
