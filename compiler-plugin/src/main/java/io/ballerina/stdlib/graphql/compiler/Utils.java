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

import io.ballerina.compiler.api.symbols.ClassSymbol;
import io.ballerina.compiler.api.symbols.IntersectionTypeSymbol;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.Qualifier;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.SymbolKind;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.validator.errors.CompilationError;
import io.ballerina.tools.diagnostics.Location;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static io.ballerina.stdlib.graphql.compiler.validator.ValidatorUtils.updateContext;

/**
 * Util class for the compiler plugin.
 */
public final class Utils {

    private Utils() {
    }

    // compiler plugin constants
    public static final String PACKAGE_NAME = "graphql";
    public static final String PACKAGE_ORG = "ballerina";

    // resource function constants
    public static final String LISTENER_IDENTIFIER = "Listener";
    public static final String CONTEXT_IDENTIFIER = "Context";
    public static final String FILE_UPLOAD_IDENTIFIER = "Upload";

    public static boolean isGraphqlModuleSymbol(TypeSymbol typeSymbol) {
        if (typeSymbol.getModule().isEmpty()) {
            return false;
        }
        String moduleName = typeSymbol.getModule().get().id().moduleName();
        String orgName = typeSymbol.getModule().get().id().orgName();
        return PACKAGE_NAME.equals(moduleName) && PACKAGE_ORG.equals(orgName);
    }

    public static boolean isRemoteFunction(MethodSymbol methodSymbol) {
        return methodSymbol.qualifiers().contains(Qualifier.REMOTE);
    }

    public static boolean isGraphqlListener(Symbol listenerSymbol) {
        if (listenerSymbol.kind() != SymbolKind.TYPE) {
            return false;
        }
        TypeSymbol typeSymbol = ((TypeReferenceTypeSymbol) listenerSymbol).typeDescriptor();
        if (typeSymbol.typeKind() != TypeDescKind.OBJECT) {
            return false;
        }
        if (!isGraphqlModuleSymbol(typeSymbol)) {
            return false;
        }
        if (typeSymbol.getName().isEmpty()) {
            return false;
        }
        return LISTENER_IDENTIFIER.equals(typeSymbol.getName().get());
    }

    public static boolean isIgnoreType(TypeSymbol typeSymbol) {
        return typeSymbol.typeKind() == TypeDescKind.NIL || typeSymbol.typeKind() == TypeDescKind.ERROR;
    }

    public static List<TypeSymbol> getEffectiveTypes(UnionTypeSymbol unionTypeSymbol) {
        List<TypeSymbol> effectiveTypes = new ArrayList<>();
        for (TypeSymbol typeSymbol : unionTypeSymbol.memberTypeDescriptors()) {
            if (!isIgnoreType(typeSymbol)) {
                effectiveTypes.add(typeSymbol);
            }
        }
        return effectiveTypes;
    }

    public static TypeSymbol getEffectiveType(IntersectionTypeSymbol intersectionTypeSymbol, Location location) {
        List<TypeSymbol> effectiveTypes = new ArrayList<>();
        for (TypeSymbol typeSymbol : intersectionTypeSymbol.memberTypeDescriptors()) {
            if (typeSymbol.typeKind() == TypeDescKind.READONLY) {
                continue;
            }
            effectiveTypes.add(typeSymbol);
        }
        if (effectiveTypes.size() == 1) {
            return effectiveTypes.get(0);
        }
        return null;
    }

    public static boolean isPrimitiveType(TypeSymbol returnType) {
        return returnType.typeKind().isStringType() ||
                returnType.typeKind() == TypeDescKind.INT ||
                returnType.typeKind() == TypeDescKind.FLOAT ||
                returnType.typeKind() == TypeDescKind.BOOLEAN ||
                returnType.typeKind() == TypeDescKind.DECIMAL;
    }

    public static boolean isDistinctServiceReference(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() != TypeDescKind.TYPE_REFERENCE) {
            return false;
        }
        TypeReferenceTypeSymbol typeReferenceTypeSymbol = (TypeReferenceTypeSymbol) typeSymbol;
        Symbol typeDescriptor = typeReferenceTypeSymbol.typeDescriptor();
        if (typeDescriptor.kind() != SymbolKind.CLASS) {
            return false;
        }
        ClassSymbol classSymbol = (ClassSymbol) typeDescriptor;
        return classSymbol.qualifiers().containsAll(Arrays.asList(Qualifier.SERVICE, Qualifier.DISTINCT));
    }

    public static boolean isGraphQlService(SyntaxNodeAnalysisContext context) {
        ServiceDeclarationNode node = (ServiceDeclarationNode) context.node();
        if (context.semanticModel().symbol(node).isEmpty()) {
            return false;
        }
        if (context.semanticModel().symbol(node).get().kind() != SymbolKind.SERVICE_DECLARATION) {
            return false;
        }
        ServiceDeclarationSymbol symbol = (ServiceDeclarationSymbol) context.semanticModel().symbol(node).get();
        if (!hasGraphqlListener(symbol)) {
            return false;
        }
        if (symbol.listenerTypes().size() > 1) {
            updateContext(context, CompilationError.INVALID_MULTIPLE_LISTENERS, node.location());
            return false;
        }
        return true;
    }

    private static boolean hasGraphqlListener(ServiceDeclarationSymbol symbol) {
        for (TypeSymbol listener : symbol.listenerTypes()) {
            if (isGraphqlListener(listener)) {
                return true;
            }
        }
        return false;
    }

    private static boolean isGraphqlListener(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() == TypeDescKind.UNION) {
            UnionTypeSymbol unionTypeSymbol = (UnionTypeSymbol) typeSymbol;
            for (TypeSymbol member : unionTypeSymbol.memberTypeDescriptors()) {
                if (isGraphqlModuleSymbol(member)) {
                    return true;
                }
            }
        } else {
            return isGraphqlModuleSymbol(typeSymbol);
        }
        return false;
    }
}
