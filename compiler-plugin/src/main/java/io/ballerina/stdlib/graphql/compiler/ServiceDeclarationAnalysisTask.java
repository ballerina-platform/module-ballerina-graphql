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

import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
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
import static io.ballerina.stdlib.graphql.compiler.Utils.isGraphqlService;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getDescription;

/**
 * Validates a Ballerina GraphQL Service declaration.
 */
public class ServiceDeclarationAnalysisTask implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private final Map<DocumentId, GraphqlModifierContext> modifierContextMap;

    public ServiceDeclarationAnalysisTask(Map<DocumentId, GraphqlModifierContext> nodeMap) {
        this.modifierContextMap = nodeMap;
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        if (hasCompilationErrors(context)) {
            return;
        }
        if (!isGraphqlService(context)) {
            return;
        }
        ServiceDeclarationNode node = (ServiceDeclarationNode) context.node();
        // Already checked isEmpty() inside the isGraphqlService() method.
        @SuppressWarnings("OptionalGetWithoutIsPresent")
        ServiceDeclarationSymbol symbol = (ServiceDeclarationSymbol) context.semanticModel().symbol(node).get();
        InterfaceFinder interfaceFinder = new InterfaceFinder();
        interfaceFinder.populateInterfaces(context);

        ServiceValidator serviceValidator = new ServiceValidator(context, node, interfaceFinder);
        serviceValidator.validate();
        if (serviceValidator.isErrorOccurred()) {
            return;
        }
        DocumentId documentId = context.documentId();
        Schema schema = generateSchema(context, interfaceFinder, node, getDescription(symbol));
        addToModifierContextMap(documentId, node, schema);
    }

    private Schema generateSchema(SyntaxNodeAnalysisContext context, InterfaceFinder interfaceFinder,
                                  ServiceDeclarationNode node, String description) {
        SchemaGenerator schemaGenerator = new SchemaGenerator(context, node, interfaceFinder, description);
        return schemaGenerator.generate();
    }

    private void addToModifierContextMap(DocumentId documentId, ServiceDeclarationNode node, Schema schema) {
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
