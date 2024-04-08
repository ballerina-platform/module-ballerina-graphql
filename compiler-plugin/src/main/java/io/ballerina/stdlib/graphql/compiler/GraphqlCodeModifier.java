/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org).
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

import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.plugins.CodeModifier;
import io.ballerina.projects.plugins.CodeModifierContext;
import io.ballerina.stdlib.graphql.compiler.schema.generator.GraphqlModifierContext;
import io.ballerina.stdlib.graphql.compiler.schema.generator.GraphqlSourceModifier;
import io.ballerina.stdlib.graphql.compiler.service.validator.ListenerValidator;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import static io.ballerina.stdlib.graphql.compiler.Utils.IS_ANALYSIS_COMPLETED;
import static io.ballerina.stdlib.graphql.compiler.Utils.MODIFIER_CONTEXT_MAP;

/**
 * Analyzes a Ballerina GraphQL service and report diagnostics, and generates a schema for a valid service.
 */
public class GraphqlCodeModifier extends CodeModifier {
    private final Map<String, Object> userData;
    private final Map<DocumentId, GraphqlModifierContext> modifierContextMap;

    public GraphqlCodeModifier(Map<String, Object> userData) {
        this.modifierContextMap = new HashMap<>();
        this.userData = userData;
        userData.put(MODIFIER_CONTEXT_MAP, this.modifierContextMap);
    }

    @Override
    public void init(CodeModifierContext modifierContext) {
        modifierContext.addSyntaxNodeAnalysisTask(new ServiceDeclarationAnalysisTask(this.userData),
                SyntaxKind.SERVICE_DECLARATION);
        modifierContext.addSyntaxNodeAnalysisTask(
                new ObjectConstructorAnalysisTask(this.userData), SyntaxKind.OBJECT_CONSTRUCTOR);
        modifierContext.addSyntaxNodeAnalysisTask(new InterceptorAnalysisTask(), SyntaxKind.CLASS_DEFINITION);
        modifierContext.addSyntaxNodeAnalysisTask(new ListenerValidator(),
                Arrays.asList(SyntaxKind.IMPLICIT_NEW_EXPRESSION,
                        SyntaxKind.EXPLICIT_NEW_EXPRESSION));
        modifierContext.addSyntaxNodeAnalysisTask(new AnnotationAnalysisTask(), SyntaxKind.ANNOTATION);
        modifierContext.addSyntaxNodeAnalysisTask(new ModuleLevelVariableDeclarationAnalysisTask(this.userData),
                SyntaxKind.MODULE_VAR_DECL);
        modifierContext.addSourceModifierTask(new GraphqlSourceModifier(this.modifierContextMap));
        this.userData.put(IS_ANALYSIS_COMPLETED, true);
    }
}
