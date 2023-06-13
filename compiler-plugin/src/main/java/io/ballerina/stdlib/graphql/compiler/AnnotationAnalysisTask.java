/*
 * Copyright (c) 2023, WSO2 LLC. (https://www.wso2.com) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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
import io.ballerina.compiler.api.symbols.AnnotationSymbol;
import io.ballerina.compiler.api.symbols.ArrayTypeSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.ArrayTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.ChildNodeList;
import io.ballerina.compiler.syntax.tree.OptionalTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.RequiredParameterNode;
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.UnionTypeDescriptorNode;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.diagnostics.CompilationDiagnostic;

import java.util.List;

import static io.ballerina.stdlib.graphql.commons.utils.Utils.isGraphqlModuleSymbol;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.updateContext;

/**
 * Validates the usages of the annotation, @graphql:ID.
 */
public class AnnotationAnalysisTask implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private static final String ID_ANNOTATION = "ID";

    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        AnnotationNode annotationNode = (AnnotationNode) syntaxNodeAnalysisContext.node();
        SemanticModel semanticModel = syntaxNodeAnalysisContext.semanticModel();
        if (semanticModel.symbol(annotationNode).isPresent()) {
            AnnotationSymbol annotationSymbol = (AnnotationSymbol) semanticModel.symbol(annotationNode).get();
            if (annotationSymbol.getModule().isPresent()
                    && isGraphqlModuleSymbol(annotationSymbol.getModule().get())
                    && annotationSymbol.getName().isPresent()
                    && annotationSymbol.getName().get().equals(ID_ANNOTATION)) {
                if (annotationNode.parent().kind() == SyntaxKind.REQUIRED_PARAM) {
                    RequiredParameterNode requiredParameterNode = (RequiredParameterNode) annotationNode.parent();
                    if (semanticModel.symbol(requiredParameterNode).isPresent()) {
                        ParameterSymbol parameterSymbol =
                                (ParameterSymbol) semanticModel.symbol(requiredParameterNode).get();
                        if (!checkTypeForValidation(parameterSymbol.typeDescriptor())) {
                            updateContext(syntaxNodeAnalysisContext, CompilationDiagnostic.INVALID_USE_OF_ID_ANNOTATION,
                                    annotationNode.location());
                        }
                    } else {
                        updateContext(syntaxNodeAnalysisContext, CompilationDiagnostic.INVALID_USE_OF_ID_ANNOTATION,
                                annotationNode.location());
                    }
                } else if (annotationNode.parent().kind() == SyntaxKind.RETURN_TYPE_DESCRIPTOR) {
                    ReturnTypeDescriptorNode returnTypeDescriptorNode =
                            (ReturnTypeDescriptorNode) annotationNode.parent();
                    if (semanticModel.symbol(returnTypeDescriptorNode.type()).isPresent()) {
                        TypeSymbol typeSymbol =
                                (TypeSymbol) semanticModel.symbol(returnTypeDescriptorNode.type()).get();
                        if (!checkTypeForValidation(typeSymbol)) {
                            updateContext(syntaxNodeAnalysisContext, CompilationDiagnostic.INVALID_USE_OF_ID_ANNOTATION,
                                    annotationNode.location());
                        }
                    } else if (returnTypeDescriptorNode.type().kind() == SyntaxKind.UNION_TYPE_DESC) {
                        UnionTypeDescriptorNode unionTypeDescNode = (UnionTypeDescriptorNode)
                                returnTypeDescriptorNode.type();
                        ChildNodeList childNodeList = unionTypeDescNode.children();
                        if (!validateChildNodes(childNodeList, semanticModel)) {
                            updateContext(syntaxNodeAnalysisContext, CompilationDiagnostic.INVALID_USE_OF_ID_ANNOTATION,
                                    annotationNode.location());
                        }
                    } else if (returnTypeDescriptorNode.type().kind() == SyntaxKind.OPTIONAL_TYPE_DESC) {
                        OptionalTypeDescriptorNode optionalTypeDescriptorNode = (OptionalTypeDescriptorNode)
                                returnTypeDescriptorNode.type();
                        ChildNodeList childNodeList = optionalTypeDescriptorNode.children();
                        if (!validateChildNodes(childNodeList, semanticModel)) {
                            updateContext(syntaxNodeAnalysisContext, CompilationDiagnostic.INVALID_USE_OF_ID_ANNOTATION,
                                    annotationNode.location());
                        }
                    } else if (returnTypeDescriptorNode.type().kind() == SyntaxKind.ARRAY_TYPE_DESC) {
                        ArrayTypeDescriptorNode arrayTypeDescriptorNode =
                                (ArrayTypeDescriptorNode) returnTypeDescriptorNode.type();
                        ChildNodeList childNodeList = arrayTypeDescriptorNode.children();
                        if (!validateChildNodes(childNodeList, semanticModel)) {
                            updateContext(syntaxNodeAnalysisContext, CompilationDiagnostic.INVALID_USE_OF_ID_ANNOTATION,
                                    annotationNode.location());
                        }
                    } else {
                        updateContext(syntaxNodeAnalysisContext, CompilationDiagnostic.INVALID_USE_OF_ID_ANNOTATION,
                                annotationNode.location());
                    }
                } else {
                    updateContext(syntaxNodeAnalysisContext, CompilationDiagnostic.INVALID_USE_OF_ID_ANNOTATION,
                            annotationNode.location());
                }
            }
        }
    }

    private boolean validateChildNodes(ChildNodeList childNodeList, SemanticModel semanticModel) {
        boolean isValid = true;
        for (int i = 0; i < childNodeList.size(); i++) {
            if (childNodeList.get(i).kind() != SyntaxKind.ERROR_TYPE_DESC
                    && childNodeList.get(i).kind() != SyntaxKind.NIL_TYPE_DESC
                    && childNodeList.get(i).kind() != SyntaxKind.PIPE_TOKEN
                    && childNodeList.get(i).kind() != SyntaxKind.ARRAY_DIMENSION
                    && childNodeList.get(i).kind() != SyntaxKind.QUESTION_MARK_TOKEN) {
                if (semanticModel.symbol(childNodeList.get(i)).isPresent()) {
                    TypeSymbol typeSymbol =
                            (TypeSymbol) semanticModel.symbol(childNodeList.get(i)).get();
                    if (!checkTypeForValidation(typeSymbol)) {
                        isValid = false;
                    }
                } else if (childNodeList.get(i).kind() == SyntaxKind.OPTIONAL_TYPE_DESC) {
                    OptionalTypeDescriptorNode optionalTypeDescriptorNode =
                            (OptionalTypeDescriptorNode) childNodeList.get(i);
                    isValid = validateChildNodes(optionalTypeDescriptorNode.children(), semanticModel);
                } else if (childNodeList.get(i).kind() == SyntaxKind.ARRAY_TYPE_DESC) {
                    ArrayTypeDescriptorNode arrayTypeDescriptorNode =
                            (ArrayTypeDescriptorNode) childNodeList.get(i);
                    isValid = validateChildNodes(arrayTypeDescriptorNode.children(), semanticModel);
                }
            }
        }
        return isValid;
    }

    private boolean isValidIdTypeRefType(TypeReferenceTypeSymbol typeDescriptor) {
        return typeDescriptor.definition().getModule().isPresent()
                && Utils.isValidUuidModule(typeDescriptor.definition().getModule().get())
                && typeDescriptor.definition().getName().isPresent()
                && typeDescriptor.definition().getName().get().equals(Utils.UUID_RECORD_NAME);
    }

    private boolean isValidIdUnionType(UnionTypeSymbol typeDescriptor) {
        boolean isValid = true;
        List<TypeSymbol> memberTypes = typeDescriptor.memberTypeDescriptors();
        for (TypeSymbol memberType : memberTypes) {
            if (!(memberType.typeKind() == TypeDescKind.NIL) && !(memberType.typeKind() == TypeDescKind.ERROR)) {
                isValid = checkTypeForValidation(memberType);
                if (!isValid) {
                    break;
                }
            }
        }
        return isValid;
    }

    private boolean isValidIdType(TypeSymbol memberTypeDescriptor) {
        return memberTypeDescriptor.typeKind() == TypeDescKind.STRING
                || memberTypeDescriptor.typeKind() == TypeDescKind.INT
                || memberTypeDescriptor.typeKind() == TypeDescKind.FLOAT
                || memberTypeDescriptor.typeKind() == TypeDescKind.DECIMAL;
    }

    private boolean checkTypeForValidation(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() == TypeDescKind.ARRAY) {
            return checkTypeForValidation(((ArrayTypeSymbol) typeSymbol).memberTypeDescriptor());
        } else if (typeSymbol.typeKind() == TypeDescKind.UNION) {
            return isValidIdUnionType((UnionTypeSymbol) typeSymbol);
        } else if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            return isValidIdTypeRefType((TypeReferenceTypeSymbol) typeSymbol);
        } else {
            return isValidIdType(typeSymbol);
        }
    }
}
