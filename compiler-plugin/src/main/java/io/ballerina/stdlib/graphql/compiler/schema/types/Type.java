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

package io.ballerina.stdlib.graphql.compiler.schema.types;

import io.ballerina.compiler.api.symbols.TypeSymbol;

import java.util.ArrayList;
import java.util.List;

/**
 * Represents the {@code __Type} type in GraphQL schema.
 */
public class Type {
    private final String name;
    private final TypeKind typeKind;
    private final String description;
    private final TypeSymbol typeSymbol;
    private final List<Field> fields;
    private final List<EnumValue> enumValues;
    private final List<Type> possibleTypes;
    private final List<Type> interfaces;

    public Type(String name, TypeKind typeKind, String description, TypeSymbol typeSymbol) {
        this.name = name;
        this.typeKind = typeKind;
        this.description = description;
        this.typeSymbol = typeSymbol;
        this.fields = typeKind == TypeKind.OBJECT || typeKind == TypeKind.INTERFACE ? new ArrayList<>() : null;
        this.enumValues = typeKind == TypeKind.ENUM ? new ArrayList<>() : null;
        this.possibleTypes = typeKind == TypeKind.INTERFACE || typeKind == TypeKind.UNION ? new ArrayList<>() : null;
        this.interfaces = typeKind == TypeKind.OBJECT || typeKind == TypeKind.INTERFACE ? new ArrayList<>() : null;
    }

    public void addEnumValue(EnumValue enumValue) {
        this.enumValues.add(enumValue);
    }

    public void addPossibleType(Type type) {
        if (this.possibleTypes.contains(type)) {
            return;
        }
        this.possibleTypes.add(type);
    }

    public void addInterface(Type type) {
        if (this.interfaces.contains(type)) {
            return;
        }
        this.interfaces.add(type);
    }

    public String getName() {
        return this.name;
    }

    public TypeKind getTypeKind() {
        return this.typeKind;
    }

    public String getDescription() {
        return this.description;
    }

    public TypeSymbol getTypeSymbol() {
        return this.typeSymbol;
    }

    public List<EnumValue> getEnumValues() {
        return this.enumValues;
    }

    public List<Type> getPossibleTypes() {
        return this.possibleTypes;
    }

    public List<Type> getInterfaces() {
        return this.interfaces;
    }
}
