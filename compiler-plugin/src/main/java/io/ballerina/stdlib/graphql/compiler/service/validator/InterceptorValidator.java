package io.ballerina.stdlib.graphql.compiler.service.validator;

import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.SymbolKind;
import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TypeReferenceNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.service.errors.CompilationError;
import io.ballerina.tools.diagnostics.Location;

import static io.ballerina.stdlib.graphql.compiler.Utils.isRemoteMethod;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.GRAPHQL_INTERCEPTOR;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.INTERCEPTOR_FUNCTION_EXECUTE;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.updateContext;

/**
 * Validate Interceptors in Ballerina GraphQL services.
 */
public class InterceptorValidator {

    private final ClassDefinitionNode classDefinitionNode;
    private final SyntaxNodeAnalysisContext context;
    private boolean errorOccurred;
    public InterceptorValidator(SyntaxNodeAnalysisContext context, ClassDefinitionNode classDefinitionNode) {
        this.context = context;
        this.classDefinitionNode = classDefinitionNode;
        this.errorOccurred = false;
    }

    public void validate() {
        NodeList<Node> members = this.classDefinitionNode.members();
        for (Node member : members) {
            if (member.kind() == SyntaxKind.TYPE_REFERENCE) {
                String typeReference = ((TypeReferenceNode) member).typeName().toString();
                if (typeReference.equals(GRAPHQL_INTERCEPTOR)) {
                    validateInterceptorService(members);
                    break;
                }
            }
        }
    }

    public boolean isErrorOccurred() {
        return this.errorOccurred;
    }

    private void validateInterceptorService(NodeList<Node> members) {
        for (Node node : members) {
            validateInterceptorServiceMember(node);
        }
    }

    private void validateInterceptorServiceMember(Node node) {
        if (this.context.semanticModel().symbol(node).isEmpty()) {
            return;
        }
        Symbol symbol = this.context.semanticModel().symbol(node).get();
        Location location = node.location();
        if (symbol.kind() == SymbolKind.METHOD) {
            MethodSymbol methodSymbol = (MethodSymbol) symbol;
            if (isRemoteMethod(methodSymbol)) {
                validateRemoteMethod(methodSymbol, location);
            }
        } else if (symbol.kind() == SymbolKind.RESOURCE_METHOD) {
            addDiagnostic(CompilationError.RESOURCE_METHOD_INSIDE_INTERCEPTOR, location);
        }
    }

    private void validateRemoteMethod(MethodSymbol methodSymbol, Location location) {
        if (methodSymbol.getName().isEmpty()) {
            return;
        }
        if (!methodSymbol.getName().get().equals(INTERCEPTOR_FUNCTION_EXECUTE)) {
            addDiagnostic(CompilationError.INVALID_REMOTE_METHOD_INSIDE_INTERCEPTOR, location);
        }
    }

    private void addDiagnostic(CompilationError compilationError, Location location) {
        this.errorOccurred = true;
        updateContext(this.context, compilationError, location);
    }
}
