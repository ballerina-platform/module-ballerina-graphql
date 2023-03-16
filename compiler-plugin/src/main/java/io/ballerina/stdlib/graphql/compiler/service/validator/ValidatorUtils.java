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
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.compiler.diagnostics.CompilationDiagnostic;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.Location;

import java.util.List;

import static io.ballerina.stdlib.graphql.commons.types.TypeName.ANY;
import static io.ballerina.stdlib.graphql.commons.types.TypeName.FIELD_SET;
import static io.ballerina.stdlib.graphql.commons.types.TypeName.LINK_IMPORT;
import static io.ballerina.stdlib.graphql.commons.types.TypeName.LINK_PURPOSE;
import static io.ballerina.stdlib.graphql.commons.types.TypeName.SERVICE;

/**
 * Utility functions for the Ballerina GraphQL compiler validations.
 */
public final class ValidatorUtils {
    private ValidatorUtils() {
    }

    public static final String DOUBLE_UNDERSCORES = "__";
    public static final String RESOURCE_FUNCTION_GET = "get";
    public static final String RESOURCE_FUNCTION_SUBSCRIBE = "subscribe";
    public static final String GRAPHQL_INTERCEPTOR = "Interceptor";
    public static final String INTERCEPTOR_EXECUTE = "execute";

    public static void updateContext(SyntaxNodeAnalysisContext context, CompilationDiagnostic errorCode,
                                     Location location) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(errorCode.getDiagnosticCode(), errorCode.getDiagnostic(),
                                                           errorCode.getDiagnosticSeverity());
        Diagnostic diagnostic = DiagnosticFactory.createDiagnostic(diagnosticInfo, location);
        context.reportDiagnostic(diagnostic);
    }

    public static void updateContext(SyntaxNodeAnalysisContext context, CompilationDiagnostic diagnosticCode,
                                     Location location, Object... args) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(diagnosticCode.getDiagnosticCode(),
                diagnosticCode.getDiagnostic(), diagnosticCode.getDiagnosticSeverity());
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

    public static boolean isReservedFederatedResolverName(String methodName) {
        return methodName.equals(Schema.ENTITIES_RESOLVER_NAME) || methodName.equals(Schema.SERVICE_RESOLVER_NAME);
    }

    public static boolean isReservedFederatedTypeName(String typeName) {
        List<String> reservedTypes = List.of(ANY.getName(), FIELD_SET.getName(), LINK_IMPORT.getName(),
                                             LINK_PURPOSE.getName(), SERVICE.getName());
        return reservedTypes.contains(typeName);
    }
}
