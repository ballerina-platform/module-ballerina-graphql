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

package io.ballerina.stdlib.graphql.compiler.service.validator;

import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.service.errors.CompilationError;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.Location;

/**
 * Utility functions for the Ballerina GraphQL compiler validations.
 */
public final class ValidatorUtils {
    private ValidatorUtils() {
    }

    public static final String DOUBLE_UNDERSCORES = "__";
    public static final String RESOURCE_FUNCTION_GET = "get";
    public static final String RESOURCE_FUNCTION_SUBSCRIBE = "subscribe";
    public static final String GRAPHQL_INTERCEPTOR = "graphql:Interceptor";
    public static final String INTERCEPTOR_FUNCTION_EXECUTE = "execute";

    public static void updateContext(SyntaxNodeAnalysisContext context, CompilationError errorCode,
                                     Location location) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(
                errorCode.getErrorCode(), errorCode.getError(), errorCode.getDiagnosticSeverity());
        Diagnostic diagnostic = DiagnosticFactory.createDiagnostic(diagnosticInfo, location);
        context.reportDiagnostic(diagnostic);
    }

    public static void updateContext(SyntaxNodeAnalysisContext context, CompilationError errorCode,
                                     Location location, Object... args) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(
                errorCode.getErrorCode(), errorCode.getError(), errorCode.getDiagnosticSeverity());
        Diagnostic diagnostic = DiagnosticFactory.createDiagnostic(diagnosticInfo, location, args);
        context.reportDiagnostic(diagnostic);
    }

    static Location getLocation(Symbol typeSymbol, Location alternateLocation) {
        if (typeSymbol.getLocation().isPresent()) {
            return typeSymbol.getLocation().get();
        }
        return alternateLocation;
    }

    public static boolean isInvalidFieldName(String fieldName) {
        return fieldName.startsWith(DOUBLE_UNDERSCORES);
    }
}
