/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.util.List;
import java.util.Optional;

/**
 * Validates a Ballerina GraphQL Service.
 */
public class GraphqlServiceValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) syntaxNodeAnalysisContext.node();
        Optional<Symbol> serviceDeclarationSymbol = syntaxNodeAnalysisContext.semanticModel()
                .symbol(serviceDeclarationNode);
        if (serviceDeclarationSymbol.isPresent()) {
            List<TypeSymbol> listenerTypes =
                    ((ServiceDeclarationSymbol) serviceDeclarationSymbol.get()).listenerTypes();
            for (TypeSymbol listenerType : listenerTypes) {
                if (isListenerBelongsToGraphQLModule(listenerType)) {
                    validate(syntaxNodeAnalysisContext);
                }
            }
        }
    }

    public static boolean equals(String actual, String expected) {
        return actual.compareTo(expected) == 0;
    }

    private boolean isGraphQLModule(ModuleSymbol moduleSymbol) {
        return equals(moduleSymbol.getName().get(), "graphql")
                && equals(moduleSymbol.id().orgName(), "ballerina");
    }

    private boolean isListenerBelongsToGraphQLModule(TypeSymbol listenerType) {
        if (listenerType.typeKind() == TypeDescKind.UNION) {
            return ((UnionTypeSymbol) listenerType).memberTypeDescriptors().stream()
                    .filter(typeDescriptor -> typeDescriptor instanceof TypeReferenceTypeSymbol)
                    .map(typeReferenceTypeSymbol -> (TypeReferenceTypeSymbol) typeReferenceTypeSymbol)
                    .anyMatch(typeReferenceTypeSymbol -> isGraphQLModule(typeReferenceTypeSymbol.getModule().get()));
        }

        if (listenerType.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            return isGraphQLModule(((TypeReferenceTypeSymbol) listenerType).typeDescriptor().getModule().get());
        }

        return false;
    }

    public void validate(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) syntaxNodeAnalysisContext.node();
        serviceDeclarationNode.members().stream()
                .filter(child -> child.kind() == SyntaxKind.OBJECT_METHOD_DEFINITION
                        || child.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION).forEach(node -> {
            checkForRemoteMethods((FunctionDefinitionNode) node, syntaxNodeAnalysisContext);
        });
    }

    private void checkForRemoteMethods(FunctionDefinitionNode node, SyntaxNodeAnalysisContext context) {
        int hasRemoteKeyword = node.qualifierList().stream()
                .filter(q -> q.kind() == SyntaxKind.RESOURCE_KEYWORD && q.isMissing()).toArray().length;

        if (hasRemoteKeyword > 0) {
            reportDiagnostic(node, "GRAPHQL_101", "REMOTE_METHODS_ARE_NOT_ALLOWED", context);
        }
    }

    private void reportDiagnostic(FunctionDefinitionNode node, String code, String messageFormat,
                                  SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(code, messageFormat, DiagnosticSeverity.INFO);
        syntaxNodeAnalysisContext.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo,
                                                                node.location(), node.functionName().toString()));
    }
}
