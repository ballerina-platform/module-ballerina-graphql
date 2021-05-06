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

package io.ballerina.stdlib.graphql.runtime.schema.types;

import io.ballerina.runtime.api.types.Type;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * This class represents a Type in GraphQL schema.
 */
public class SchemaType {

    private final TypeKind kind;
    private final String name;
    private final Map<String, SchemaField> fields;
    private final List<Object> enumValues;
    private final List<SchemaType> possibleTypes;
    private SchemaType ofType;
    private final Type balType;

    public SchemaType(String name, TypeKind kind) {
        this(name, kind, null);
    }

    public SchemaType(String name, TypeKind kind, Type balType) {
        this.name = name;
        this.kind = kind;
        this.balType = balType;
        this.fields = (kind == TypeKind.OBJECT) ? new HashMap<>() : null;
        this.enumValues = kind == TypeKind.ENUM ? new ArrayList<>() : null;
        this.possibleTypes = (kind == TypeKind.UNION) ? new ArrayList<>() : null;
    }

    public String getName() {
        return this.name;
    }

    public TypeKind getKind() {
        return this.kind;
    }

    public Collection<SchemaField> getFields() {
        return this.fields.values();
    }

    public Type getBalType() {
        return this.balType;
    }

    public List<Object> getEnumValues() {
        return this.enumValues;
    }

    public SchemaType getOfType() {
        return this.ofType;
    }

    public void addField(SchemaField field) {
        this.fields.put(field.getName(), field);
    }

    public SchemaField getField(String name) {
        if (this.fields.containsKey(name)) {
            return this.fields.get(name);
        }
        return null;
    }

    public void addEnumValue(Object o) {
        this.enumValues.add(o);
    }

    public void setOfType(SchemaType ofType) {
        this.ofType = ofType;
    }

    public void addPossibleType(SchemaType schemaType) {
        this.possibleTypes.add(schemaType);
    }

    public List<SchemaType> getPossibleTypes() {
        if (this.possibleTypes.size() == 0) {
            return null;
        }
        return this.possibleTypes;
    }
}
