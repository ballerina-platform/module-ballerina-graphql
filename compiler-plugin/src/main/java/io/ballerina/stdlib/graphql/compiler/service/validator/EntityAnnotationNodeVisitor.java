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
import io.ballerina.compiler.api.symbols.AnnotationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.NodeVisitor;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;

import java.util.Optional;

/**
 * Obtains EntityAnnotationNode node from the syntax tree.
 */
public class EntityAnnotationNodeVisitor extends NodeVisitor {
    private final AnnotationSymbol annotationSymbol;
    private final SemanticModel semanticModel;
    private final String entityName;
    private AnnotationNode annotationNode;

    public EntityAnnotationNodeVisitor(SemanticModel semanticModel, AnnotationSymbol annotationSymbol,
                                       String entityName) {
        this.semanticModel = semanticModel;
        this.annotationSymbol = annotationSymbol;
        this.entityName = entityName;
    }

    @Override
    public void visit(AnnotationNode annotationNode) {
        if (this.annotationNode != null) {
            return;
        }
        Optional<Symbol> annotationSymbol = this.semanticModel.symbol(annotationNode);
        if (annotationSymbol.isPresent() && annotationSymbol.get().equals(this.annotationSymbol)) {
            if (annotationNode.parent().parent().kind() == SyntaxKind.TYPE_DEFINITION) {
                TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) annotationNode.parent().parent();
                if (typeDefinitionNode.typeName().text().trim().equals(this.entityName)) {
                    this.annotationNode = annotationNode;
                }
            } else if (annotationNode.parent().parent().kind() == SyntaxKind.CLASS_DEFINITION) {
                ClassDefinitionNode classDefinitionNode = (ClassDefinitionNode) annotationNode.parent().parent();
                if (classDefinitionNode.className().text().trim().equals(this.entityName)) {
                    this.annotationNode = annotationNode;
                }
            }
        }
    }

    public Optional<AnnotationNode> getNode() {
        return Optional.ofNullable(this.annotationNode);
    }
}
