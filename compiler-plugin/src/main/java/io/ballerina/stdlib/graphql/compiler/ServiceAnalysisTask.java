/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.schema.generator.SchemaGenerator;
import io.ballerina.stdlib.graphql.compiler.service.validator.ServiceValidator;

import static io.ballerina.stdlib.graphql.compiler.Utils.hasCompilationErrors;
import static io.ballerina.stdlib.graphql.compiler.Utils.isGraphQlService;

/**
 * Validates a Ballerina GraphQL Service.
 */
public class ServiceAnalysisTask implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private final ServiceValidator serviceValidator;
    private final SchemaGenerator schemaGenerator;

    public ServiceAnalysisTask() {
        this.serviceValidator = new ServiceValidator();
        this.schemaGenerator = new SchemaGenerator();
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        if (hasCompilationErrors(context)) {
            return;
        }
        if (!isGraphQlService(context)) {
            return;
        }
        this.serviceValidator.initialize(context);
        this.serviceValidator.validate();
        if (this.serviceValidator.isErrorOccurred()) {
            return;
        }
        this.schemaGenerator.initialize(this.serviceValidator.getInterfaceFinder());
        this.schemaGenerator.generate(context);
    }
}
