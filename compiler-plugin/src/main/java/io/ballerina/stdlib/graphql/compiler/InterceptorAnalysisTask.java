package io.ballerina.stdlib.graphql.compiler;

import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.service.validator.InterceptorValidator;

import static io.ballerina.stdlib.graphql.compiler.Utils.READONLY_SERVICE;
import static io.ballerina.stdlib.graphql.compiler.Utils.hasCompilationErrors;

/**
 * Validates a Ballerina GraphQL Interceptors.
 */
public class InterceptorAnalysisTask implements AnalysisTask<SyntaxNodeAnalysisContext> {

    public void perform(SyntaxNodeAnalysisContext context) {

        if (hasCompilationErrors(context)) {
            return;
        }
        ClassDefinitionNode classDefinitionNode = (ClassDefinitionNode) context.node();
        NodeList<Token> tokens = classDefinitionNode.classTypeQualifiers();
        if (tokens.isEmpty()) {
            return;
        }
        if (!tokens.stream().allMatch(token -> READONLY_SERVICE.contains(token.text()))) {
            return;
        }
        InterceptorValidator interceptorValidator = validateService(context, classDefinitionNode);
        if (interceptorValidator.isErrorOccurred()) {
            return;
        }
    }

    private InterceptorValidator validateService(SyntaxNodeAnalysisContext context,
                                                 ClassDefinitionNode classDefinitionNode) {

        InterceptorValidator interceptorValidator = new InterceptorValidator(context, classDefinitionNode);
        interceptorValidator.validate();
        return interceptorValidator;
    }
}
