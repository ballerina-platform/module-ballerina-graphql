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
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.ModuleId;
import io.ballerina.projects.Project;

import java.util.Collection;
import java.util.Optional;

/**
 * Find EntityAnnotationNode node from the syntax tree.
 */
public class EntityAnnotationFinder {

    private final AnnotationSymbol annotationSymbol;
    private final SemanticModel semanticModel;
    private final Project project;
    private final ModuleId moduleId;
    private final String entityName;

    public EntityAnnotationFinder(SemanticModel semanticModel, Project currentProject, ModuleId currentModuleId,
                                  AnnotationSymbol annotationSymbol, String entityName) {
        this.semanticModel = semanticModel;
        this.annotationSymbol = annotationSymbol;
        this.project = currentProject;
        this.moduleId = currentModuleId;
        this.entityName = entityName;
    }

    public Optional<AnnotationNode> find() {
        if (this.annotationSymbol.getName().isEmpty()) {
            return Optional.empty();
        }
        return getAnnotationNodeFromModule();
    }

    private Optional<AnnotationNode> getAnnotationNodeFromModule() {
        Module currentModule = this.project.currentPackage().module(this.moduleId);
        Collection<DocumentId> documentIds = currentModule.documentIds();
        EntityAnnotationNodeVisitor directiveVisitor = new EntityAnnotationNodeVisitor(this.semanticModel,
                                                                                       this.annotationSymbol,
                                                                                       this.entityName);
        for (DocumentId documentId : documentIds) {
            Node rootNode = currentModule.document(documentId).syntaxTree().rootNode();
            rootNode.accept(directiveVisitor);
            if (directiveVisitor.getNode().isPresent()) {
                break;
            }
        }
        return directiveVisitor.getNode();
    }
}
