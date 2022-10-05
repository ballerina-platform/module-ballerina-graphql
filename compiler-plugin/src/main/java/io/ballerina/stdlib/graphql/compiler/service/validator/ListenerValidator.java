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

package io.ballerina.stdlib.graphql.compiler.service.validator;

import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.ExplicitNewExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionArgumentNode;
import io.ballerina.compiler.syntax.tree.ImplicitNewExpressionNode;
import io.ballerina.compiler.syntax.tree.ListenerDeclarationNode;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.service.diagnostics.CompilationDiagnostic;

import static io.ballerina.stdlib.graphql.compiler.Utils.isGraphqlListener;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.updateContext;

/**
 * Validates Ballerina GraphQL Listener Initializations.
 */
public class ListenerValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {
    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        if (context.node().kind() == SyntaxKind.EXPLICIT_NEW_EXPRESSION) {
            ExplicitNewExpressionNode node = (ExplicitNewExpressionNode) context.node();
            validateExplicitNewListener(context, node);
        } else if (context.node().kind() == SyntaxKind.IMPLICIT_NEW_EXPRESSION) {
            ImplicitNewExpressionNode node = (ImplicitNewExpressionNode) context.node();
            validateImplicitNewExpression(context, node);
        }
    }

    private void validateExplicitNewListener(SyntaxNodeAnalysisContext context, ExplicitNewExpressionNode node) {
        if (context.semanticModel().symbol(node.typeDescriptor()).isEmpty()) {
            return;
        }
        Symbol listenerSymbol = context.semanticModel().symbol(node.typeDescriptor()).get();
        if (!isGraphqlListener(listenerSymbol)) {
            return;
        }
        SeparatedNodeList<FunctionArgumentNode> functionArgs = node.parenthesizedArgList().arguments();
        validateListenerArguments(context, functionArgs);
    }

    private void validateImplicitNewExpression(SyntaxNodeAnalysisContext context, ImplicitNewExpressionNode node) {
        ListenerDeclarationNode listenerDeclarationNode;
        if (node.parent().kind() == SyntaxKind.CHECK_EXPRESSION) {
            if (node.parent().parent().kind() != SyntaxKind.LISTENER_DECLARATION) {
                return;
            }
            listenerDeclarationNode = (ListenerDeclarationNode) node.parent().parent();
        } else {
            if (node.parent().kind() != SyntaxKind.LISTENER_DECLARATION) {
                return;
            }
            listenerDeclarationNode = (ListenerDeclarationNode) node.parent();
        }
        validateImplicitNewListener(context, node, listenerDeclarationNode);
    }

    private void validateImplicitNewListener(SyntaxNodeAnalysisContext context, ImplicitNewExpressionNode node,
                                             ListenerDeclarationNode listenerDeclarationNode) {
        if (listenerDeclarationNode.typeDescriptor().isEmpty()) {
            return;
        }
        if (context.semanticModel().symbol(listenerDeclarationNode.typeDescriptor().get()).isEmpty()) {
            return;
        }
        Symbol listenerSymbol = context.semanticModel().symbol(listenerDeclarationNode.typeDescriptor().get()).get();
        if (!isGraphqlListener(listenerSymbol)) {
            return;
        }
        if (node.parenthesizedArgList().isEmpty()) {
            return;
        }
        SeparatedNodeList<FunctionArgumentNode> functionArgs = node.parenthesizedArgList().get().arguments();
        validateListenerArguments(context, functionArgs);
    }

    private void validateListenerArguments(SyntaxNodeAnalysisContext context,
                                           SeparatedNodeList<FunctionArgumentNode> arguments) {
        // two args are valid only if the first arg is numeric (i.e, port and config)
        if (arguments.size() > 1) {
            PositionalArgumentNode firstArg = (PositionalArgumentNode) arguments.get(0);
            FunctionArgumentNode secondArg = arguments.get(1);
            SyntaxKind firstArgSyntaxKind = firstArg.expression().kind();
            if (firstArgSyntaxKind != SyntaxKind.NUMERIC_LITERAL) {
                updateContext(context, CompilationDiagnostic.INVALID_LISTENER_INIT, secondArg.location());
            }
        }
    }
}
