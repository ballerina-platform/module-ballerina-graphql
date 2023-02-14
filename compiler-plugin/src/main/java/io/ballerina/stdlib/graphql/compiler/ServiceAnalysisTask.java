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

import io.ballerina.compiler.api.symbols.AnnotationSymbol;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ObjectConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.compiler.schema.generator.GraphqlModifierContext;
import io.ballerina.stdlib.graphql.compiler.schema.generator.SchemaGenerator;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceEntityFinder;
import io.ballerina.stdlib.graphql.compiler.service.validator.ServiceValidator;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.graphql.compiler.Utils.hasSubgraphAnnotation;

/**
 * Provides common implementation to validate Ballerina GraphQL Services.
 */
public abstract class ServiceAnalysisTask implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private final Map<DocumentId, GraphqlModifierContext> modifierContextMap;
    private final Map<Node, Boolean> nodeSubgraphMap;

    public ServiceAnalysisTask(Map<DocumentId, GraphqlModifierContext> nodeMap) {
        this.modifierContextMap = nodeMap;
        this.nodeSubgraphMap = new HashMap<>();
    }

    public ServiceValidator getServiceValidator(SyntaxNodeAnalysisContext context, Node node,
                                                InterfaceEntityFinder interfaceEntityFinder) {
        boolean isSubgraph = isSubgraphService(node, context);
        nodeSubgraphMap.put(node, isSubgraph);
        ServiceValidator serviceValidator = new ServiceValidator(context, node, interfaceEntityFinder, isSubgraph);
        serviceValidator.validate();
        return serviceValidator;
    }

    public InterfaceEntityFinder getInterfaceFinder(SyntaxNodeAnalysisContext context) {
        InterfaceEntityFinder interfaceEntityFinder = new InterfaceEntityFinder();
        interfaceEntityFinder.populateInterfaces(context);
        return interfaceEntityFinder;
    }

    public Schema generateSchema(SyntaxNodeAnalysisContext context, InterfaceEntityFinder interfaceEntityFinder,
                                 Node node, String description) {
        boolean isSubgraph = nodeSubgraphMap.get(node);
        SchemaGenerator schemaGenerator = new SchemaGenerator(context, node, interfaceEntityFinder, description,
                                                              isSubgraph);
        return schemaGenerator.generate();
    }

    public void addToModifierContextMap(DocumentId documentId, Node node, Schema schema) {
        if (this.modifierContextMap.containsKey(documentId)) {
            GraphqlModifierContext modifierContext = this.modifierContextMap.get(documentId);
            modifierContext.add(node, schema);
        } else {
            GraphqlModifierContext modifierContext = new GraphqlModifierContext();
            modifierContext.add(node, schema);
            this.modifierContextMap.put(documentId, modifierContext);
        }
    }

    @SuppressWarnings("OptionalGetWithoutIsPresent")
    private static boolean isSubgraphService(Node serviceNode, SyntaxNodeAnalysisContext context) {
        List<AnnotationSymbol> annotations = new ArrayList<>();
        if (serviceNode.kind() == SyntaxKind.SERVICE_DECLARATION) {
            ServiceDeclarationSymbol serviceDeclarationSymbol = (ServiceDeclarationSymbol) context.semanticModel()
                    .symbol(serviceNode).get();
            annotations = serviceDeclarationSymbol.annotations();
        } else if (serviceNode.kind() == SyntaxKind.OBJECT_CONSTRUCTOR) {
            NodeList<AnnotationNode> annotationNodes = ((ObjectConstructorExpressionNode) serviceNode).annotations();
            annotations = annotationNodes.stream()
                    .map(annotationNode -> (AnnotationSymbol) context.semanticModel().symbol(annotationNode).get())
                    .collect(Collectors.toList());
        }
        return hasSubgraphAnnotation(annotations);
    }
}
