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
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.PluginConstants.CompilationErrors;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.util.Optional;

/**
 * Validates functions in Ballerina GraphQL services.
 */
public class GraphqlFunctionValidator {

    public void validate(SyntaxNodeAnalysisContext context) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) context.node();
        NodeList<Node> memberNodes = serviceDeclarationNode.members();
        for (Node node : memberNodes) {
            FunctionDefinitionNode functionDefinitionNode = (FunctionDefinitionNode) node;
            if (functionDefinitionNode.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                // resource functions are valid - validate function signature
                validateResourceFunction(functionDefinitionNode, context);
            } else if (functionDefinitionNode.kind() == SyntaxKind.OBJECT_METHOD_DEFINITION) {
                // object methods are valid, object methods that are remote functions are invalid
                if (PluginUtils.isRemoteFunction(context, functionDefinitionNode)) {
                    context.reportDiagnostic(PluginUtils.getDiagnostic(CompilationErrors.INVALID_FUNCTION,
                            DiagnosticSeverity.ERROR, functionDefinitionNode.location()));
                }
            }
        }
    }

    private void validateResourceFunction(FunctionDefinitionNode functionDefinitionNode,
                                          SyntaxNodeAnalysisContext context) {
        validateResourceAccessorName(functionDefinitionNode, context);
        validateReturnType(functionDefinitionNode, context);
    }

    private void validateResourceAccessorName(FunctionDefinitionNode functionDefinitionNode,
                                              SyntaxNodeAnalysisContext context) {
        SemanticModel semanticModel = context.semanticModel();
        Optional<Symbol> symbolOptional = semanticModel.symbol(functionDefinitionNode);
        if (symbolOptional.isPresent()) {
            ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) symbolOptional.get();
            if (resourceMethodSymbol.getName().isPresent()) {
                if (!resourceMethodSymbol.getName().get().equals(PluginConstants.RESOURCE_FUNCTION_GET)) {
                    context.reportDiagnostic(PluginUtils.getDiagnostic(CompilationErrors.INVALID_RESOURCE_FUNCTION_NAME,
                            DiagnosticSeverity.ERROR, functionDefinitionNode.location()));
                }
            } else {
                context.reportDiagnostic(PluginUtils.getDiagnostic(CompilationErrors.INVALID_RESOURCE_FUNCTION_NAME,
                        DiagnosticSeverity.ERROR, functionDefinitionNode.location()));
            }
        }
    }

    private void validateReturnType(FunctionDefinitionNode functionDefinitionNode, SyntaxNodeAnalysisContext context) {
    }
}
