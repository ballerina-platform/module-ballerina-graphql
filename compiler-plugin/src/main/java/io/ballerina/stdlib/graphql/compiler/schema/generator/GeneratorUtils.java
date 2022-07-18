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

package io.ballerina.stdlib.graphql.compiler.schema.generator;

import io.ballerina.compiler.api.symbols.Documentable;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.stdlib.graphql.compiler.schema.types.ScalarType;
import io.ballerina.stdlib.graphql.compiler.schema.types.Type;
import io.ballerina.stdlib.graphql.compiler.schema.types.TypeKind;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Utility methods for Ballerina GraphQL schema generator.
 */
public class GeneratorUtils {
    private GeneratorUtils() {
    }

    private static final String UNICODE_REGEX = "\\\\(\\\\*)u\\{([a-fA-F0-9]+)\\}";
    public static final Pattern UNICODE_PATTERN = Pattern.compile(UNICODE_REGEX);

    public static final String UNION_TYPE_NAME_DELIMITER = "_";

    public static final String MAP_KEY_ARGUMENT_NAME = "key";
    public static final String MAP_KEY_ARGUMENT_DESCRIPTION =
            "[auto-generated]: The key of the value required from a map";
    public static final String SCHEMA_STRING_FIELD = "schemaString";

    public static String getTypeName(TypeSymbol typeSymbol) {
        switch (typeSymbol.typeKind()) {
            case STRING:
            case STRING_CHAR:
                return ScalarType.STRING.getName();
            case INT:
                return ScalarType.INT.getName();
            case FLOAT:
                return ScalarType.FLOAT.getName();
            case BOOLEAN:
                return ScalarType.BOOLEAN.getName();
            case DECIMAL:
                return ScalarType.DECIMAL.getName();
            default:
                if (typeSymbol.getName().isEmpty()) {
                    return null;
                }
                return typeSymbol.getName().get();
        }
    }

    public static String getTypeName(List<TypeSymbol> memberTypes) {
        List<String> typeNames = new ArrayList<>();
        for (TypeSymbol typeSymbol : memberTypes) {
            if (typeSymbol.getName().isEmpty()) {
                continue;
            }
            typeNames.add(typeSymbol.getName().get());
        }
        return String.join(UNION_TYPE_NAME_DELIMITER, typeNames);
    }

    public static String getDescription(Documentable documentable) {
        if (documentable.documentation().isEmpty()) {
            return null;
        }
        if (documentable.documentation().get().description().isEmpty()) {
            return null;
        }
        return documentable.documentation().get().description().get();
    }

    public static String getDeprecationReason(Documentable documentable) {
        if (documentable.documentation().isEmpty()) {
            return null;
        }
        if (documentable.documentation().get().deprecatedDescription().isEmpty()) {
            return null;
        }
        return documentable.documentation().get().deprecatedDescription().get();
    }

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

        if (value.startsWith("'")) {
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

    public static Type getWrapperType(Type type, TypeKind typeKind) {
        return new Type(typeKind, type);
    }
}
