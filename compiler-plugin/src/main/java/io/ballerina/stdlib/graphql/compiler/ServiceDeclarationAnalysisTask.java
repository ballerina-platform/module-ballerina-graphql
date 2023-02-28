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
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.compiler.schema.generator.GraphqlModifierContext;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceEntityFinder;
import io.ballerina.stdlib.graphql.compiler.service.validator.ServiceValidator;

import java.util.Map;

import static io.ballerina.stdlib.graphql.commons.utils.Utils.isGraphqlService;
import static io.ballerina.stdlib.graphql.compiler.Utils.hasCompilationErrors;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getDescription;

/**
 * Validates a Ballerina GraphQL Service declaration.
 */
public class ServiceDeclarationAnalysisTask extends ServiceAnalysisTask {

    public ServiceDeclarationAnalysisTask(Map<DocumentId, GraphqlModifierContext> nodeMap) {
        super(nodeMap);
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
        InterfaceEntityFinder interfaceEntityFinder = getInterfaceFinder(context.semanticModel());
        ServiceValidator serviceValidator = getServiceValidator(context, node, interfaceEntityFinder);
        if (serviceValidator.isErrorOccurred()) {
            return;
        }

        // Already checked isEmpty() inside the isGraphqlService() method.
        @SuppressWarnings("OptionalGetWithoutIsPresent")
        ServiceDeclarationSymbol symbol = (ServiceDeclarationSymbol) context.semanticModel().symbol(node).get();
        String description = getDescription(symbol);
        Schema schema = generateSchema(context, interfaceEntityFinder, node, description);
        DocumentId documentId = context.documentId();
        addToModifierContextMap(documentId, node, schema);
    }
}
