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

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.Qualifier;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.diagnostics.Location;

import java.util.Optional;

/**
 * Util class for the compiler plugin.
 */
public class Utils {

    private Utils() {
    }

    // compiler plugin constants
    public static final String PACKAGE_PREFIX = "graphql";
    public static final String PACKAGE_ORG = "ballerina";

    // resource function constants
    public static final String RESOURCE_FUNCTION_GET = "get";
    public static final String LISTENER_IDENTIFIER = "Listener";
    public static final String DOUBLE_UNDERSCORES = "__";

    /**
     * Compilation errors.
     */
    enum CompilationError {
        INVALID_FUNCTION("Remote methods are not allowed inside the service classes returned from GraphQL resources",
                         "GRAPHQL_101", DiagnosticSeverity.ERROR),
        INVALID_RETURN_TYPE("Invalid return type for GraphQL resource/remote function", "GRAPHQL_102",
                            DiagnosticSeverity.ERROR),
        INVALID_RESOURCE_INPUT_PARAM("Invalid input parameter type for GraphQL resource/remote function", "GRAPHQL_103",
                                     DiagnosticSeverity.ERROR),
        INVALID_RETURN_TYPE_NIL("A GraphQL resource/remote function must have a return type", "GRAPHQL_104",
                                DiagnosticSeverity.ERROR),
        INVALID_RETURN_TYPE_ERROR_OR_NIL("A GraphQL resource/remote function must have a return data type",
                                         "GRAPHQL_105", DiagnosticSeverity.ERROR),
        INVALID_RESOURCE_FUNCTION_ACCESSOR(
                "Only \"" + RESOURCE_FUNCTION_GET + "\" accessor is allowed for GraphQL resource function",
                "GRAPHQL_106", DiagnosticSeverity.ERROR),
        INVALID_MULTIPLE_LISTENERS("A GraphQL service cannot be attached to multiple listeners", "GRAPHQL_107",
                                   DiagnosticSeverity.ERROR),
        INVALID_RETURN_TYPE_ERROR("A GraphQL resource/remote function must have a return data type", "GRAPHQL_108",
                                  DiagnosticSeverity.ERROR),
        INVALID_LISTENER_INIT("http:Listener and graphql:ListenerConfiguration are mutually exclusive", "GRAPHQL_109",
                              DiagnosticSeverity.ERROR),
        INVALID_RETURN_TYPE_MULTIPLE_SERVICES("GraphQL union type cannot consist non-distinct services", "GRAPHQL_110",
                                              DiagnosticSeverity.ERROR),
        INVALID_FIELD_NAME("A GraphQL field name must not begin with \"" + DOUBLE_UNDERSCORES + 
                                   "\", which is reserved by GraphQL introspection", "GRAPHQL_111",
                           DiagnosticSeverity.ERROR),
        INVALID_RETURN_TYPE_ANY(
                "A GraphQL resource/remote function cannot return \"any\" or \"anydata\", instead use specific type " +
                        "names", "GRAPHQL_112", DiagnosticSeverity.ERROR),
        MISSING_RESOURCE_FUNCTIONS("A GraphQL service must have at least one resource function", "GRAPHQL_113",
                                   DiagnosticSeverity.ERROR),
        INVALID_RETURN_TYPE_INPUT_OBJECT(
                "A GraphQL resource/remote function cannot return \"InputObject\", instead use specific type " +
                        "names", "GRAPHQL_113", DiagnosticSeverity.ERROR),
        INVALID_RESOURCE_INPUT_PARAM_INPUT_OBJECT(
                "A GraphQL resource/remote function \"return type\" cannot use as the \"input object\" parameter",
                "GRAPHQL_114", DiagnosticSeverity.ERROR);

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

    public static boolean validateModuleId(ModuleSymbol moduleSymbol) {
        String moduleName = moduleSymbol.id().moduleName();
        String orgName = moduleSymbol.id().orgName();
        return moduleName.equals(PACKAGE_PREFIX) && orgName.equals(PACKAGE_ORG);
    }

    public static MethodSymbol getMethodSymbol(SyntaxNodeAnalysisContext context,
                                               FunctionDefinitionNode functionDefinitionNode) {
        MethodSymbol methodSymbol = null;
        SemanticModel semanticModel = context.semanticModel();
        Optional<Symbol> symbol = semanticModel.symbol(functionDefinitionNode);
        if (symbol.isPresent()) {
            methodSymbol = (MethodSymbol) symbol.get();
        }
        return methodSymbol;
    }

    public static boolean isRemoteFunction(SyntaxNodeAnalysisContext context,
                                           FunctionDefinitionNode functionDefinitionNode) {
        MethodSymbol methodSymbol = getMethodSymbol(context, functionDefinitionNode);
        return methodSymbol.qualifiers().contains(Qualifier.REMOTE);
    }

    public static void updateContext(SyntaxNodeAnalysisContext context, CompilationError errorCode,
                                     Location location) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(
                errorCode.getErrorCode(), errorCode.getError(), errorCode.getDiagnosticSeverity());
        Diagnostic diagnostic = DiagnosticFactory.createDiagnostic(diagnosticInfo, location);
        context.reportDiagnostic(diagnostic);
    }

    public static boolean isGraphqlListener(TypeSymbol listenerType) {
        if (listenerType.typeKind() == TypeDescKind.UNION) {
            return ((UnionTypeSymbol) listenerType).memberTypeDescriptors().stream()
                    .filter(typeDescriptor -> typeDescriptor instanceof TypeReferenceTypeSymbol)
                    .map(typeReferenceTypeSymbol -> (TypeReferenceTypeSymbol) typeReferenceTypeSymbol)
                    .anyMatch(typeReferenceTypeSymbol ->
                                      typeReferenceTypeSymbol.getModule().isPresent()
                                              && validateModuleId(typeReferenceTypeSymbol.getModule().get()
                                      ));
        }

        if (listenerType.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            Optional<ModuleSymbol> moduleOpt = ((TypeReferenceTypeSymbol) listenerType).typeDescriptor().getModule();
            return moduleOpt.isPresent() && validateModuleId(moduleOpt.get());
        }

        if (listenerType.typeKind() == TypeDescKind.OBJECT) {
            Optional<ModuleSymbol> moduleOpt = listenerType.getModule();
            return moduleOpt.isPresent() && validateModuleId(moduleOpt.get());
        }
        return false;
    }

    public static boolean isInvalidFieldName(String fieldName) {
        return fieldName.startsWith(DOUBLE_UNDERSCORES) || fieldName.contains("/" + DOUBLE_UNDERSCORES);
    }

    static Location getLocation(Symbol typeSymbol, Location alternateLocation) {
        if (typeSymbol.getLocation().isPresent()) {
            return typeSymbol.getLocation().get();
        }
        return alternateLocation;
    }
}
