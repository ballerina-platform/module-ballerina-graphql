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

package io.ballerina.stdlib.graphql.schema;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * This class represents a Type in GraphQL schema.
 */
public class SchemaType {

    private TypeKind kind;
    private String name;
    private Set<SchemaField> fields;
    private List<Object> enumValues;
    SchemaType ofType;

    public SchemaType(String name, TypeKind kind) {
        this.name = name;
        this.kind = kind;
        this.fields = new HashSet<>();
        this.enumValues = new ArrayList<>();
    }

    public String getName() {
        return this.name;
    }

    public TypeKind getKind() {
        return this.kind;
    }

    public Set<SchemaField> getFields() {
        return this.fields;
    }

    public List<Object> getEnumValues() {
        return this.enumValues;
    }

    public SchemaType getOfType() {
        return this.ofType;
    }

    public void addField(SchemaField field) {
        this.fields.add(field);
    }

    public void addEnumValue(Object o) {
        this.enumValues.add(o);
    }

    public void setOfType(SchemaType ofType) {
        this.ofType = ofType;
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof SchemaType)) {
            return false;
        }
        if (this.kind != ((SchemaType) obj).kind) {
            return false;
        }
        return this.name.equals(((SchemaType) obj).name);
    }

    @Override
    public int hashCode() {
        return (this.name + this.kind).hashCode();
    }
}
