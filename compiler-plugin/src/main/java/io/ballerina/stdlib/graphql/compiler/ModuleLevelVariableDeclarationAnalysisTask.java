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
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.ModuleVariableDeclarationNode;
import io.ballerina.compiler.syntax.tree.ObjectConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Project;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils;
import io.ballerina.stdlib.graphql.compiler.schema.generator.GraphqlModifierContext;
import io.ballerina.stdlib.graphql.compiler.schema.generator.SDLFileGenerator;
import io.ballerina.stdlib.graphql.compiler.schema.types.Schema;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceFinder;
import io.ballerina.stdlib.graphql.compiler.service.validator.ServiceValidator;

import java.util.Map;

import static io.ballerina.stdlib.graphql.compiler.Utils.hasCompilationErrors;
import static io.ballerina.stdlib.graphql.compiler.Utils.isGraphQLServiceObjectDeclaration;

/**
 * Validates a Ballerina GraphQL Service variable declaration.
 */
public class ModuleLevelVariableDeclarationAnalysisTask extends ServiceAnalysisTask {

    public ModuleLevelVariableDeclarationAnalysisTask(Map<DocumentId, GraphqlModifierContext> nodeMap) {
        super(nodeMap);
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        if (hasCompilationErrors(context)) {
            return;
        }
        if (context.node().kind() != SyntaxKind.MODULE_VAR_DECL) {
            return;
        }
        ModuleVariableDeclarationNode moduleVariableDeclarationNode = (ModuleVariableDeclarationNode) context.node();
        if (!isGraphQLServiceObjectDeclaration(moduleVariableDeclarationNode)) {
            return;
        }
        if (moduleVariableDeclarationNode.initializer().isEmpty()) {
            return;
        }
        ExpressionNode expressionNode = moduleVariableDeclarationNode.initializer().get();
        if (expressionNode.kind() != SyntaxKind.OBJECT_CONSTRUCTOR) {
            return;
        }
        ObjectConstructorExpressionNode graphqlServiceObjectNode = (ObjectConstructorExpressionNode) expressionNode;
        InterfaceFinder interfaceFinder = getInterfaceFinder(context);
        ServiceValidator serviceObjectValidator = getServiceValidator(context, graphqlServiceObjectNode,
                                                                      interfaceFinder);
        if (serviceObjectValidator.isErrorOccurred()) {
            return;
        }

        String description = getDescription(context, moduleVariableDeclarationNode);
        Schema schema = generateSchema(context, interfaceFinder, graphqlServiceObjectNode, description);
        DocumentId documentId = context.documentId();
        addToModifierContextMap(documentId, moduleVariableDeclarationNode, schema);

        Project project = context.currentPackage().project();
        VariableSymbol serviceVariableSymbol =
                (VariableSymbol) context.semanticModel().symbol(moduleVariableDeclarationNode).get();
        SDLFileGenerator sdlFileGenerator =
                new SDLFileGenerator(schema, serviceVariableSymbol.hashCode(), project);
        sdlFileGenerator.generate();
    }

    String getDescription(SyntaxNodeAnalysisContext context,
                          ModuleVariableDeclarationNode moduleVariableDeclarationNode) {
        if (context.semanticModel().symbol(moduleVariableDeclarationNode).isEmpty()) {
            return null;
        }
        VariableSymbol serviceVariableSymbol = (VariableSymbol) context.semanticModel()
                .symbol(moduleVariableDeclarationNode).get();
        return GeneratorUtils.getDescription(serviceVariableSymbol);
    }
}
