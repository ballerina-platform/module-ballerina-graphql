/*
 * Copyright (c) 2022, WSO2 LLC. (http://www.wso2.org). All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.graphql.commons.utils;

import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.SymbolKind;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.IdentifierToken;
import io.ballerina.compiler.syntax.tree.ModuleVariableDeclarationNode;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.compiler.syntax.tree.TypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.TypedBindingPatternNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

/**
 * Utility class to validate GraphQL package services and symbols.
 */
public class Utils {

    public static final String PACKAGE_NAME = "graphql";
    public static final String SUBGRAPH_SUB_MODULE_NAME = "graphql.subgraph";
    public static final String PACKAGE_ORG = "ballerina";
    public static final String SERVICE_NAME = "Service";

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

    public static boolean hasGraphqlListener(ServiceDeclarationSymbol symbol) {
        for (TypeSymbol listener : symbol.listenerTypes()) {
            if (isGraphqlListener(listener)) {
                return true;
            }
        }
        return false;
    }

    public static boolean isGraphqlListener(TypeSymbol typeSymbol) {
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

    public static boolean isGraphqlModuleSymbol(Symbol symbol) {
        return hasExpectedModuleName(symbol, PACKAGE_NAME, PACKAGE_ORG);
    }

    public static boolean isSubgraphModuleSymbol(Symbol symbol) {
        return hasExpectedModuleName(symbol, SUBGRAPH_SUB_MODULE_NAME, PACKAGE_ORG);
    }

    private static boolean hasExpectedModuleName(Symbol symbol, String expectedModuleName, String expectedOrgName) {
        if (symbol.getModule().isEmpty()) {
            return false;
        }
        String moduleName = symbol.getModule().get().id().moduleName();
        String orgName = symbol.getModule().get().id().orgName();
        return expectedModuleName.equals(moduleName) && expectedOrgName.equals(orgName);
    }

    public static boolean isGraphQLServiceObjectDeclaration(ModuleVariableDeclarationNode variableNode) {
        TypedBindingPatternNode typedBindingPatternNode = variableNode.typedBindingPattern();
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
}
