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

package io.ballerina.stdlib.graphql.compiler.diagnostics;

import io.ballerina.tools.diagnostics.DiagnosticSeverity;

/**
 * Compilation errors in the Ballerina GraphQL package.
 */
public enum CompilationDiagnostic {
    INVALID_FUNCTION(DiagnosticMessage.ERROR_101, DiagnosticCode.GRAPHQL_101, DiagnosticSeverity.ERROR),
    INVALID_RETURN_TYPE(DiagnosticMessage.ERROR_102, DiagnosticCode.GRAPHQL_102, DiagnosticSeverity.ERROR),
    INVALID_INPUT_PARAMETER_TYPE(DiagnosticMessage.ERROR_103, DiagnosticCode.GRAPHQL_103, DiagnosticSeverity.ERROR),
    INVALID_RETURN_TYPE_NIL(DiagnosticMessage.ERROR_104, DiagnosticCode.GRAPHQL_104, DiagnosticSeverity.ERROR),
    INVALID_RETURN_TYPE_ERROR_OR_NIL(DiagnosticMessage.ERROR_105, DiagnosticCode.GRAPHQL_105, DiagnosticSeverity.ERROR),
    INVALID_RESOURCE_FUNCTION_ACCESSOR(DiagnosticMessage.ERROR_106, DiagnosticCode.GRAPHQL_106,
                                       DiagnosticSeverity.ERROR),
    INVALID_MULTIPLE_LISTENERS(DiagnosticMessage.ERROR_107, DiagnosticCode.GRAPHQL_107, DiagnosticSeverity.ERROR),
    INVALID_RETURN_TYPE_ERROR(DiagnosticMessage.ERROR_108, DiagnosticCode.GRAPHQL_108, DiagnosticSeverity.ERROR),
    INVALID_LISTENER_INIT(DiagnosticMessage.ERROR_109, DiagnosticCode.GRAPHQL_109, DiagnosticSeverity.ERROR),
    INVALID_UNION_MEMBER_TYPE(DiagnosticMessage.ERROR_110, DiagnosticCode.GRAPHQL_110, DiagnosticSeverity.ERROR),
    INVALID_FIELD_NAME(DiagnosticMessage.ERROR_111, DiagnosticCode.GRAPHQL_111, DiagnosticSeverity.ERROR),
    INVALID_RETURN_TYPE_ANY(DiagnosticMessage.ERROR_112, DiagnosticCode.GRAPHQL_112, DiagnosticSeverity.ERROR),
    MISSING_RESOURCE_FUNCTIONS(DiagnosticMessage.ERROR_113, DiagnosticCode.GRAPHQL_113, DiagnosticSeverity.ERROR),
    INVALID_RETURN_TYPE_INPUT_OBJECT(DiagnosticMessage.ERROR_114, DiagnosticCode.GRAPHQL_114, DiagnosticSeverity.ERROR),
    INVALID_RESOURCE_INPUT_OBJECT_PARAM(DiagnosticMessage.ERROR_115, DiagnosticCode.GRAPHQL_115,
                                        DiagnosticSeverity.ERROR),
    NON_DISTINCT_INTERFACE(DiagnosticMessage.ERROR_116, DiagnosticCode.GRAPHQL_116, DiagnosticSeverity.ERROR),
    INVALID_PATH_PARAMETERS(DiagnosticMessage.ERROR_117, DiagnosticCode.GRAPHQL_117, DiagnosticSeverity.ERROR),
    INVALID_RESOURCE_PATH(DiagnosticMessage.ERROR_118, DiagnosticCode.GRAPHQL_118, DiagnosticSeverity.ERROR),
    INVALID_FILE_UPLOAD_IN_RESOURCE_FUNCTION(DiagnosticMessage.ERROR_119, DiagnosticCode.GRAPHQL_119,
                                             DiagnosticSeverity.ERROR),
    MULTI_DIMENSIONAL_UPLOAD_ARRAY(DiagnosticMessage.ERROR_120, DiagnosticCode.GRAPHQL_120, DiagnosticSeverity.ERROR),
    INVALID_INPUT_TYPE(DiagnosticMessage.ERROR_121, DiagnosticCode.GRAPHQL_121, DiagnosticSeverity.ERROR),
    INVALID_INPUT_TYPE_UNION(DiagnosticMessage.ERROR_122, DiagnosticCode.GRAPHQL_122, DiagnosticSeverity.ERROR),
    NON_DISTINCT_INTERFACE_IMPLEMENTATION(DiagnosticMessage.ERROR_123, DiagnosticCode.GRAPHQL_123,
                                          DiagnosticSeverity.ERROR),
    INVALID_HIERARCHICAL_RESOURCE_PATH(DiagnosticMessage.ERROR_124, DiagnosticCode.GRAPHQL_124,
                                       DiagnosticSeverity.ERROR),
    INVALID_SUBSCRIBE_RESOURCE_RETURN_TYPE(DiagnosticMessage.ERROR_125, DiagnosticCode.GRAPHQL_125,
                                           DiagnosticSeverity.ERROR),
    INVALID_ROOT_RESOURCE_ACCESSOR(DiagnosticMessage.ERROR_126, DiagnosticCode.GRAPHQL_126, DiagnosticSeverity.ERROR),
    SCHEMA_GENERATION_FAILED(DiagnosticMessage.ERROR_127, DiagnosticCode.GRAPHQL_127, DiagnosticSeverity.ERROR),
    RESOURCE_METHOD_INSIDE_INTERCEPTOR(DiagnosticMessage.ERROR_128, DiagnosticCode.GRAPHQL_128,
                                       DiagnosticSeverity.ERROR),
    INVALID_REMOTE_METHOD_INSIDE_INTERCEPTOR(DiagnosticMessage.ERROR_129, DiagnosticCode.GRAPHQL_129,
                                             DiagnosticSeverity.ERROR),
    INVALID_ANONYMOUS_FIELD_TYPE(DiagnosticMessage.ERROR_130, DiagnosticCode.GRAPHQL_130, DiagnosticSeverity.ERROR),
    INVALID_ANONYMOUS_INPUT_TYPE(DiagnosticMessage.ERROR_131, DiagnosticCode.GRAPHQL_131, DiagnosticSeverity.ERROR),
    INVALID_RETURN_TYPE_CLASS(DiagnosticMessage.ERROR_132, DiagnosticCode.GRAPHQL_132, DiagnosticSeverity.ERROR),
    INVALID_USE_OF_RESERVED_REMOTE_METHOD_NAME(DiagnosticMessage.ERROR_133, DiagnosticCode.GRAPHQL_133,
                                               DiagnosticSeverity.ERROR),
    INVALID_USE_OF_RESERVED_RESOURCE_PATH(DiagnosticMessage.ERROR_134, DiagnosticCode.GRAPHQL_134,
                                          DiagnosticSeverity.ERROR),
    INVALID_USE_OF_RESERVED_TYPE_AS_OUTPUT_TYPE(DiagnosticMessage.ERROR_135, DiagnosticCode.GRAPHQL_135,
                                                DiagnosticSeverity.ERROR),
    INVALID_USE_OF_RESERVED_TYPE_AS_INPUT_TYPE(DiagnosticMessage.ERROR_136, DiagnosticCode.GRAPHQL_136,
                                               DiagnosticSeverity.ERROR),
    FAILED_TO_ADD_ENTITY_RESOLVER(DiagnosticMessage.ERROR_137, DiagnosticCode.GRAPHQL_137, DiagnosticSeverity.ERROR),
    FAILED_TO_ADD_SERVICE_RESOLVER(DiagnosticMessage.ERROR_138, DiagnosticCode.GRAPHQL_138, DiagnosticSeverity.ERROR),
    UNSUPPORTED_TYPE_ALIAS(DiagnosticMessage.ERROR_139, DiagnosticCode.GRAPHQL_139, DiagnosticSeverity.ERROR),
    INVALID_USE_OF_ID_ANNOTATION(DiagnosticMessage.ERROR_140, DiagnosticCode.GRAPHQL_140, DiagnosticSeverity.ERROR),
    MISSING_GRAPHQL_CONTEXT_PARAMETER(DiagnosticMessage.ERROR_141, DiagnosticCode.GRAPHQL_141,
                                      DiagnosticSeverity.ERROR),
    INVALID_PARAMETER_IN_PREFETCH_METHOD(DiagnosticMessage.ERROR_142, DiagnosticCode.GRAPHQL_142,
                                         DiagnosticSeverity.ERROR),
    INVALID_RETURN_TYPE_IN_PREFETCH_METHOD(DiagnosticMessage.ERROR_143, DiagnosticCode.GRAPHQL_143,
                                           DiagnosticSeverity.ERROR),
    UNABLE_TO_FIND_PREFETCH_METHOD(DiagnosticMessage.ERROR_144, DiagnosticCode.GRAPHQL_144, DiagnosticSeverity.ERROR),
    INVALID_USAGE_OF_PREFETCH_METHOD_NAME_CONFIG(DiagnosticMessage.ERROR_145, DiagnosticCode.GRAPHQL_145,
                                                 DiagnosticSeverity.ERROR),
    INVALID_EMPTY_RECORD_OBJECT_TYPE(DiagnosticMessage.ERROR_146, DiagnosticCode.GRAPHQL_146, DiagnosticSeverity.ERROR),
    INVALID_EMPTY_RECORD_INPUT_TYPE(DiagnosticMessage.ERROR_147, DiagnosticCode.GRAPHQL_147, DiagnosticSeverity.ERROR),
    INVALID_MODIFICATION_OF_SERVICE_CONFIG_FIELD(DiagnosticMessage.ERROR_148, DiagnosticCode.GRAPHQL_148,
                                                 DiagnosticSeverity.ERROR),
    INVALID_ENTITY_FIELD(DiagnosticMessage.ERROR_149, DiagnosticCode.GRAPHQL_149, DiagnosticSeverity.ERROR),

    // Warnings
    UNSUPPORTED_INPUT_FIELD_DEPRECATION(DiagnosticMessage.WARNING_201, DiagnosticCode.GRAPHQL_201,
                                        DiagnosticSeverity.WARNING),
    UNABLE_TO_VALIDATE_PREFETCH_METHOD(DiagnosticMessage.WARNING_202, DiagnosticCode.GRAPHQL_202,
                                       DiagnosticSeverity.WARNING),
    PROVIDE_KEY_VALUE_PAIR_FOR_ENTITY_ANNOTATION(DiagnosticMessage.WARNING_203, DiagnosticCode.GRAPHQL_203,
                                                 DiagnosticSeverity.WARNING),
    PROVIDE_A_STRING_LITERAL_OR_AN_ARRAY_OF_STRING_LITERALS_FOR_KEY_FIELD(DiagnosticMessage.WARNING_204,
                                                                          DiagnosticCode.GRAPHQL_204,
                                                                          DiagnosticSeverity.WARNING),
    UNABLE_TO_INFER_DEFAULT_VALUE_AT_COMPILE_TIME(DiagnosticMessage.WARNING_205, DiagnosticCode.GRAPHQL_205,
                                                  DiagnosticSeverity.WARNING),
    UNABLE_TO_INFER_DEFAULT_VALUE_PROVIDE_KEY_VALUE_PAIR(DiagnosticMessage.WARNING_206, DiagnosticCode.GRAPHQL_206,
                                                         DiagnosticSeverity.WARNING),
    PROVIDE_LITERAL_OR_CONSTRUCTOR_EXPRESSION_FOR_DEFAULT_PARAM(DiagnosticMessage.WARNING_207,
                                                                DiagnosticCode.GRAPHQL_207, DiagnosticSeverity.WARNING),
    UNABLE_TO_INFER_DEFAULT_VALUE_AVOID_USING_SPREAD_OPERATION(DiagnosticMessage.WARNING_208,
                                                               DiagnosticCode.GRAPHQL_208, DiagnosticSeverity.WARNING),
    UNABLE_TO_VALIDATE_DEFAULT_VALUES_OF_INPUT_FIELD_AT_COMPILE_TIME(DiagnosticMessage.WARNING_209,
                                                                     DiagnosticCode.WARNING_209,
                                                                     DiagnosticSeverity.WARNING),
    UNABLE_TO_VALIDATE_DEFAULT_VALUES_OF_INPUT_OBJECT_AT_COMPILE_TIME(DiagnosticMessage.WARNING_210,
                                                                      DiagnosticCode.WARNING_210,
                                                                      DiagnosticSeverity.WARNING);

    private final String diagnostic;
    private final String diagnosticCode;
    private final DiagnosticSeverity diagnosticSeverity;

    CompilationDiagnostic(DiagnosticMessage message, DiagnosticCode diagnosticCode,
                          DiagnosticSeverity diagnosticSeverity) {
        this.diagnostic = message.getMessage();
        this.diagnosticCode = diagnosticCode.name();
        this.diagnosticSeverity = diagnosticSeverity;
    }

    public String getDiagnostic() {
        return diagnostic;
    }

    public String getDiagnosticCode() {
        return diagnosticCode;
    }

    public DiagnosticSeverity getDiagnosticSeverity() {
        return this.diagnosticSeverity;
    }
}
