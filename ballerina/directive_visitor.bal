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

import graphql.parser;

class DirectiveVisitor {
    *parser:Visitor;

    private final __Schema schema;
    private parser:DocumentNode documentNode;
    private __Directive[] defaultDirectives;
    private ErrorDetail[] errors;

    isolated function init(__Schema schema, parser:DocumentNode documentNode) {
        self.schema = schema;
        self.documentNode = documentNode;
        self.defaultDirectives = schema.directives;
        self.errors = [];
    }

    public isolated function validate() returns ErrorDetail[]? {
        self.visitDocument(self.documentNode);
        if self.errors.length() > 0 {
            return self.errors;
        }
        return;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        parser:OperationNode[] operations = documentNode.getOperations();
        int i = 0;
        while i < operations.length() {
            boolean isIncluded = self.checkDirectives(operations[i].getDirectives());
            if isIncluded {
                self.visitOperation(operations[i]);
                i += 1;
            } else {
                _ = operations.remove(i);
            }
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        parser:Selection[] selections = operationNode.getSelections();
        int i = 0;
        while i < selections.length() {
            boolean isIncluded = self.checkDirectives((<parser:ParentNode>selections[i]).getDirectives());
            if isIncluded {
                self.visitSelection(selections[i]);
                i += 1;
            } else {
                _ = selections.remove(i);
            }
        }
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {
        if selection is parser:FragmentNode {
            self.visitFragment(selection);
        } else {
            self.visitField(selection);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        parser:Selection[] selections = fieldNode.getSelections();
        int i = 0;
        while i < selections.length() {
            boolean isIncluded = self.checkDirectives((<parser:ParentNode>selections[i]).getDirectives());
            if isIncluded {
                self.visitSelection(selections[i]);
                i += 1;
            } else {
                _ = selections.remove(i);
            }
        }
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        parser:Selection[] selections = fragmentNode.getSelections();
        int i = 0;
        while i < selections.length() {
            boolean isIncluded = self.checkDirectives((<parser:ParentNode>selections[i]).getDirectives());
            if isIncluded {
                self.visitSelection(selections[i]);
                i += 1;
            } else {
                _ = selections.remove(i);
            }
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        // Do nothing
    }

    private isolated function checkDirectives(parser:DirectiveNode[] directives) returns boolean {
        boolean skip;
        boolean include;
        [skip, include] = self.validateDirectives(directives);
        if !skip && include {
            return true;
        }
        return false;
    }

    private isolated function validateDirectives(parser:DirectiveNode[] directives) returns [boolean, boolean] {
        map<parser:DirectiveNode> visitedDirectives = {};
        boolean skip = false;
        boolean include = true;
        int i = 0;
        while i < directives.length() {
            parser:DirectiveNode directive = directives[i];
            if visitedDirectives.hasKey(directive.getName()) {
                string message = string`The directive "${directive.getName()}" can only be used once at this location.`;
                Location location1 = (visitedDirectives.get(directive.getName())).getLocation();
                ErrorDetail errorDetail = getErrorDetailRecord(message, [location1, directive.getLocation()]);
                self.errors.push(errorDetail);
            } else {
                boolean isUndefinedDirective = true;
                foreach __Directive defaultDirective in self.defaultDirectives {
                    if directive.getName() == defaultDirective.name {
                        isUndefinedDirective = false;
                        [skip, include] = self.validateDefaultDirectives(directive, defaultDirective, skip, include);
                        break;
                    }
                }
                if isUndefinedDirective {
                    string message = string`Unknown directive "${directive.getName()}".`;
                    ErrorDetail errorDetail = getErrorDetailRecord(message, directive.getLocation());
                    self.errors.push(errorDetail);
                }
                visitedDirectives[directive.getName()] = directive;
            }
            i += 1;
        }
        return [skip, include];
    }

    private isolated function validateDefaultDirectives(parser:DirectiveNode directive, __Directive defaultDirective,
                                                        boolean skip, boolean include) returns [boolean, boolean] {
        boolean isSkipped = skip;
        boolean isIncluded = include;
        parser:DirectiveLocation dirLocation = directive.getDirectiveLocations()[0];
        parser:DirectiveLocation[] defaultDirectiveLocations = <parser:DirectiveLocation[]> defaultDirective?.locations;
        if defaultDirectiveLocations.indexOf(dirLocation) is () {
            string message = string`Directive "${directive.getName()}" may not be used on ${dirLocation.toString()}.`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, directive.getLocation());
            self.errors.push(errorDetail);
        } else {
            if directive.getName() == SKIP {
                parser:ArgumentNode argNode = directive.getArguments()[0];
                if argNode.isVariableDefinition() {
                    isSkipped = <boolean>argNode.getVariableValue();
                } else {
                    parser:ArgumentValue value = <parser:ArgumentValue> argNode.getValue().get(argNode.getName());
                    isSkipped = <boolean>value.value;
                }
            } else {
                parser:ArgumentNode argNode = directive.getArguments()[0];
                if argNode.isVariableDefinition() {
                    isIncluded = <boolean>argNode.getVariableValue();
                } else {
                    parser:ArgumentValue value = <parser:ArgumentValue> argNode.getValue().get(argNode.getName());
                    isIncluded = <boolean>value.value;
                }
            }
        }
        return [isSkipped, isIncluded];
    }

}
