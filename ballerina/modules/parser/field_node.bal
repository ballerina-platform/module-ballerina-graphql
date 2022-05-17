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

public class FieldNode {
    *ParentNode;

    private final string name;
    private final string alias;
    private Location location;
    private ArgumentNode[] arguments;
    private Selection[] selections;
    private DirectiveNode[] directives;

    public isolated function init(string name, Location location, string alias) {
        self.name = name;
        self.alias = alias;
        self.location = location;
        self.arguments = [];
        self.selections = [];
        self.directives = [];
    }

    public isolated function accept(Visitor visitor, anydata data = ()) {
        visitor.visitField(self, data);
    }

    public isolated function getName() returns string {
        return self.name;
    }

    public isolated function getAlias() returns string {
        return self.alias;
    }

    public isolated function getLocation() returns Location {
        return self.location;
    }

    public isolated function addArgument(ArgumentNode argument) {
        self.arguments.push(argument);
    }

    public isolated function getArguments() returns ArgumentNode[] {
        return self.arguments;
    }

    public isolated function addSelection(Selection selection) {
        self.selections.push(selection);
    }

    public isolated function getSelections() returns Selection[] {
        return self.selections;
    }

    public isolated function addDirective(DirectiveNode directive) {
        self.directives.push(directive);
    }

    public isolated function getDirectives() returns DirectiveNode[] {
        return self.directives;
    }
}
