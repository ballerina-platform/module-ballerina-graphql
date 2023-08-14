package io.ballerina.stdlib.graphql.compiler.service.validator;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.AnnotationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.NodeVisitor;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;

import java.util.Optional;

/**
 * Obtains EntityAnnotationNode node from the syntax tree.
 */
public class EntityAnnotationNodeVisitor extends NodeVisitor {
    private final AnnotationSymbol annotationSymbol;
    private final SemanticModel semanticModel;
    private final String entityName;
    private AnnotationNode annotationNode;

    public EntityAnnotationNodeVisitor(SemanticModel semanticModel, AnnotationSymbol annotationSymbol,
                                       String entityName) {
        this.semanticModel = semanticModel;
        this.annotationSymbol = annotationSymbol;
        this.entityName = entityName;
    }

    @Override
    public void visit(AnnotationNode annotationNode) {
        Optional<Symbol> annotationSymbol = this.semanticModel.symbol(annotationNode);
        if (annotationSymbol.isPresent() && annotationSymbol.get().equals(this.annotationSymbol)) {
            if (annotationNode.parent().parent().kind() == SyntaxKind.TYPE_DEFINITION) {
                TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) annotationNode.parent().parent();
                if (typeDefinitionNode.typeName().text().trim().equals(this.entityName)) {
                    this.annotationNode = annotationNode;
                }
            } else if (annotationNode.parent().parent().kind() == SyntaxKind.CLASS_DEFINITION) {
                ClassDefinitionNode classDefinitionNode = (ClassDefinitionNode) annotationNode.parent().parent();
                if (classDefinitionNode.className().text().trim().equals(this.entityName)) {
                    this.annotationNode = annotationNode;
                }
            }
        }
    }

    public Optional<AnnotationNode> getNode() {
        if (this.annotationNode == null) {
            return Optional.empty();
        }
        return Optional.of(this.annotationNode);
    }
}
