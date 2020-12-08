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
import java.util.List;

/**
 * This class represents a Type in GraphQL schema.
 */
public class SchemaType {

    private TypeKind kind;
    private String name;
    private List<SchemaField> fields;

    public SchemaType(String name) {
        this.name = name;
        this.fields = new ArrayList<>();
    }

    public SchemaType(String name, TypeKind kind) {
        this.name = name;
        this.kind = kind;
        this.fields = new ArrayList<>();
    }

    public String getName() {
        return this.name;
    }

    public TypeKind getKind() {
        return this.kind;
    }

    public List<SchemaField> getFields() {
        return this.fields;
    }

    public void addField(SchemaField field) {
        this.fields.add(field);
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
