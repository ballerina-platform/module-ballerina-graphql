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

import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.schema.generator.GraphqlModifierContext;
import io.ballerina.stdlib.graphql.compiler.schema.generator.SchemaGenerator;
import io.ballerina.stdlib.graphql.compiler.schema.types.Schema;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceFinder;
import io.ballerina.stdlib.graphql.compiler.service.validator.ServiceValidator;

import java.util.Map;

/**
 * Provides common implementation to validate Ballerina GraphQL Services.
 */
public abstract class ServiceAnalysisTask implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private final Map<DocumentId, GraphqlModifierContext> modifierContextMap;

    public ServiceAnalysisTask(Map<DocumentId, GraphqlModifierContext> nodeMap) {
        this.modifierContextMap = nodeMap;
    }

    public ServiceValidator getServiceValidator(SyntaxNodeAnalysisContext context, Node node,
                                                InterfaceFinder interfaceFinder) {
        ServiceValidator serviceValidator = new ServiceValidator(context, node, interfaceFinder);
        serviceValidator.validate();
        return serviceValidator;
    }

    public InterfaceFinder getInterfaceFinder(SyntaxNodeAnalysisContext context) {
        InterfaceFinder interfaceFinder = new InterfaceFinder();
        interfaceFinder.populateInterfaces(context);
        return interfaceFinder;
    }

    public Schema generateSchema(SyntaxNodeAnalysisContext context, InterfaceFinder interfaceFinder, Node node,
                                 String description) {
        SchemaGenerator schemaGenerator = new SchemaGenerator(context, node, interfaceFinder, description);
        return schemaGenerator.generate();
    }

    public void addToModifierContextMap(DocumentId documentId, Node node, Schema schema) {
        if (this.modifierContextMap.containsKey(documentId)) {
            GraphqlModifierContext modifierContext = this.modifierContextMap.get(documentId);
            modifierContext.addSchemaHashCode(schema.hashCode());
            modifierContext.add(node, schema);
        } else {
            GraphqlModifierContext modifierContext = new GraphqlModifierContext();
            modifierContext.addSchemaHashCode(schema.hashCode());
            modifierContext.add(node, schema);
            this.modifierContextMap.put(documentId, modifierContext);
        }
    }
}
