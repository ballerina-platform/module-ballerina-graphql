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
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.graphql.compiler.endpointyaml.generator;

import io.ballerina.projects.plugins.CompilerLifecycleEventContext;
import io.ballerina.projects.plugins.CompilerLifecycleTask;
import io.ballerina.stdlib.graphql.compiler.diagnostics.CompilationDiagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.Location;
import io.ballerina.tools.text.LinePosition;
import io.ballerina.tools.text.LineRange;
import io.ballerina.tools.text.TextRange;

import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.util.List;
import java.util.Map;

import static io.ballerina.stdlib.graphql.compiler.Utils.GRAPHQL_EXPORTED_ENDPOINTS;

/**
 * Publishes every endpoint collected by {@link io.ballerina.stdlib.graphql.compiler.ServiceDeclarationAnalysisTask}
 * during code analysis to Ballerina lang, once for the whole compilation after code generation has completed.
 */
public class EndpointMetadataTask implements CompilerLifecycleTask<CompilerLifecycleEventContext> {
    private static final String ENDPOINT_META_INFO_CLASS = "io.ballerina.projects.plugins.EndpointMetaInfo";
    private static final String ADD_ENDPOINT_METADATA_METHOD = "addEndpointMetadata";

    private final Map<String, Object> ctxData;

    public EndpointMetadataTask(Map<String, Object> ctxData) {
        this.ctxData = ctxData;
    }

    @Override
    @SuppressWarnings("unchecked")
    public void perform(CompilerLifecycleEventContext context) {
        List<Endpoint> endpoints = (List<Endpoint>) ctxData.get(GRAPHQL_EXPORTED_ENDPOINTS);
        if (endpoints == null || endpoints.isEmpty()) {
            return;
        }
        try {
            for (Endpoint endpoint : endpoints) {
                addEndpointMetadata(context, endpoint);
            }
        } catch (ReflectiveOperationException | SecurityException e) {
            DiagnosticInfo diagnosticInfo = new DiagnosticInfo(
                    CompilationDiagnostic.UNSUPPORTED_ENDPOINT_METADATA.getDiagnosticCode(),
                    CompilationDiagnostic.UNSUPPORTED_ENDPOINT_METADATA.getDiagnostic(),
                    CompilationDiagnostic.UNSUPPORTED_ENDPOINT_METADATA.getDiagnosticSeverity());
            context.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, new NullLocation()));
        }
    }

    private void addEndpointMetadata(CompilerLifecycleEventContext context, Endpoint endpoint)
            throws ReflectiveOperationException {
        Class<?> endpointMetaInfoClass = Class.forName(ENDPOINT_META_INFO_CLASS);
        Constructor<?> constructor = endpointMetaInfoClass.getConstructor(String.class, int.class, String.class,
                String.class, String.class);
        Object endpointMetaInfo = constructor.newInstance(endpoint.getName(), endpoint.getPort(),
                endpoint.getBasePath(), endpoint.getType(), endpoint.getSchemaPath());
        Method method = context.getClass().getMethod(ADD_ENDPOINT_METADATA_METHOD, endpointMetaInfoClass);
        method.setAccessible(true);
        method.invoke(context, endpointMetaInfo);
    }

    private static class NullLocation implements Location {
        @Override
        public LineRange lineRange() {
            LinePosition position = LinePosition.from(0, 0);
            return LineRange.from("", position, position);
        }

        @Override
        public TextRange textRange() {
            return TextRange.from(0, 0);
        }
    }
}
