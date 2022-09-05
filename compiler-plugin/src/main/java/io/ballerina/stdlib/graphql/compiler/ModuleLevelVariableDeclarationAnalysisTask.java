/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.graphql.compiler;

import io.ballerina.compiler.api.symbols.VariableSymbol;
import io.ballerina.compiler.syntax.tree.ModuleVariableDeclarationNode;
import io.ballerina.compiler.syntax.tree.ObjectConstructorExpressionNode;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.schema.generator.GraphqlModifierContext;
import io.ballerina.stdlib.graphql.compiler.schema.generator.SchemaGenerator;
import io.ballerina.stdlib.graphql.compiler.schema.types.Schema;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceFinder;
import io.ballerina.stdlib.graphql.compiler.service.validator.ServiceValidator;

import java.util.Map;

import static io.ballerina.stdlib.graphql.compiler.Utils.hasCompilationErrors;
import static io.ballerina.stdlib.graphql.compiler.Utils.isGraphQLServiceObjectDeclaration;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getDescription;

/**
 * Validates a Ballerina GraphQL Service variable declaration.
 */
public class ModuleLevelVariableDeclarationAnalysisTask implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private final Map<DocumentId, GraphqlModifierContext> modifierContextMap;

    public ModuleLevelVariableDeclarationAnalysisTask(Map<DocumentId, GraphqlModifierContext> nodeMap) {
        this.modifierContextMap = nodeMap;
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        if (hasCompilationErrors(context)) {
            return;
        }

        ModuleVariableDeclarationNode moduleVariableDeclarationNode = (ModuleVariableDeclarationNode) context.node();
        if (!isGraphQLServiceObjectDeclaration(moduleVariableDeclarationNode)) {
            return;
        }

        if (moduleVariableDeclarationNode.initializer().isEmpty()) {
            return;
        }
        ObjectConstructorExpressionNode graphqlServiceObjectNode
                = (ObjectConstructorExpressionNode) moduleVariableDeclarationNode.initializer().get();
        InterfaceFinder interfaceFinder = new InterfaceFinder();
        interfaceFinder.populateInterfaces(context);
        ServiceValidator serviceObjectValidator = new ServiceValidator(context, graphqlServiceObjectNode,
                interfaceFinder);
        serviceObjectValidator.validate();
        if (serviceObjectValidator.isErrorOccurred()) {
            return;
        }
        DocumentId documentId = context.documentId();
        String description = null;
        if (context.semanticModel().symbol(moduleVariableDeclarationNode).isPresent()) {
            VariableSymbol serviceVariableSymbol = (VariableSymbol) context.semanticModel()
                    .symbol(moduleVariableDeclarationNode).get();
            description = getDescription(serviceVariableSymbol);
        }
        Schema schema = generateSchema(interfaceFinder, graphqlServiceObjectNode, description, context);
        addToModifierContextMap(documentId, moduleVariableDeclarationNode, schema);
    }

    private Schema generateSchema(InterfaceFinder interfaceFinder, ObjectConstructorExpressionNode serviceObjectNode,
                                  String description, SyntaxNodeAnalysisContext context) {
        SchemaGenerator schemaGenerator = new SchemaGenerator(context, serviceObjectNode, interfaceFinder, description);
        return schemaGenerator.generate();
    }

    private void addToModifierContextMap(DocumentId documentId, ModuleVariableDeclarationNode node, Schema schema) {
        if (this.modifierContextMap.containsKey(documentId)) {
            GraphqlModifierContext modifierContext = this.modifierContextMap.get(documentId);
            modifierContext.add(node, schema);
        } else {
            GraphqlModifierContext modifierContext = new GraphqlModifierContext();
            modifierContext.add(node, schema);
            this.modifierContextMap.put(documentId, modifierContext);
        }
    }
}
