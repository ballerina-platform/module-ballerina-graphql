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

package io.ballerina.stdlib.graphql.commons.types;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static io.ballerina.stdlib.graphql.commons.utils.Utils.removeEscapeCharacter;

/**
 * Represents the {@code __Type} type in GraphQL schema.
 */
public class Type implements Serializable {
    private static final long serialVersionUID = 1L;
    private final String name;
    private final TypeKind kind;
    private final String description;
    private final Position position;
    private final Map<String, Field> fields;
    private final List<EnumValue> enumValues;
    private final List<Type> possibleTypes;
    private final List<Type> interfaces;
    private final List<InputValue> inputFields;
    private final Type ofType;
    private final ObjectKind objectKind;

    /**
     * Used to create wrapper (NON_NULL and LIST) types.
     *
     * @param kind - TypeKind of the wrapper. can be either NON_NULL or LIST
     * @param ofType - Type to be wrapped
     */
    public Type(TypeKind kind, Type ofType) {
        this(null, kind, null, null, ofType);
    }

    /**
     * Used to create types without a description.
     *
     * @param name - Name of the type
     * @param kind - TypeKind of the type
     */
    public Type(String name, TypeKind kind) {
        this(name, kind, null);
    }

    /**
     * Used to create non-wrapper types.
     *
     * @param name - Name of the type
     * @param kind - TypeKind of the type. Cannot be NON_NULL or LIST
     * @param description - The description of the type from the documentation
     */
    public Type(String name, TypeKind kind, String description) {
        this(name, kind, description, null, (Type) null);
    }

    public Type(String name, TypeKind kind, String description, Position position) {
        this(name, kind, description, position, (Type) null);
    }

    /**
     * Used to create wrapper OBJECT type.
     *
     * @param name - Name of the type
     * @param kind - TypeKind of the type. Will be an OBJECT
     * @param description - The description of the type from the documentation
     * @param objectKind - The kind of the object. Could be ObjectKind.CLASS or ObjectKind.RECORD
     */
    public Type(String name, TypeKind kind, String description, Position position, ObjectKind objectKind) {
        this(name, kind, description, position, null, objectKind);
    }

    /**
     * Used to create type without ObjectKind.
     *
     * @param name - Name of the type
     * @param kind - TypeKind of the type. Cannot be an OBJECT
     * @param description - The description of the type from the documentation
     * @param ofType - The type to be wrapped
     */
    public Type(String name, TypeKind kind, String description, Position position, Type ofType) {
        this(name, kind, description, position, ofType, null);
    }

    private Type(String name, TypeKind kind, String description, Position position, Type ofType,
                 ObjectKind objectKind) {
        this.name = removeEscapeCharacter(name);
        this.kind = kind;
        this.description = description;
        this.position = position;
        this.fields = kind == TypeKind.OBJECT || kind == TypeKind.INTERFACE ? new LinkedHashMap<>() : null;
        this.enumValues = kind == TypeKind.ENUM ? new ArrayList<>() : null;
        this.possibleTypes = kind == TypeKind.INTERFACE || kind == TypeKind.UNION ? new ArrayList<>() : null;
        this.interfaces = kind == TypeKind.OBJECT || kind == TypeKind.INTERFACE ? new ArrayList<>() : null;
        this.inputFields = kind == TypeKind.INPUT_OBJECT ? new ArrayList<>() : null;
        this.ofType = ofType;
        this.objectKind = objectKind;
    }

    public Collection<Field> getFields() {
        return this.fields.values();
    }

    public void addField(Field field) {
        this.fields.put(field.getName(), field);
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

    public TypeKind getKind() {
        return this.kind;
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

    public List<InputValue> getInputFields() {
        return this.inputFields;
    }

    public Type getOfType() {
        return this.ofType;
    }

    public ObjectKind getObjectKind() {
        return objectKind;
    }
}
