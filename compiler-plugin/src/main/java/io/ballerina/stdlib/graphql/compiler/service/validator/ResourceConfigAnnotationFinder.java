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
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.ModuleId;
import io.ballerina.projects.Project;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.util.Collection;
import java.util.Optional;

/**
 * Find ResourceConfig AnnotationNode node from the syntax tree.
 */
public class ResourceConfigAnnotationFinder {
    private final MethodSymbol methodSymbol;
    private final SemanticModel semanticModel;
    private final Project project;
    private final ModuleId moduleId;

    public ResourceConfigAnnotationFinder(SyntaxNodeAnalysisContext context, MethodSymbol methodSymbol) {
        this.semanticModel = context.semanticModel();
        this.methodSymbol = methodSymbol;
        this.project = context.currentPackage().project();
        this.moduleId = context.moduleId();
    }

    public Optional<AnnotationNode> find() {
        return getAnnotationNodeFromModule();
    }

    private Optional<AnnotationNode> getAnnotationNodeFromModule() {
        Module currentModule = this.project.currentPackage().module(this.moduleId);
        Collection<DocumentId> documentIds = currentModule.documentIds();
        FunctionDefinitionNodeVisitor functionDefinitionNodeVisitor = new FunctionDefinitionNodeVisitor(
                this.semanticModel, this.methodSymbol);
        for (DocumentId documentId : documentIds) {
            Node rootNode = currentModule.document(documentId).syntaxTree().rootNode();
            rootNode.accept(functionDefinitionNodeVisitor);
            if (functionDefinitionNodeVisitor.getAnnotationNode().isPresent()) {
                break;
            }
        }
        return functionDefinitionNodeVisitor.getAnnotationNode();
    }
}
