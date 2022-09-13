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
import io.ballerina.compiler.api.symbols.ObjectTypeSymbol;
import io.ballerina.compiler.api.symbols.Qualifier;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.SymbolKind;
import io.ballerina.compiler.api.symbols.TypeDefinitionSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.IdentifierToken;
import io.ballerina.compiler.syntax.tree.ModuleVariableDeclarationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.compiler.syntax.tree.TypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.TypedBindingPatternNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.util.ArrayList;
import java.util.List;

/**
 * Util class for the compiler plugin.
 */
public final class Utils {

    // compiler plugin constants
    public static final String PACKAGE_NAME = "graphql";
    public static final String PACKAGE_ORG = "ballerina";
    public static final String SERVICE_NAME = "Service";

    // resource function constants
    public static final String LISTENER_IDENTIFIER = "Listener";
    public static final String CONTEXT_IDENTIFIER = "Context";
    public static final String FILE_UPLOAD_IDENTIFIER = "Upload";
    public static final String SERVICE_CONFIG_IDENTIFIER = "ServiceConfig";

    private Utils() {
    }

    public static boolean isGraphqlModuleSymbol(Symbol symbol) {
        if (symbol.getModule().isEmpty()) {
            return false;
        }
        String moduleName = symbol.getModule().get().id().moduleName();
        String orgName = symbol.getModule().get().id().orgName();
        return PACKAGE_NAME.equals(moduleName) && PACKAGE_ORG.equals(orgName);
    }

    public static boolean isRemoteMethod(MethodSymbol methodSymbol) {
        return methodSymbol.qualifiers().contains(Qualifier.REMOTE);
    }

    public static boolean isResourceMethod(MethodSymbol methodSymbol) {
        return methodSymbol.qualifiers().contains(Qualifier.RESOURCE);
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
        for (TypeSymbol typeSymbol : unionTypeSymbol.userSpecifiedMemberTypes()) {
            if (typeSymbol.typeKind() == TypeDescKind.UNION) {
                effectiveTypes.addAll(getEffectiveTypes((UnionTypeSymbol) typeSymbol));
            } else if (!isIgnoreType(typeSymbol)) {
                effectiveTypes.add(typeSymbol);
            }
        }
        return effectiveTypes;
    }

    public static TypeSymbol getEffectiveType(IntersectionTypeSymbol intersectionTypeSymbol) {
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
        return intersectionTypeSymbol;
    }

    public static ObjectTypeSymbol getObjectTypeSymbol(Symbol serviceObjectTypeOrClass) {
        if (serviceObjectTypeOrClass.kind() == SymbolKind.TYPE_DEFINITION) {
            TypeDefinitionSymbol serviceObjectTypeSymbol = (TypeDefinitionSymbol) serviceObjectTypeOrClass;
            TypeSymbol typeSymbol = serviceObjectTypeSymbol.typeDescriptor();
            if (typeSymbol.typeKind() == TypeDescKind.OBJECT) {
                return (ObjectTypeSymbol) typeSymbol;
            }
        } else if (serviceObjectTypeOrClass.kind() == SymbolKind.CLASS) {
            return (ObjectTypeSymbol) serviceObjectTypeOrClass;
        }
        String symbolName = "Provided symbol";
        if (serviceObjectTypeOrClass.getName().isPresent()) {
            symbolName = serviceObjectTypeOrClass.getName().get();
        }
        throw new UnsupportedOperationException(
                symbolName + " is not ClassSymbol or TypeDefinitionSymbol of an object");
    }

    public static boolean isDistinctServiceReference(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() != TypeDescKind.TYPE_REFERENCE) {
            return false;
        }
        Symbol typeDescriptor = ((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor();
        return isDistinctServiceClass(typeDescriptor);
    }

    public static boolean isDistinctServiceClass(Symbol symbol) {
        if (!isServiceClass(symbol)) {
            return false;
        }
        return ((ClassSymbol) symbol).qualifiers().contains(Qualifier.DISTINCT);
    }

    public static boolean isServiceClass(Symbol symbol) {
        if (symbol.kind() != SymbolKind.CLASS) {
            return false;
        }
        return ((ClassSymbol) symbol).qualifiers().contains(Qualifier.SERVICE);
    }

    public static boolean isServiceObjectDefinition(Symbol symbol) {
        if (symbol.kind() != SymbolKind.TYPE_DEFINITION) {
            return false;
        }
        TypeSymbol typeDescriptor = ((TypeDefinitionSymbol) symbol).typeDescriptor();
        return isServiceObjectType(typeDescriptor);
    }

    public static boolean isServiceObjectReference(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() != TypeDescKind.TYPE_REFERENCE) {
            return false;
        }
        TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor();
        return isServiceObjectType(typeDescriptor);
    }

    private static boolean isServiceObjectType(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() != TypeDescKind.OBJECT || typeSymbol.kind() != SymbolKind.TYPE) {
            return false;
        }
        return ((ObjectTypeSymbol) typeSymbol).qualifiers().contains(Qualifier.SERVICE);
    }

    public static boolean isGraphqlService(SyntaxNodeAnalysisContext context) {
        ServiceDeclarationNode node = (ServiceDeclarationNode) context.node();
        if (context.semanticModel().symbol(node).isEmpty()) {
            return false;
        }
        if (context.semanticModel().symbol(node).get().kind() != SymbolKind.SERVICE_DECLARATION) {
            return false;
        }
        ServiceDeclarationSymbol symbol = (ServiceDeclarationSymbol) context.semanticModel().symbol(node).get();
        return hasGraphqlListener(symbol);
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

    public static boolean hasCompilationErrors(SyntaxNodeAnalysisContext context) {
        for (Diagnostic diagnostic : context.semanticModel().diagnostics()) {
            if (diagnostic.diagnosticInfo().severity() == DiagnosticSeverity.ERROR) {
                return true;
            }
        }
        return false;
    }

    public static boolean isFileUploadParameter(TypeSymbol typeSymbol) {
        if (typeSymbol.getName().isEmpty()) {
            return false;
        }
        if (!isGraphqlModuleSymbol(typeSymbol)) {
            return false;
        }
        return FILE_UPLOAD_IDENTIFIER.equals(typeSymbol.getName().get());
    }

    public static boolean isContextParameter(TypeSymbol typeSymbol) {
        if (typeSymbol.getName().isEmpty()) {
            return false;
        }
        if (!isGraphqlModuleSymbol(typeSymbol)) {
            return false;
        }
        return CONTEXT_IDENTIFIER.equals(typeSymbol.getName().get());
    }

    public static String getAccessor(ResourceMethodSymbol resourceMethodSymbol) {
        return resourceMethodSymbol.getName().orElse(null);
    }

    public static boolean isGraphQLServiceObjectDeclaration(
            ModuleVariableDeclarationNode moduleVariableDeclarationNode) {
        TypedBindingPatternNode typedBindingPatternNode = moduleVariableDeclarationNode.typedBindingPattern();
        TypeDescriptorNode typeDescriptorNode = typedBindingPatternNode.typeDescriptor();
        if (typeDescriptorNode.kind() != SyntaxKind.QUALIFIED_NAME_REFERENCE) {
            return false;
        }
        return isGraphqlServiceQualifiedNameReference((QualifiedNameReferenceNode) typeDescriptorNode);
    }

    private static boolean isGraphqlServiceQualifiedNameReference(QualifiedNameReferenceNode nameReferenceNode) {
        Token modulePrefixToken = nameReferenceNode.modulePrefix();
        if (modulePrefixToken.kind() != SyntaxKind.IDENTIFIER_TOKEN) {
            return false;
        }
        if (!PACKAGE_NAME.equals(modulePrefixToken.text())) {
            return false;
        }
        IdentifierToken identifier = nameReferenceNode.identifier();
        return SERVICE_NAME.equals(identifier.text());
    }

    public static boolean isFunctionDefinition(Node node) {
        return node.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION
                || node.kind() == SyntaxKind.OBJECT_METHOD_DEFINITION;
    }
}
