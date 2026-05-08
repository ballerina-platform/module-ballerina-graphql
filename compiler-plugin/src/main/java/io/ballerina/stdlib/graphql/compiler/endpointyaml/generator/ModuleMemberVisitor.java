/*
 * Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.graphql.compiler.endpointyaml.generator;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.syntax.tree.BindingPatternNode;
import io.ballerina.compiler.syntax.tree.CaptureBindingPatternNode;
import io.ballerina.compiler.syntax.tree.ConstantDeclarationNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.ListenerDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.ModuleVariableDeclarationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeVisitor;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.TypedBindingPatternNode;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

import static io.ballerina.stdlib.graphql.compiler.endpointyaml.generator.EndpointYamlGenerator.unescapeIdentifier;

public class ModuleMemberVisitor extends NodeVisitor {
    private final Map<String, VariableDeclaredValue> variableDeclarations = new LinkedHashMap<>();
    private final Map<String, ListenerDeclarationNode> listenerDeclarations = new LinkedHashMap<>();
    private final SemanticModel semanticModel;

    public record VariableDeclaredValue(ExpressionNode value, boolean isConfigurable) {
    }

    public ModuleMemberVisitor(SemanticModel semanticModel) {
        this.semanticModel = semanticModel;
    }

    public SemanticModel getSemanticModel() {
        return this.semanticModel;
    }

    @Override
    public void visit(ModulePartNode modulePartNode) {
        // Explicitly visit all members of the module
        modulePartNode.members().forEach(member -> member.accept(this));
    }

    @Override
    public void visit(ListenerDeclarationNode listenerDeclarationNode) {
        String listenerName = unescapeIdentifier(listenerDeclarationNode.variableName().text());
        listenerDeclarations.put(listenerName, listenerDeclarationNode);
    }

    @Override
    public void visit(ModuleVariableDeclarationNode moduleVariableDeclarationNode) {
        TypedBindingPatternNode typedBindingPatternNode = moduleVariableDeclarationNode.typedBindingPattern();
        TypeDescriptorNode typeDescriptorNode = typedBindingPatternNode.typeDescriptor();
        BindingPatternNode bindingPatternNode = typedBindingPatternNode.bindingPattern();

        boolean isConfigurable = moduleVariableDeclarationNode.qualifiers().stream()
                .anyMatch(token -> token.kind().equals(SyntaxKind.CONFIGURABLE_KEYWORD));

        if (!bindingPatternNode.kind().equals(SyntaxKind.CAPTURE_BINDING_PATTERN) ||
                !(typeDescriptorNode.kind().equals(SyntaxKind.INT_TYPE_DESC) ||
                        typeDescriptorNode.kind().equals(SyntaxKind.VAR_TYPE_DESC))) {
            return;
        }

        CaptureBindingPatternNode captureBindingPatternNode = (CaptureBindingPatternNode) bindingPatternNode;
        if (captureBindingPatternNode.variableName().isMissing()) {
            return;
        }

        String variableName = unescapeIdentifier(captureBindingPatternNode.variableName().text());
        Optional<ExpressionNode> variableValue = moduleVariableDeclarationNode.initializer();

        variableDeclarations.put(variableName,
                new VariableDeclaredValue(variableValue.orElse(null), isConfigurable));
    }

    @Override
    public void visit(ConstantDeclarationNode constantDeclarationNode) {
        String variableName = unescapeIdentifier(constantDeclarationNode.variableName().text());
        Node variableValue = constantDeclarationNode.initializer();
        if (variableValue instanceof ExpressionNode valueExpression) {
            // Constant declarations are always non-configurable
            variableDeclarations.put(variableName, new VariableDeclaredValue(valueExpression, false));
        }
    }

    public Optional<ListenerDeclarationNode> getListenerDeclaration(String listenerName) {
        if (listenerDeclarations.containsKey(listenerName)) {
            return Optional.of(listenerDeclarations.get(listenerName));
        }
        return Optional.empty();
    }

    public Optional<VariableDeclaredValue> getVariableDeclaredValue(String variableName) {
        if (variableDeclarations.containsKey(variableName)) {
            return Optional.of(variableDeclarations.get(variableName));
        }
        return Optional.empty();
    }

}
