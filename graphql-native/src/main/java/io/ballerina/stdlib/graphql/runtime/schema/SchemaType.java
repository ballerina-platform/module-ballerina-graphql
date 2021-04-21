/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.graphql.runtime.schema;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * This class represents a Type in GraphQL schema.
 */
public class SchemaType {

    private TypeKind kind;
    private String name;
    private Map<String, SchemaField> fields;
    private List<Object> enumValues;
    private List<SchemaType> possibleTypes;
    SchemaType ofType;

    public SchemaType(String name, TypeKind kind) {
        this.name = name;
        this.kind = kind;
        this.fields = new HashMap<>();
        this.enumValues = new ArrayList<>();
        this.possibleTypes = new ArrayList<>();
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

    public SchemaField getField(String name) {
        return this.fields.get(name);
    }

    public boolean hasField(String name) {
        return this.fields.containsKey(name);
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
