/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.graphql.compiler.service.validator;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.NodeVisitor;

import java.util.Optional;

/**
 * Obtains ResourceConfig AnnotationNode node from the syntax tree.
 */
public class FunctionDefinitionNodeVisitor extends NodeVisitor {
    private static final String RESOURCE_CONFIG_ANNOTATION = "ResourceConfig";
    private final SemanticModel semanticModel;
    private final MethodSymbol methodSymbol;
    private AnnotationNode annotationNode;

    public FunctionDefinitionNodeVisitor(SemanticModel semanticModel, MethodSymbol methodSymbol) {
        this.semanticModel = semanticModel;
        this.methodSymbol = methodSymbol;
    }

    @Override
    public void visit(FunctionDefinitionNode functionDefinitionNode) {
        if (this.annotationNode != null) {
            return;
        }
        Optional<Symbol> functionSymbol = this.semanticModel.symbol(functionDefinitionNode);
        if (functionSymbol.isEmpty() || !functionSymbol.get().equals(this.methodSymbol)) {
            return;
        }
        if (functionDefinitionNode.metadata().isPresent()) {
            NodeList<AnnotationNode> annotations = functionDefinitionNode.metadata().get().annotations();
            for (AnnotationNode annotation : annotations) {
                Optional<Symbol> annotationSymbol = this.semanticModel.symbol(annotation);
                if (annotationSymbol.isPresent() && annotationSymbol.get().getName().orElse("")
                        .equals(RESOURCE_CONFIG_ANNOTATION)) {
                    this.annotationNode = annotation;
                }
            }
        }
    }

    public Optional<AnnotationNode> getAnnotationNode() {
        return Optional.ofNullable(this.annotationNode);
    }
}
