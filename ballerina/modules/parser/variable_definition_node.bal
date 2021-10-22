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

public class VariableDefinitionNode {
    *Node;

    private string name;
    private string typeName;
    private Location location;
    private ArgumentNode? defaultValue;

    public isolated function init(string name, string typeName, Location location) {
        self.name = name;
        self.typeName = typeName;
        self.location = location;
        self.defaultValue = ();
    }

    public isolated function getName() returns string {
        return self.name;
    }

    public isolated function getLocation() returns Location {
        return self.location;
    }

    public isolated function getTypeName() returns string {
        return self.typeName;
    }

    public isolated function getDefaultValue() returns ArgumentNode? {
        return self.defaultValue;
    }

    public isolated function setDefaultValue(ArgumentNode defaultValue) {
        self.defaultValue = defaultValue;
    }
}
