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
    *ParentNode;

    private string name;
    private Location location;
    private Location? spreadLocation;
    private string onType;
    private boolean inlineFragment;
    private Selection[] selections;

    public isolated function init(string name, Location location, boolean inlineFragment, string onType = "") {
        self.name = name;
        self.location = location;
        self.spreadLocation = ();
        self.onType = onType;
        self.inlineFragment = inlineFragment;
        self.selections = [];
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

    public isolated function addSelection(Selection selection) {
        self.selections.push(selection);
    }

    public isolated function getSelections() returns Selection[] {
        return self.selections;
    }

    public isolated function isInlineFragment() returns boolean {
        return self.inlineFragment;
    }

    public isolated function getSpreadLocation() returns Location? {
        return self.spreadLocation;
    }

    public isolated function setSpreadLocation(Location spreadLocation) {
        self.spreadLocation = spreadLocation;
    }

    public isolated function setLocation(Location location) {
        self.location = location;
    }

    public isolated function setOnType(string onType) {
        self.onType = onType;
    }
}
