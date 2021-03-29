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

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.SymbolKind;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.VariableSymbol;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.util.List;

/**
 * Validates a Ballerina GraphQL Service.
 */
public class GraphqlServiceValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) syntaxNodeAnalysisContext.node();
        getListenerTypes(syntaxNodeAnalysisContext);
        TypeSymbol typeSymbol = getListenerTypeSymbol(syntaxNodeAnalysisContext);
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo("GRAPHQL_101", typeSymbol.signature(),
                                                           DiagnosticSeverity.INFO);
        Diagnostic diagnostic = DiagnosticFactory.createDiagnostic(diagnosticInfo, serviceDeclarationNode.location());
        syntaxNodeAnalysisContext.reportDiagnostic(diagnostic);
    }

    private void getListenerTypes(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        ServiceDeclarationNode node = (ServiceDeclarationNode) syntaxNodeAnalysisContext.node();
        ServiceDeclarationSymbol symbol = (ServiceDeclarationSymbol) syntaxNodeAnalysisContext.semanticModel().symbol(
                node).get();
        List<TypeSymbol> listenerTypes = symbol.listenerTypes();
        for (TypeSymbol listenerType : listenerTypes) {
            if (listenerType.kind() == SymbolKind.) {
                listenerType.signature();
            }
        }
    }

    private TypeSymbol getListenerTypeSymbol(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) syntaxNodeAnalysisContext.node();
        TypeSymbol moduleType = null;
        for (ExpressionNode expressionNode : serviceDeclarationNode.expressions()) {
            if (expressionNode.kind() == SyntaxKind.EXPLICIT_NEW_EXPRESSION) {
                SemanticModel semanticModel = syntaxNodeAnalysisContext.semanticModel();
                Module defaultModule = syntaxNodeAnalysisContext.currentPackage().getDefaultModule();
                DocumentId documentId = syntaxNodeAnalysisContext.documentId();
                moduleType = ((TypeReferenceTypeSymbol) (semanticModel.symbol(defaultModule.document(documentId),
                                                                              expressionNode.lineRange().startLine())
                        .get())).typeDescriptor();

            } else if (expressionNode.kind() == SyntaxKind.SIMPLE_NAME_REFERENCE) {
                VariableSymbol symbol = (VariableSymbol) syntaxNodeAnalysisContext.semanticModel().symbol
                        (syntaxNodeAnalysisContext.currentPackage().getDefaultModule().
                                 document(syntaxNodeAnalysisContext.documentId()),
                         expressionNode.lineRange().startLine()).get();
                moduleType = symbol.typeDescriptor();
            } else {
                moduleType = null;
                // todo
            }
        }
        return moduleType;
    }
}
