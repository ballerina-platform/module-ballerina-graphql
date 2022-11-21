// Copyright (c) 2022 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

class DocumentNodeModifierVisitor {
    *parser:Visitor;

    private NodeModifierContext nodeModifierContext;
    private parser:DocumentNode? document;
    private map<parser:Node> modifiedNodes;

    isolated function init(NodeModifierContext nodeModifierContext) {
        self.nodeModifierContext = nodeModifierContext;
        self.modifiedNodes = {};
        self.document = ();
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {
        map<parser:OperationNode> operations = {};
        foreach parser:OperationNode operationNode in documentNode.getOperations() {
            operationNode.accept(self);
            parser:OperationNode modifiedOperationNode = <parser:OperationNode>self.getModifiedNode(operationNode);
            operations[modifiedOperationNode.getName()] = modifiedOperationNode;
        }
        self.document = documentNode.modifyWith(operations);
    }

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        parser:DirectiveNode[] directives = [];
        foreach parser:DirectiveNode directiveNode in operationNode.getDirectives() {
            directiveNode.accept(self);
            parser:DirectiveNode modifiedDirectiveNode = <parser:DirectiveNode>self.getModifiedNode(directiveNode);
            directives.push(modifiedDirectiveNode);
        }
        parser:SelectionNode[] selections = [];
        foreach parser:SelectionNode selectionNode in operationNode.getSelections() {
            selectionNode.accept(self);
            parser:SelectionNode modifiedSelectionNode = <parser:SelectionNode>self.getModifiedNode(selectionNode);
            selections.push(modifiedSelectionNode);
        }
        parser:OperationNode modifiedOperationNode = operationNode.modifyWith(operationNode.getVaribleDefinitions(),
                                                                              selections, directives);
        self.addModifiedNode(operationNode, modifiedOperationNode);
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        parser:ArgumentNode[] arguments = [];
        foreach parser:ArgumentNode argumentNode in fieldNode.getArguments() {
            argumentNode.accept(self);
            parser:ArgumentNode modifiedArgumentNode = <parser:ArgumentNode>self.getModifiedNode(argumentNode);
            arguments.push(modifiedArgumentNode);
        }
        parser:SelectionNode[] selections = [];
        foreach parser:SelectionNode selectionNode in fieldNode.getSelections() {
            selectionNode.accept(self);
            parser:SelectionNode modifiedSelectionNode = <parser:SelectionNode>self.getModifiedNode(selectionNode);
            selections.push(modifiedSelectionNode);
        }
        parser:DirectiveNode[] directives = [];
        foreach parser:DirectiveNode directiveNode in fieldNode.getDirectives() {
            directiveNode.accept(self);
            parser:DirectiveNode modifiedDirectiveNode = <parser:DirectiveNode>self.getModifiedNode(directiveNode);
            directives.push(modifiedDirectiveNode);
        }
        parser:FieldNode modifiedFieldNode = fieldNode.modifyWith(arguments, selections, directives);
        self.addModifiedNode(fieldNode, modifiedFieldNode);
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        parser:FragmentNode modifiedFragmentNode = self.nodeModifierContext.getModifiedFragmentNode(fragmentNode);
        parser:SelectionNode[] selections = [];
        foreach parser:SelectionNode selectionNode in modifiedFragmentNode.getSelections() {
            selectionNode.accept(self);
            parser:SelectionNode modifiedSelectionNode = <parser:SelectionNode>self.getModifiedNode(selectionNode);
            selections.push(modifiedSelectionNode);
        }
        parser:DirectiveNode[] directives = [];
        foreach parser:DirectiveNode directiveNode in modifiedFragmentNode.getDirectives() {
            directiveNode.accept(self);
            parser:DirectiveNode modifiedDirectiveNode = <parser:DirectiveNode>self.getModifiedNode(directiveNode);
            directives.push(modifiedDirectiveNode);
        }
        modifiedFragmentNode = modifiedFragmentNode.modifyWith(selections, directives);
        self.addModifiedNode(fragmentNode, modifiedFragmentNode);
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        parser:ArgumentNode modfiedArgumentNode = self.nodeModifierContext.getModifiedArgumentNode(argumentNode);
        parser:ArgumentValue|parser:ArgumentValue[] argumentValue = modfiedArgumentNode.getValue();
        if argumentValue is parser:ArgumentValue[] {
            parser:ArgumentValue[] value = [];
            foreach parser:ArgumentValue argField in argumentValue {
                if argField is parser:ArgumentNode {
                    argField.accept(self);
                    var modifiedArgField = <parser:ArgumentNode>self.getModifiedNode(argField);
                    value.push(modifiedArgField);
                } else {
                    value.push(argField);
                }
            }
            modfiedArgumentNode = modfiedArgumentNode.modifyWithValue(value);
        } else if argumentValue is parser:ArgumentNode {
            argumentValue.accept(self);
            var modifiedArgumentValue = <parser:ArgumentNode>self.getModifiedNode(argumentValue);
            modfiedArgumentNode = modfiedArgumentNode.modifyWithValue(modifiedArgumentValue);
        }
        self.addModifiedNode(argumentNode, modfiedArgumentNode);
    }

    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {
        parser:ArgumentNode[] arguments = [];
        foreach parser:ArgumentNode argumentNode in directiveNode.getArguments() {
            argumentNode.accept(self);
            parser:ArgumentNode modifiedArgumentNode = <parser:ArgumentNode>self.getModifiedNode(argumentNode);
            arguments.push(modifiedArgumentNode);
        }
        parser:DirectiveNode modifiedDirectiveNode = directiveNode.modifyWith(arguments);
        self.addModifiedNode(directiveNode, modifiedDirectiveNode);
    }

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {}

    public isolated function getDocumentNode() returns parser:DocumentNode {
        return <parser:DocumentNode>self.document;
    }

    private isolated function getModifiedNode(parser:Node node) returns parser:Node {
        string hashCode = parser:getHashCode(node);
        return self.modifiedNodes.hasKey(hashCode) ? self.modifiedNodes.get(hashCode) : node;
    }

    private isolated function addModifiedNode(parser:Node originalNode, parser:Node modfiedNode) {
        string hashCode = parser:getHashCode(originalNode);
        self.modifiedNodes[hashCode] = modfiedNode;
    }
}
