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

import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.syntax.tree.ExplicitNewExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionArgumentNode;
import io.ballerina.compiler.syntax.tree.ImplicitNewExpressionNode;
import io.ballerina.compiler.syntax.tree.ListenerDeclarationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TypeDescriptorNode;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.util.Optional;

import static io.ballerina.stdlib.graphql.compiler.PluginUtils.isGraphqlListener;

/**
 * Validates Ballerina GraphQL Listener Initializations.
 */
public class GraphqlListenerValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {
    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        Node node = context.node();
        if (node.kind() == SyntaxKind.EXPLICIT_NEW_EXPRESSION) {
            ExplicitNewExpressionNode expressionNode = (ExplicitNewExpressionNode) node;
            Optional<Symbol> symbolOpt = context.semanticModel().symbol(expressionNode.typeDescriptor());
            if (symbolOpt.isPresent() && symbolOpt.get() instanceof TypeReferenceTypeSymbol) {
                TypeSymbol typeSymbol = ((TypeReferenceTypeSymbol) symbolOpt.get()).typeDescriptor();
                String identifier = typeSymbol.getName().orElse("");
                if (PluginConstants.LISTENER_IDENTIFIER.equals(identifier) && isGraphqlListener(typeSymbol)) {
                    SeparatedNodeList<FunctionArgumentNode> functionArgs =
                            expressionNode.parenthesizedArgList().arguments();
                    verifyListenerArgType(context, functionArgs);
                }

            }
        } else {
            ImplicitNewExpressionNode expressionNode = (ImplicitNewExpressionNode) node;
            if (node.parent() instanceof ListenerDeclarationNode) {
                ListenerDeclarationNode parentNode = (ListenerDeclarationNode) expressionNode.parent();
                Optional<TypeDescriptorNode> parentTypeOpt = parentNode.typeDescriptor();
                if (parentTypeOpt.isPresent()) {
                    Optional<Symbol> parentSymbolOpt = context.semanticModel().symbol(parentTypeOpt.get());
                    if (parentSymbolOpt.isPresent() && parentSymbolOpt.get() instanceof TypeReferenceTypeSymbol) {
                        TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) parentSymbolOpt.get()).typeDescriptor();
                        if (isGraphqlListener(typeDescriptor) && expressionNode.parenthesizedArgList().isPresent()) {
                            SeparatedNodeList<FunctionArgumentNode> functionArgs =
                                    expressionNode.parenthesizedArgList().get().arguments();
                            verifyListenerArgType(context, functionArgs);
                        }
                    }
                }
            }
        }
    }

    private void verifyListenerArgType(SyntaxNodeAnalysisContext context,
                                       SeparatedNodeList<FunctionArgumentNode> functionArgs) {
        // two args are valid only if the first arg is numeric (i.e, port and config)
        if (functionArgs.size() == 2) {
            PositionalArgumentNode firstArg = (PositionalArgumentNode) functionArgs.get(0);
            PositionalArgumentNode secondArg = (PositionalArgumentNode) functionArgs.get(1);
            SyntaxKind firstArgSyntaxKind = firstArg.expression().kind();
            if (firstArgSyntaxKind != SyntaxKind.NUMERIC_LITERAL) {
                PluginUtils.updateContext(context, PluginConstants.CompilationErrors.INVALID_LISTENER_INIT,
                        secondArg.location());
            }
        }
    }
}
