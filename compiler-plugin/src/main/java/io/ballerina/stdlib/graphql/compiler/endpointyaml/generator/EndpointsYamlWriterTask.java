/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com)
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

package io.ballerina.stdlib.graphql.compiler.endpointyaml.generator;

import io.ballerina.projects.Package;
import io.ballerina.projects.plugins.CompilerLifecycleEventContext;
import io.ballerina.projects.plugins.CompilerLifecycleTask;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.diagnostics.Location;
import io.ballerina.tools.text.LinePosition;
import io.ballerina.tools.text.LineRange;
import io.ballerina.tools.text.TextRange;

import java.io.IOException;
import java.util.List;
import java.util.Map;

import static io.ballerina.stdlib.graphql.compiler.Utils.GRAPHQL_EXPORTED_ENDPOINTS;

/*
 * Writes every endpoint collected by {@link io.ballerina.stdlib.graphql.compiler.ServiceDeclarationAnalysisTask}
 * during code analysis into a single, consolidated endpoints.yaml, once for the whole compilation after code
 * generation has completed.
 */
public class EndpointsYamlWriterTask implements CompilerLifecycleTask<CompilerLifecycleEventContext> {
    private final Map<String, Object> ctxData;

    public EndpointsYamlWriterTask(Map<String, Object> ctxData) {
        this.ctxData = ctxData;
    }

    @Override
    @SuppressWarnings("unchecked")
    public void perform(CompilerLifecycleEventContext context) {
        List<Endpoint> endpoints = (List<Endpoint>) ctxData.get(GRAPHQL_EXPORTED_ENDPOINTS);
        if (endpoints == null || endpoints.isEmpty()) {
            return;
        }
        Package currentPackage = context.currentPackage();
        if (currentPackage == null) {
            return;
        }
        try {
            EndpointYamlGenerator.writeEndpointsYaml(currentPackage.project().targetDir(), endpoints);
        } catch (IOException e) {
            context.reportDiagnostic(DiagnosticFactory.createDiagnostic(
                    new DiagnosticInfo("GRAPHQL_PLUGIN_DEBUG", "[graphql-plugin] " + e.getMessage(),
                            DiagnosticSeverity.ERROR),
                    NULL_LOCATION));
        }
    }

    private static final Location NULL_LOCATION = new Location() {
        private static final LineRange LINE_RANGE =
                LineRange.from("", LinePosition.from(0, 0), LinePosition.from(0, 0));
        private static final TextRange TEXT_RANGE = TextRange.from(0, 0);

        @Override
        public LineRange lineRange() {
            return LINE_RANGE;
        }

        @Override
        public TextRange textRange() {
            return TEXT_RANGE;
        }
    };
}
