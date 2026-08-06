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
        for (Endpoint endpoint : endpoints) {
            addEndpointMetadata(context, endpoint);
        }
    }

    private void addEndpointMetadata(CompilerLifecycleEventContext context, Endpoint endpoint) {
        try {
            Class<?> endpointMetaInfoClass = Class.forName(ENDPOINT_META_INFO_CLASS);
            Constructor<?> constructor = endpointMetaInfoClass.getConstructor(String.class, int.class, String.class,
                    String.class, String.class);
            Object endpointMetaInfo = constructor.newInstance(endpoint.getName(), endpoint.getPort(),
                    endpoint.getBasePath(), endpoint.getType(), endpoint.getSchemaPath());
            Method method = context.getClass().getMethod(ADD_ENDPOINT_METADATA_METHOD, endpointMetaInfoClass);
            method.setAccessible(true);
            method.invoke(context, endpointMetaInfo);
        } catch (ReflectiveOperationException | SecurityException e) {
            // Endpoint metadata export is supported only with newer Ballerina lang versions.
        }
    }
}
