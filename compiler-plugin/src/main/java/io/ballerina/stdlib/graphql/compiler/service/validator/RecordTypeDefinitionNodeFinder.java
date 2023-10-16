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

import io.ballerina.compiler.api.symbols.RecordTypeSymbol;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.stdlib.graphql.compiler.FinderContext;

import java.util.ArrayList;
import java.util.Optional;

/**
 * Find RecordTypeDefinitionNode from the syntax tree.
 */
public class RecordTypeDefinitionNodeFinder {
    private final FinderContext context;
    private final RecordTypeSymbol recordTypeSymbol;
    private final String recordTypeName;

    public RecordTypeDefinitionNodeFinder(FinderContext context, RecordTypeSymbol recordTypeSymbol,
                                          String recordTypeName) {
        this.context = context;
        this.recordTypeSymbol = recordTypeSymbol;
        this.recordTypeName = recordTypeName;
    }

    public Optional<TypeDefinitionNode> find() {
        Module currentModule = this.context.project().currentPackage().module(this.context.moduleId());
        ArrayList<DocumentId> documentIds = new ArrayList<>(currentModule.documentIds());
        documentIds.addAll(currentModule.testDocumentIds());
        RecordTypeDefinitionNodeVisitor visitor = new RecordTypeDefinitionNodeVisitor(this.context.semanticModel(),
                                                                                      this.recordTypeSymbol,
                                                                                      this.recordTypeName);
        for (DocumentId documentId : documentIds) {
            Node rootNode = currentModule.document(documentId).syntaxTree().rootNode();
            rootNode.accept(visitor);
            Optional<TypeDefinitionNode> typeDefinitionNode = visitor.getRecordTypeDefinitionNode();
            if (typeDefinitionNode.isPresent()) {
                return typeDefinitionNode;
            }
        }
        return Optional.empty();
    }
}
