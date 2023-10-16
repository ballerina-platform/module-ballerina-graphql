/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
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
import io.ballerina.projects.ModuleId;
import io.ballerina.projects.Project;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

/**
 * Holds the information needed for NodeFinders and SchemaGenerator.
 */
public class FinderContext {
    private final SemanticModel semanticModel;
    private final Project project;
    private final ModuleId moduleId;

    public FinderContext(SemanticModel semanticModel, Project project, ModuleId moduleId) {
        this.semanticModel = semanticModel;
        this.project = project;
        this.moduleId = moduleId;
    }

    public FinderContext(SyntaxNodeAnalysisContext context) {
        this.semanticModel = context.semanticModel();
        this.project = context.currentPackage().project();
        this.moduleId = context.moduleId();
    }

    public SemanticModel semanticModel() {
        return semanticModel;
    }

    public Project project() {
        return project;
    }

    public ModuleId moduleId() {
        return moduleId;
    }
}
