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

import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.stdlib.graphql.compiler.FinderContext;

import java.util.Collection;
import java.util.Optional;

/**
 * Find ResourceConfig AnnotationNode node from the syntax tree.
 */
public class ResourceConfigAnnotationFinder {
    private final MethodSymbol methodSymbol;
    private final FinderContext context;

    public ResourceConfigAnnotationFinder(FinderContext context, MethodSymbol methodSymbol) {
        this.context = context;
        this.methodSymbol = methodSymbol;
    }

    public Optional<AnnotationNode> find() {
        return getAnnotationNodeFromModule();
    }

    private Optional<AnnotationNode> getAnnotationNodeFromModule() {
        Module currentModule = this.context.project().currentPackage().module(this.context.moduleId());
        Collection<DocumentId> documentIds = currentModule.documentIds();
        FunctionDefinitionNodeVisitor functionDefinitionNodeVisitor = new FunctionDefinitionNodeVisitor(
                this.context.semanticModel(), this.methodSymbol);
        for (DocumentId documentId : documentIds) {
            Node rootNode = currentModule.document(documentId).syntaxTree().rootNode();
            rootNode.accept(functionDefinitionNodeVisitor);
            if (functionDefinitionNodeVisitor.getAnnotationNode().isPresent()) {
                break;
            }
        }
        Optional<AnnotationNode> annotationNode = functionDefinitionNodeVisitor.getAnnotationNode();
        if (annotationNode.isEmpty()) {
            documentIds = currentModule.testDocumentIds();
            for (DocumentId documentId : documentIds) {
                Node rootNode = currentModule.document(documentId).syntaxTree().rootNode();
                rootNode.accept(functionDefinitionNodeVisitor);
                if (functionDefinitionNodeVisitor.getAnnotationNode().isPresent()) {
                    break;
                }
            }
            annotationNode = functionDefinitionNodeVisitor.getAnnotationNode();
        }
        return annotationNode;
    }
}
