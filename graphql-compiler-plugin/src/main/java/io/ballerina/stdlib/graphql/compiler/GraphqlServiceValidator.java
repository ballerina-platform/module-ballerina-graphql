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
import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.BasicLiteralNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.compiler.syntax.tree.UnaryExpressionNode;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.PluginConstants.CompilationErrors;

import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.graphql.compiler.PluginUtils.validateModuleId;

/**
 * Validates a Ballerina GraphQL Service.
 */
public class GraphqlServiceValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private final GraphqlFunctionValidator functionValidator;
    private GraphqlListenerInitVisitor initVisitor;

    public GraphqlServiceValidator() {
        this.functionValidator = new GraphqlFunctionValidator();
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) context.node();
        if (!isGraphQlService(context)) {
            return;
        }
        this.initVisitor = new GraphqlListenerInitVisitor(context);
        serviceDeclarationNode.syntaxTree().rootNode().accept(initVisitor);
//        validateListenerArguments(context);
        this.functionValidator.validate(context);
        validateAnnotation(context);
    }

    private void validateAnnotation(SyntaxNodeAnalysisContext context) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) context.node();
        if (serviceDeclarationNode.metadata().isPresent()) {
            MetadataNode metadataNode = serviceDeclarationNode.metadata().get();
            NodeList<AnnotationNode> annotationNodes = metadataNode.annotations();
            AnnotationNode annotationNode = annotationNodes.get(0);
            if (annotationNode.annotValue().isPresent()) {
                MappingConstructorExpressionNode constructorExpressionNode = annotationNode.annotValue().get();
                SeparatedNodeList<MappingFieldNode> mappingFieldNodes = constructorExpressionNode.fields();
                for (MappingFieldNode mappingNode : mappingFieldNodes) {
                    SpecificFieldNode specificFieldNode = (SpecificFieldNode) mappingNode;
                    if (specificFieldNode.fieldName().toString().contains(PluginConstants.MAX_QUERY_DEPTH) &&
                            specificFieldNode.valueExpr().isPresent()) {
                        if (specificFieldNode.valueExpr().get().kind() == SyntaxKind.UNARY_EXPRESSION) {
                            UnaryExpressionNode queryDepthValueNode =
                                    (UnaryExpressionNode) specificFieldNode.valueExpr().get();
                            Token unaryOp = queryDepthValueNode.unaryOperator();
                            // check 0
                            if (unaryOp.text().equals(PluginConstants.UNARY_NEGATIVE)) {
                                PluginUtils.updateContext(context, CompilationErrors.INVALID_MAX_QUERY_DEPTH,
                                        queryDepthValueNode.location());
                            }
                        } else if (specificFieldNode.valueExpr().get().kind() == SyntaxKind.NUMERIC_LITERAL) {
                            BasicLiteralNode basicLiteralNode = (BasicLiteralNode) specificFieldNode.valueExpr().get();
                            if (Integer.parseInt(basicLiteralNode.literalToken().text()) == 0) {
                                PluginUtils.updateContext(context, CompilationErrors.INVALID_MAX_QUERY_DEPTH,
                                        specificFieldNode.location());
                            }
                        }
                    }
                }
            }
        }
    }

    private boolean isGraphQlService(SyntaxNodeAnalysisContext context) {
        boolean isGraphQlService = false;
        SemanticModel semanticModel = context.semanticModel();
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) context.node();
        Optional<Symbol> symbol = semanticModel.symbol(serviceDeclarationNode);
        if (symbol.isPresent()) {
            ServiceDeclarationSymbol serviceDeclarationSymbol = (ServiceDeclarationSymbol) symbol.get();
            List<TypeSymbol> listeners = serviceDeclarationSymbol.listenerTypes();
            if (listeners.size() > 1 && hasGraphqlListener(listeners)) {
                PluginUtils.updateContext(context, CompilationErrors.INVALID_MULTIPLE_LISTENERS,
                        serviceDeclarationNode.location());
            } else {
                if (listeners.get(0).typeKind() == TypeDescKind.UNION) {
                    UnionTypeSymbol unionTypeSymbol = (UnionTypeSymbol) listeners.get(0);
                    List<TypeSymbol> members = unionTypeSymbol.memberTypeDescriptors();
                    for (TypeSymbol memberSymbol : members) {
                        Optional<ModuleSymbol> module = memberSymbol.getModule();
                        if (module.isPresent()) {
                            isGraphQlService = validateModuleId(module.get());
                        }
                    }
                } else {
                    Optional<ModuleSymbol> module = listeners.get(0).getModule();
                    if (module.isPresent()) {
                        isGraphQlService = validateModuleId(module.get());
                    }
                }
            }
        }
        return isGraphQlService;
    }

    private boolean hasGraphqlListener(List<TypeSymbol> listeners) {
        for (TypeSymbol listener : listeners) {
            if (listener.typeKind() == TypeDescKind.UNION) {
                UnionTypeSymbol unionTypeSymbol = (UnionTypeSymbol) listener;
                List<TypeSymbol> members = unionTypeSymbol.memberTypeDescriptors();
                for (TypeSymbol member : members) {
                    if (validateModuleId(member.getModule().get())) {
                        return true;
                    }
                }
            } else {
                if (validateModuleId(listener.getModule().get())) {
                    return true;
                }
            }
        }
        return false;
    }

//    private void validateListenerArguments(SyntaxNodeAnalysisContext context) {
//        initVisitor.getExplicitNewExpressionNodes()
//                .forEach(explicitNewExpressionNode -> {
//                    SeparatedNodeList<FunctionArgumentNode> functionArgs = explicitNewExpressionNode
//                            .parenthesizedArgList().arguments();
//                    verifyListenerArgType(context, explicitNewExpressionNode.location(), functionArgs);
//                });
//
//        initVisitor.getImplicitNewExpressionNodes()
//                .forEach(implicitNewExpressionNode -> {
//                    Optional<ParenthesizedArgList> argListOpt = implicitNewExpressionNode.parenthesizedArgList();
//                    if (argListOpt.isPresent()) {
//                        SeparatedNodeList<FunctionArgumentNode> functionArgs = argListOpt.get().arguments();
//                        verifyListenerArgType(context, implicitNewExpressionNode.location(), functionArgs);
//                    }
//                });
//    }
//
//    private void verifyListenerArgType(SyntaxNodeAnalysisContext context, NodeLocation location,
//                                       SeparatedNodeList<FunctionArgumentNode> functionArgs) {
//        if (functionArgs.size() >= 2) {
//            PositionalArgumentNode firstArg = (PositionalArgumentNode) functionArgs.get(0);
//            PositionalArgumentNode secondArg = (PositionalArgumentNode) functionArgs.get(1);
//            SyntaxKind firstArgSyntaxKind = firstArg.expression().kind();
//            SyntaxKind secondArgSyntaxKind = secondArg.expression().kind();
//            if ((firstArgSyntaxKind == SyntaxKind.SIMPLE_NAME_REFERENCE
//                    || firstArgSyntaxKind == SyntaxKind.MAPPING_CONSTRUCTOR)
//                    && (secondArgSyntaxKind == SyntaxKind.SIMPLE_NAME_REFERENCE
//                    || secondArgSyntaxKind == SyntaxKind.MAPPING_CONSTRUCTOR)) {
//
//            }
//        }
//    }
}
