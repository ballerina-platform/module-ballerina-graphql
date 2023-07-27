package io.ballerina.stdlib.graphql.compiler.service.validator;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.NodeVisitor;

import java.util.Optional;

/**
 * Obtains ResourceConfig AnnotationNode node from the syntax tree.
 */
public class FunctionDefinitionNodeVisitor extends NodeVisitor {
    private static final String RESOURCE_CONFIG_ANNOTATION = "ResourceConfig";
    private final SemanticModel semanticModel;
    private final MethodSymbol methodSymbol;
    private AnnotationNode annotationNode;

    public FunctionDefinitionNodeVisitor(SemanticModel semanticModel, MethodSymbol methodSymbol) {
        this.semanticModel = semanticModel;
        this.methodSymbol = methodSymbol;
    }

    @Override
    public void visit(FunctionDefinitionNode functionDefinitionNode) {
        if (this.annotationNode != null) {
            return;
        }
        Optional<Symbol> methodSymbol = this.semanticModel.symbol(functionDefinitionNode);
        if (methodSymbol.isEmpty() || methodSymbol.get().hashCode() != this.methodSymbol.hashCode()) {
            return;
        }
        if (functionDefinitionNode.metadata().isEmpty()) {
            return;
        }
        NodeList<AnnotationNode> annotations = functionDefinitionNode.metadata().get().annotations();
        for (AnnotationNode annotation : annotations) {
            Optional<Symbol> annotationSymbol = this.semanticModel.symbol(annotation);
            if (annotationSymbol.isPresent() && annotationSymbol.get().getName().orElse("")
                    .equals(RESOURCE_CONFIG_ANNOTATION)) {
                this.annotationNode = annotation;
            }
        }
    }

    public Optional<AnnotationNode> getAnnotationNode() {
        if (this.annotationNode == null) {
            return Optional.empty();
        }
        return Optional.of(this.annotationNode);
    }
}
