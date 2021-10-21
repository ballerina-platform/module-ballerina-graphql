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

package io.ballerina.stdlib.graphql.compiler.validator.errors;

import io.ballerina.tools.diagnostics.DiagnosticSeverity;

/**
 * Compilation errors in the Ballerina GraphQL package.
 */
public enum CompilationError {
    INVALID_FUNCTION(ErrorMessage.ERROR_101, ErrorCode.GRAPHQL_101, DiagnosticSeverity.ERROR),
    INVALID_RETURN_TYPE(ErrorMessage.ERROR_102, ErrorCode.GRAPHQL_102, DiagnosticSeverity.ERROR),
    INVALID_RESOURCE_INPUT_PARAM(ErrorMessage.ERROR_103, ErrorCode.GRAPHQL_103, DiagnosticSeverity.ERROR),
    INVALID_RETURN_TYPE_NIL(ErrorMessage.ERROR_104, ErrorCode.GRAPHQL_104, DiagnosticSeverity.ERROR),
    INVALID_RETURN_TYPE_ERROR_OR_NIL(ErrorMessage.ERROR_105, ErrorCode.GRAPHQL_105, DiagnosticSeverity.ERROR),
    INVALID_RESOURCE_FUNCTION_ACCESSOR(ErrorMessage.ERROR_106, ErrorCode.GRAPHQL_106, DiagnosticSeverity.ERROR),
    INVALID_MULTIPLE_LISTENERS(ErrorMessage.ERROR_107, ErrorCode.GRAPHQL_107, DiagnosticSeverity.ERROR),
    INVALID_RETURN_TYPE_ERROR(ErrorMessage.ERROR_108, ErrorCode.GRAPHQL_108, DiagnosticSeverity.ERROR),
    INVALID_LISTENER_INIT(ErrorMessage.ERROR_109, ErrorCode.GRAPHQL_109, DiagnosticSeverity.ERROR),
    INVALID_RETURN_TYPE_MULTIPLE_SERVICES(ErrorMessage.ERROR_110, ErrorCode.GRAPHQL_110, DiagnosticSeverity.ERROR),
    INVALID_FIELD_NAME(ErrorMessage.ERROR_111, ErrorCode.GRAPHQL_111, DiagnosticSeverity.ERROR),
    INVALID_RETURN_TYPE_ANY(ErrorMessage.ERROR_112, ErrorCode.GRAPHQL_112, DiagnosticSeverity.ERROR),
    MISSING_RESOURCE_FUNCTIONS(ErrorMessage.ERROR_113, ErrorCode.GRAPHQL_113, DiagnosticSeverity.ERROR),
    INVALID_RETURN_TYPE_INPUT_OBJECT(ErrorMessage.ERROR_114, ErrorCode.GRAPHQL_114, DiagnosticSeverity.ERROR),
    INVALID_RESOURCE_INPUT_OBJECT_PARAM(ErrorMessage.ERROR_115, ErrorCode.GRAPHQL_115, DiagnosticSeverity.ERROR),
    INVALID_LOCATION_FOR_CONTEXT_PARAMETER(ErrorMessage.ERROR_116, ErrorCode.GRAPHQL_116, DiagnosticSeverity.ERROR),
    NON_DISTINCT_INTERFACE_CLASS(ErrorMessage.ERROR_117, ErrorCode.GRAPHQL_117, DiagnosticSeverity.ERROR),
    INVALID_INTERFACE_IMPLEMENTATION(ErrorMessage.ERROR_118, ErrorCode.GRAPHQL_118, DiagnosticSeverity.ERROR);

    private final String error;
    private final String errorCode;
    private final DiagnosticSeverity diagnosticSeverity;

    CompilationError(ErrorMessage message, ErrorCode errorCode, DiagnosticSeverity diagnosticSeverity) {
        this.error = message.getMessage();
        this.errorCode = errorCode.name();
        this.diagnosticSeverity = diagnosticSeverity;
    }

    public String getError() {
        return error;
    }

    public String getErrorCode() {
        return errorCode;
    }

    public DiagnosticSeverity getDiagnosticSeverity() {
        return this.diagnosticSeverity;
    }
}
