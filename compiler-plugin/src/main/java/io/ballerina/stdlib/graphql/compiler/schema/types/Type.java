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

import java.util.ArrayList;
import java.util.List;

/**
 * Represents the {@code __Type} type in GraphQL schema.
 */
public class Type {
    private final String name;
    private final TypeKind typeKind;
    private final String description;
    private final List<Field> fields;
    private final List<EnumValue> enumValues;
    private final List<Type> possibleTypes;
    private final List<Type> interfaces;
    private final List<InputValue> inputFields;
    private final Type ofType;

    /**
     * Used to create wrapper (NON_NULL and LIST) types.
     *
     * @param typeKind - TypeKind of the wrapper. can be either NON_NULL or LIST
     * @param ofType - Type to be wrapped
     */
    public Type(TypeKind typeKind, Type ofType) {
        this(null, typeKind, null, ofType);
    }

    /**
     * Used to create types without a description.
     *
     * @param name - Name of the type
     * @param typeKind - TypeKind of the type
     */
    public Type(String name, TypeKind typeKind) {
        this(name, typeKind, null);
    }

    /**
     * Used to create non-wrapper types.
     *
     * @param name - Name of the type
     * @param typeKind - TypeKind of the type. Cannot be NON_NULL or LIST
     * @param description - The description of the type from the documentation
     */
    public Type(String name, TypeKind typeKind, String description) {
        this(name, typeKind, description, null);
    }

    private Type(String name, TypeKind typeKind, String description, Type ofType) {
        this.name = name;
        this.typeKind = typeKind;
        this.description = description;
        this.fields = typeKind == TypeKind.OBJECT || typeKind == TypeKind.INTERFACE ? new ArrayList<>() : null;
        this.enumValues = typeKind == TypeKind.ENUM ? new ArrayList<>() : null;
        this.possibleTypes = typeKind == TypeKind.INTERFACE || typeKind == TypeKind.UNION ? new ArrayList<>() : null;
        this.interfaces = typeKind == TypeKind.OBJECT || typeKind == TypeKind.INTERFACE ? new ArrayList<>() : null;
        this.inputFields = typeKind == TypeKind.INPUT_OBJECT ? new ArrayList<>() : null;
        this.ofType = ofType;
    }

    public List<Field> getFields() {
        return this.fields;
    }

    public void addField(Field field) {
        this.fields.add(field);
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

    public void addInputField(InputValue inputValue) {
        this.inputFields.add(inputValue);
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
