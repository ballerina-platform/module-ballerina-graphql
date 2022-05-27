// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

class DirectiveValidatorVisitor {
    *parser:Visitor;

    private final __Schema schema;
    private ErrorDetail[] errors;
    private map<parser:DirectiveNode> visitedDirectives;
    private __InputValue[] missingArguments;

    isolated function init(__Schema schema) {
        self.schema = schema;
        self.errors = [];
        self.visitedDirectives = {};
        self.missingArguments = [];
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        foreach parser:OperationNode operationNode in documentNode.getOperations() {
            operationNode.accept(self);
        }
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        self.validateDirectives(operationNode);
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        self.validateDirectives(fieldNode);
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        self.validateDirectives(fragmentNode);
    }

    public isolated function validateDirectives(parser:SelectionParentNode selectionParentNode) {
        foreach parser:DirectiveNode directiveNode in selectionParentNode.getDirectives() {
            directiveNode.accept(self);
        }
        self.visitedDirectives.removeAll();
        foreach parser:SelectionNode selectionNode in selectionParentNode.getSelections() {
            selectionNode.accept(self);
        }
    }

    // TODO: Check invalid argument type for valid argument name
    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        __Directive directive = <__Directive>data;
        string argumentName = argumentNode.getName();
        __InputValue? inputValue = getInputValueFromArray(directive.args, argumentName);
        if inputValue == () {
            string message = string `Unknown argument "${argumentName}" on directive "${directive.name}".`;
            self.errors.push(getErrorDetailRecord(message, argumentNode.getLocation()));
        } else {
            _ = self.missingArguments.remove(<int>self.missingArguments.indexOf(inputValue));
        }
    }

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {
        if self.visitedDirectives.hasKey(directiveNode.getName()) {
            string message = string`The directive "${directiveNode.getName()}" can only be used once at this location.`;
            Location location = self.visitedDirectives.get(directiveNode.getName()).getLocation();
            ErrorDetail errorDetail = getErrorDetailRecord(message, [location, directiveNode.getLocation()]);
            self.errors.push(errorDetail);
        } else {
            self.visitedDirectives[directiveNode.getName()] = directiveNode;
        }
        foreach __Directive definedDirective in self.schema.directives {
            if definedDirective.name == directiveNode.getName() {
                self.validateDirective(directiveNode, definedDirective);
                return;
            }
        }
        string message = string`Unknown directive "${directiveNode.getName()}".`;
        ErrorDetail errorDetail = getErrorDetailRecord(message, directiveNode.getLocation());
        self.errors.push(errorDetail);
    }

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {}

    private isolated function validateDirective(parser:DirectiveNode directiveNode, __Directive definedDirective) {
        parser:DirectiveLocation[] validLocations = definedDirective.locations;
        if validLocations.indexOf(directiveNode.getDirectiveLocation()) == () {
            string name = directiveNode.getName();
            __DirectiveLocation directiveLocation = directiveNode.getDirectiveLocation();
            string message = string`Directive "${name}" may not be used on ${directiveLocation}.`;
            ErrorDetail errorDetail = getErrorDetailRecord(message, directiveNode.getLocation());
            self.errors.push(errorDetail);
        }
        self.missingArguments = copyInputValueArray(definedDirective.args);
        foreach parser:ArgumentNode argumentNode in directiveNode.getArguments() {
            argumentNode.accept(self, definedDirective);
        }
        foreach __InputValue arg in self.missingArguments {
            string message = string `Directive "${definedDirective.name}" argument "${arg.name}" of type` +
                                string `"${getTypeNameFromType(arg.'type)}" is required but not provided.`;
            self.errors.push(getErrorDetailRecord(message, directiveNode.getLocation()));
        }
    }

    public isolated function getErrors() returns ErrorDetail[]? {
        return self.errors.length() > 0 ? self.errors : ();
    }
}
