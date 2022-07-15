package io.ballerina.stdlib.graphql.compiler;

import io.ballerina.compiler.api.symbols.ClassSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.service.validator.InterceptorValidator;

import static io.ballerina.stdlib.graphql.compiler.Utils.hasCompilationErrors;
import static io.ballerina.stdlib.graphql.compiler.Utils.isServiceClass;

/**
 * Validates a Ballerina GraphQL Interceptors.
 */
public class InterceptorAnalysisTask implements AnalysisTask<SyntaxNodeAnalysisContext> {

    public void perform(SyntaxNodeAnalysisContext context) {
        if (hasCompilationErrors(context)) {
            return;
        }
        for (Symbol symbol : context.semanticModel().moduleSymbols()) {
            if (isServiceClass(symbol)) {
                ClassSymbol classSymbol = (ClassSymbol) symbol;
                if (classSymbol.getName().isEmpty()) {
                    continue;
                }
                for (TypeSymbol typeSymbol : classSymbol.typeInclusions()) {
                    if (!isObjectReference(typeSymbol)) {
                        continue;
                    }
                    ClassDefinitionNode classDefinitionNode = (ClassDefinitionNode) context.node();
                    InterceptorValidator interceptorValidator = validateInterceptor(context, classDefinitionNode);
                    if (interceptorValidator.isErrorOccurred()) {
                        return;
                    }
                }
            }
        }
    }

    private InterceptorValidator validateInterceptor(SyntaxNodeAnalysisContext context,
                                                     ClassDefinitionNode classDefinitionNode) {
        InterceptorValidator interceptorValidator = new InterceptorValidator(context, classDefinitionNode);
        interceptorValidator.validate();
        return interceptorValidator;
    }

    private static boolean isObjectReference(TypeSymbol typeSymbol) {
        TypeDescKind typeDescKind = ((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor().typeKind();
        if (typeDescKind == TypeDescKind.OBJECT) {
            return true;
        }
        return false;
    }
}
