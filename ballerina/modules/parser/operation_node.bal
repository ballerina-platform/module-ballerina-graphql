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

public class OperationNode {
    *ParentNode;

    private string name;
    private RootOperationType kind;
    private Location location;
    private Selection[] selections;
    private map<VariableDefinitionNode> variables;
    private ErrorDetail[] errors;
    private DirectiveNode[] directives;

    public isolated function init(string name, RootOperationType kind, Location location) {
        self.name = name;
        self.kind = kind;
        self.location = location;
        self.selections = [];
        self.variables = {};
        self.errors = [];
        self.directives = [];
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

    public isolated function addSelection(Selection selection) {
        self.selections.push(selection);
    }

    public isolated function getSelections() returns Selection[] {
        return self.selections;
    }

    public isolated function addVariableDefinition(VariableDefinitionNode varDef) {
        if self.variables.hasKey(varDef.getName()) {
            string message = string`There can be only one variable named "$${varDef.getName()}"`;
            Location location = varDef.getLocation();
            self.errors.push({message: message, locations:[location]});
        } else {
            self.variables[varDef.getName()] = varDef;
        }
    }

    public isolated function getVaribleDefinitions() returns map<VariableDefinitionNode> {
        return self.variables;
    }

    public isolated function getErrors() returns ErrorDetail[] {
        return self.errors;
    }

    public isolated function addDirective(DirectiveNode directive) {
        self.directives.push(directive);
    }

    public isolated function getDirectives() returns DirectiveNode[] {
        return self.directives;
    }
}
