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

package io.ballerina.stdlib.graphql.compiler.analyzer;

import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.CodeAnalysisContext;
import io.ballerina.projects.plugins.CodeAnalyzer;
import io.ballerina.stdlib.graphql.compiler.InterceptorAnalysisTask;
import io.ballerina.stdlib.graphql.compiler.ModuleLevelVariableDeclarationAnalysisTask;
import io.ballerina.stdlib.graphql.compiler.ObjectConstructorAnalysisTask;
import io.ballerina.stdlib.graphql.compiler.ServiceDeclarationAnalysisTask;
import io.ballerina.stdlib.graphql.compiler.service.validator.ListenerValidator;

import java.util.Arrays;
import java.util.Map;

import static io.ballerina.stdlib.graphql.compiler.Utils.IS_ANALYSIS_COMPLETED;

public class GraphqlCodeAnalyzer extends CodeAnalyzer {

    private final Map<String, Object> userData;

    public GraphqlCodeAnalyzer(Map<String, Object> userData) {
        this.userData = userData;
    }

    @Override
    public void init(CodeAnalysisContext codeAnalysisContext) {
        if (this.userData == null) {
            return;
        }
        if (this.userData.isEmpty()) {
            this.analyze(codeAnalysisContext);
        } else if (this.userData.containsKey(IS_ANALYSIS_COMPLETED)) {
            boolean isAnalysisCompleted = (boolean) this.userData.get(IS_ANALYSIS_COMPLETED);
            if (!isAnalysisCompleted) {
                this.analyze(codeAnalysisContext);
            }
        }
    }

    private void analyze(CodeAnalysisContext codeAnalysisContext) {
        codeAnalysisContext.addSyntaxNodeAnalysisTask(new ServiceDeclarationAnalysisTask(this.userData),
                SyntaxKind.SERVICE_DECLARATION);
        codeAnalysisContext.addSyntaxNodeAnalysisTask(
                new ObjectConstructorAnalysisTask(this.userData), SyntaxKind.OBJECT_CONSTRUCTOR);
        codeAnalysisContext.addSyntaxNodeAnalysisTask(new InterceptorAnalysisTask(), SyntaxKind.CLASS_DEFINITION);
        codeAnalysisContext.addSyntaxNodeAnalysisTask(new ListenerValidator(),
                Arrays.asList(SyntaxKind.IMPLICIT_NEW_EXPRESSION,
                        SyntaxKind.EXPLICIT_NEW_EXPRESSION));
        codeAnalysisContext.addSyntaxNodeAnalysisTask(new ModuleLevelVariableDeclarationAnalysisTask(this.userData),
                SyntaxKind.MODULE_VAR_DECL);
    }
}
