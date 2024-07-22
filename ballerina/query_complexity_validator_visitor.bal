// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/log;

class QueryComplexityValidatorVisitor {
    *ValidatorVisitor;

    private final Engine engine;
    private final readonly & __Schema schema;
    private final QueryComplexityConfig queryComplexityConfig;
    private final string? operationName;
    private final NodeModifierContext nodeModifierContext;
    private int queryComplexity = 0;
    private ErrorDetail[] errors = [];

    isolated function init(Engine engine, readonly & __Schema schema, QueryComplexityConfig queryComplexityConfig,
            string? operationName, NodeModifierContext nodeModifierContext) {
        self.engine = engine;
        self.schema = schema;
        self.queryComplexityConfig = queryComplexityConfig;
        self.operationName = operationName;
        self.nodeModifierContext = nodeModifierContext;
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        if self.queryComplexityConfig.maxComplexity == 0 {
            return;
        }
        __Type parentType;
        if operationNode.getKind() == parser:OPERATION_QUERY {
            parentType = self.schema.queryType;
        } else if operationNode.getKind() == parser:OPERATION_MUTATION {
            parentType = <__Type>self.schema.mutationType;
        } else {
            parentType = <__Type>self.schema.subscriptionType;
        }
        foreach parser:SelectionNode selection in operationNode.getSelections() {
            selection.accept(self, parentType);
        }
        if self.queryComplexityConfig.maxComplexity < self.queryComplexity {
            string operationName = self.operationName is string ? string `${self.operationName.toString()} ` : "";
            string message = string `The operation ${operationName}exceeds the maximum query complexity threshold. Maximum allowed complexity: ${self.queryComplexityConfig.maxComplexity}, actual complexity: ${self.queryComplexity}`;
            if self.queryComplexityConfig.warnOnly {
                log:printWarn(message);
            } else {
                self.errors.push(getErrorDetailRecord(message, operationNode.getLocation()));
            }
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        __Type? 'type = <__Type?>data;
        __Type fieldType;
        if 'type is __Type {
            __Type parentType = getOfType('type);
            string coordinate = string `${parentType.name.toString()}.${fieldNode.getName()}`;
            int|Error complexityValue = getFieldComplexity(self.engine, coordinate);
            if complexityValue is Error {
                log:printDebug("Error in getting field complexity for " + coordinate, complexityValue);
            }
            int complexity = complexityValue is int ? complexityValue : self.queryComplexityConfig.defaultFieldComplexity;
            self.queryComplexity += complexity;
            __Field? requiredFieldValue = getRequierdFieldFromType(parentType, self.schema.types, fieldNode);
            if requiredFieldValue is () {
                string message = getFieldNotFoundErrorMessageFromType(fieldNode.getName(), parentType);
                self.errors.push(getErrorDetailRecord(message, fieldNode.getLocation()));
                return;
            }
            fieldType = requiredFieldValue.'type;
            foreach parser:SelectionNode selection in fieldNode.getSelections() {
                selection.accept(self, fieldType);
            }
        }
        // TODO: Handle introspection queries
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        parser:FragmentNode modifiedFragmentNode = self.nodeModifierContext.getModifiedFragmentNode(fragmentNode);
        foreach parser:SelectionNode selection in modifiedFragmentNode.getSelections() {
            selection.accept(self);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
    }

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {
    }

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {
    }

    public isolated function getErrors() returns ErrorDetail[]? {
        return self.errors.length() > 0 ? self.errors : ();
    }
}