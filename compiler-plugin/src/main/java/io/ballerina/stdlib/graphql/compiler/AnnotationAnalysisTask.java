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

import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.RequiredParameterNode;
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.diagnostics.CompilationDiagnostic;

import java.util.Arrays;

import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.updateContext;

/**
 * Validates the usages of the annotation, @graphql:ID.
 */
public class AnnotationAnalysisTask implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private static final String ID_ANNOTATION = "graphql:ID";
    // todo: add UUID
    private static final String[] allowedTypes = {"int", "string", "float", "decimal"};

    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        AnnotationNode annotationNode = (AnnotationNode) syntaxNodeAnalysisContext.node();
        if (annotationNode.annotReference().toString().equals(ID_ANNOTATION)) {
            if (annotationNode.parent().kind() == SyntaxKind.REQUIRED_PARAM) {
                RequiredParameterNode requiredParameterNode = (RequiredParameterNode) annotationNode.parent();
                if (!Arrays.asList(allowedTypes).contains(requiredParameterNode.typeName().toString())) {
                    updateContext(syntaxNodeAnalysisContext, CompilationDiagnostic.INVALID_USE_OF_ID_ANNOTATION,
                            requiredParameterNode.location());
                }
            } else if (annotationNode.parent().kind() == SyntaxKind.RETURN_TYPE_DESCRIPTOR) {
                ReturnTypeDescriptorNode returnTypeDescriptorNode = (ReturnTypeDescriptorNode) annotationNode.parent();
                if (!Arrays.asList(allowedTypes).contains(returnTypeDescriptorNode.type().toString())) {
                    updateContext(syntaxNodeAnalysisContext, CompilationDiagnostic.INVALID_USE_OF_ID_ANNOTATION,
                            returnTypeDescriptorNode.location());
                }
            }
        }
    }
}
