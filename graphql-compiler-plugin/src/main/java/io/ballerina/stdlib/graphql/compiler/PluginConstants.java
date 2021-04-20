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
    public static final String UNARY_NEGATIVE = "-";

    /**
     * Compilation errors.
     */
    enum CompilationErrors {
        INVALID_FUNCTION("Invalid method. Remote methods are not allowed.",
                "GRAPHQL_101", DiagnosticSeverity.ERROR),
        INVALID_RETURN_TYPE("Invalid return type for resource function.", "GRAPHQL_102",
                DiagnosticSeverity.ERROR),
        INVALID_RESOURCE_INPUT_PARAM("Invalid resource input parameter type.", "GRAPHQL_103",
                DiagnosticSeverity.ERROR),
        INVALID_RETURN_TYPE_NIL("Invalid return type nil. Resource function must have a return type.",
                "GRAPHQL_104", DiagnosticSeverity.ERROR),
        INVALID_RETURN_TYPE_ERROR_OR_NIL("Invalid return type error or nil. " +
                "Resource function must have a return data type.", "GRAPHQL_105", DiagnosticSeverity.ERROR),
        INVALID_RESOURCE_FUNCTION_ACCESSOR("Invalid resource function accessor. Only get is allowed",
                "GRAPHQL_106", DiagnosticSeverity.ERROR),
        INVALID_MULTIPLE_LISTENERS("Multiple listener attachments. Only one graphql:Listener is allowed.",
                "GRAPHQL_107", DiagnosticSeverity.ERROR),
        INVALID_MAX_QUERY_DEPTH("Invalid maxQueryDepth value. Value must be a positive integer",
                "GRAPHQL_108", DiagnosticSeverity.ERROR);

        private final String error;
        private final String errorCode;
        private final DiagnosticSeverity diagnosticSeverity;

        CompilationErrors(String error, String errorCode, DiagnosticSeverity diagnosticSeverity) {
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
