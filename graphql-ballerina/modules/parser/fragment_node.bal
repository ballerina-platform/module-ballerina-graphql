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

public class FragmentNode {
    *Node;
    *ParentType;

    private string name;
    private Location location;
    private string onType;
    private FieldNode[] selections;

    public isolated function init(string name, Location location, string onType) {
        self.name = name;
        self.location = location;
        self.onType = onType;
        self.selections = [];
    }

    public isolated function getName() returns string {
        return self.name;
    }

    public isolated function getLocation() returns Location {
        return self.location;
    }

    public isolated function accept(Visitor v) {
        anydata|error result = v.visitFragment(self);
    }

    public isolated function addSelection(FieldNode selection) {
        self.selections.push(selection);
    }

    public isolated function getSelections() returns FieldNode[] {
        return self.selections;
    }
}
