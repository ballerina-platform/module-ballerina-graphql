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

import java.util.ArrayList;
import java.util.List;

/**
 * Utility methods for Ballerina GraphQL schema generator.
 */
public class GeneratorUtils {
    private GeneratorUtils() {}

    public static final String UNION_TYPE_NAME_DELIMITER = "_";
    public static final String QUERY_TYPE_NAME = "Query";
    public static final String MUTATION_TYPE_NAME = "Mutation";
    public static final String SUBSCRIPTION_TYPE_NAME = "Subscription";

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
}
