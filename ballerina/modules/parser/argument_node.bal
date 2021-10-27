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

public class ArgumentNode {
    *Node;

    private string name;
    private Location location;
    private map<ArgumentValue|ArgumentNode> value;
    private ArgumentType kind;
    private string? variableName;
    private anydata? variableValue;
    private boolean variableDefinition;

    public isolated function init(string name, Location location, ArgumentType kind, boolean isVarDef = false) {
        self.name = name;
        self.location = location;
        self.value = {};
        self.kind = kind;
        self.variableDefinition = isVarDef;
        self.variableName = ();
        self.variableValue = ();
    }

    public isolated function getName() returns string {
        return self.name;
    }

    public isolated function getLocation() returns Location {
        return self.location;
    }

    public isolated function getKind() returns ArgumentType {
        return self.kind;
    }

    public isolated function setKind(ArgumentType kind) {
        self.kind = kind;
    }

    public isolated function addVariableName(string name) {
        self.variableName = name;
    }

    public isolated function getVariableName() returns string? {
        return self.variableName;
    }

    public isolated function setValue(string name, ArgumentValue|ArgumentNode value) {
        self.value[name] = value;
    }

    public isolated function getValue() returns map<ArgumentValue|ArgumentNode> {
        return self.value;
    }

    public isolated function setVariableDefinition(boolean value) {
        self.variableDefinition = value;
    }

    public isolated function isVariableDefinition() returns boolean {
        return self.variableDefinition;
    }

    public isolated function setVariableValue(anydata inputValue) {
        self.variableValue = inputValue;
    }

    public isolated function getVariableValue() returns anydata {
        return self.variableValue;
    }
}
