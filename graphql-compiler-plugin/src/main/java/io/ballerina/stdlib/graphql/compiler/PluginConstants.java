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

import io.ballerina.tools.diagnostics.DiagnosticSeverity;

/**
 * GraphQl compiler plugin constants.
 */
public class PluginConstants {

    // compiler plugin constants
    public static final String PACKAGE_PREFIX = "graphql";
    public static final String PACKAGE_ORG = "ballerina";

    // resource function constants
    public static final String RESOURCE_FUNCTION_GET = "get";
    public static final String MAX_QUERY_DEPTH = "maxQueryDepth";
    public static final String LISTENER_IDENTIFIER = "Listener";
    public static final String UNARY_NEGATIVE = "-";
    public static final String DOUBLE_UNDERSCORES = "__";

    /**
     * Compilation errors.
     */
    enum CompilationError {
        INVALID_FUNCTION("Remote methods are not allowed in service objects returned from Graphql resource functions",
                         "GRAPHQL_101", DiagnosticSeverity.ERROR),
        INVALID_RETURN_TYPE("Invalid return type for GraphQL resource/remote function", "GRAPHQL_102",
                            DiagnosticSeverity.ERROR),
        INVALID_INPUT_PARAM("Invalid input parameter type for GraphQL resource/remote function", "GRAPHQL_103",
                            DiagnosticSeverity.ERROR),
        INVALID_RETURN_TYPE_NIL("A GraphQL resource/remote function must have a return type", "GRAPHQL_104",
                                DiagnosticSeverity.ERROR),
        INVALID_RETURN_TYPE_ERROR_OR_NIL("A Graphql resource/remote function must have a return data type",
                                         "GRAPHQL_105", DiagnosticSeverity.ERROR),
        INVALID_RESOURCE_FUNCTION_ACCESSOR("Graphql resource functions allows only \"get\" accessor", "GRAPHQL_106",
                                           DiagnosticSeverity.ERROR),
        INVALID_MULTIPLE_LISTENERS("A GraphQL service can have only one graphql:Listener attached", "GRAPHQL_107",
                                   DiagnosticSeverity.ERROR),
        INVALID_MAX_QUERY_DEPTH("The maxQueryDepth value must be a positive integer", "GRAPHQL_108",
                                DiagnosticSeverity.ERROR),
        INVALID_RETURN_TYPE_ERROR("A GraphQL resource/remote function must have a return data type", "GRAPHQL_109",
                                  DiagnosticSeverity.ERROR),
        INVALID_LISTENER_INIT("The http:Listener and the graphql:ListenerConfiguration are mutually exclusive",
                              "GRAPHQL_110", DiagnosticSeverity.ERROR),
        INVALID_RETURN_TYPE_MULTIPLE_SERVICES("GraphQL union types must only consist distinct service objects",
                                              "GRAPHQL_111", DiagnosticSeverity.ERROR),
        INVALID_FIELD_NAME(
                "A GraphQL field Name must not begin with \"__\", which is reserved by GraphQL introspection",
                "GRAPHQL_112", DiagnosticSeverity.ERROR),
        MISSING_INPUT_PARAMETER("A GraphQL remote function must have input arguments", "GRAPHQL_113",
                                DiagnosticSeverity.ERROR),
        MISSING_RESOURCE_FUNCTIONS("A GraphQL service must have at least one resource function", "GRAPHQL_114",
                                   DiagnosticSeverity.ERROR);

        private final String error;
        private final String errorCode;
        private final DiagnosticSeverity diagnosticSeverity;

        CompilationError(String error, String errorCode, DiagnosticSeverity diagnosticSeverity) {
            this.error = error;
            this.errorCode = errorCode;
            this.diagnosticSeverity = diagnosticSeverity;
        }

        String getError() {
            return error;
        }

        String getErrorCode() {
            return errorCode;
        }

        DiagnosticSeverity getDiagnosticSeverity() {
            return this.diagnosticSeverity;
        }
    }

    private PluginConstants() {
    }
}
