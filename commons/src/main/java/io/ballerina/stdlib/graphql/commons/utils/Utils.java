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

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Utility class for Ballerina GraphQL schema types.
 */
public class Utils {

    public static final String PACKAGE_NAME = "graphql";
    public static final String PACKAGE_ORG = "ballerina";
    public static final String SERVICE_NAME = "Service";

    private static final String UNICODE_REGEX = "\\\\(\\\\*)u\\{([a-fA-F0-9]+)\\}";
    private static final Pattern UNICODE_PATTERN = Pattern.compile(UNICODE_REGEX);

    private static final String SINGLE_QUOTE_CHARACTER = "'";

    public static String removeEscapeCharacter(String identifier) {
        if (identifier == null) {
            return null;
        }

        Matcher matcher = UNICODE_PATTERN.matcher(identifier);
        StringBuffer buffer = new StringBuffer(identifier.length());
        while (matcher.find()) {
            String leadingSlashes = matcher.group(1);
            if (isEscapedNumericEscape(leadingSlashes)) {
                // e.g. \\u{61}, \\\\u{61}
                continue;
            }

            int codePoint = Integer.parseInt(matcher.group(2), 16);
            char[] chars = Character.toChars(codePoint);
            String ch = String.valueOf(chars);

            if (ch.equals("\\")) {
                // Ballerina string unescaping is done in two stages.
                // 1. unicode code point unescaping (doing separately as [2] does not support code points > 0xFFFF)
                // 2. java unescaping
                // Replacing unicode code point of backslash at [1] would compromise [2]. Therefore, special case it.
                matcher.appendReplacement(buffer, Matcher.quoteReplacement(leadingSlashes + "\\u005C"));
            } else {
                matcher.appendReplacement(buffer, Matcher.quoteReplacement(leadingSlashes + ch));
            }
        }
        matcher.appendTail(buffer);
        String value = String.valueOf(buffer);

        if (value.startsWith(SINGLE_QUOTE_CHARACTER)) {
            return value.substring(1);
        }
        return value;
    }

    private static boolean isEscapedNumericEscape(String leadingSlashes) {
        return !isEven(leadingSlashes.length());
    }

    private static boolean isEven(int n) {
        // (n & 1) is 0 when n is even.
        return (n & 1) == 0;
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

    public static boolean isGraphqlModuleSymbol(Symbol symbol) {
        if (symbol.getModule().isEmpty()) {
            return false;
        }
        String moduleName = symbol.getModule().get().id().moduleName();
        String orgName = symbol.getModule().get().id().orgName();
        return PACKAGE_NAME.equals(moduleName) && PACKAGE_ORG.equals(orgName);
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
