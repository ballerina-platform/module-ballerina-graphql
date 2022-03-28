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

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Represents the {@code Schema} type in GraphQL schema.
 */
public class Schema {
    private final String description;
    private final Map<String, Type> types;
    private Type queryType;
    private Type mutationType;
    private List<Directive> directives;

    /**
     * Creates the schema.
     *
     * @param description - The description of the schema
     */
    public Schema(String description) {
        this.description = description;
        this.types = new LinkedHashMap<>();
    }

    /**
     * Adds a type to the schema and returns it. If the type name already exists, returns the existing type. If the
     * type name does not exist in the schema, creates the type and returns it.
     *
     * @param typeName - The name of the type
     * @param kind - The TypeKind of the type
     * @param description - The description of the type
     *
     * @return - The created or existing type with the provided name
     */
    public Type addType(String typeName, TypeKind kind, String description) {
        if (this.types.containsKey(typeName)) {
            return this.types.get(typeName);
        }
        Type type = new Type(typeName, kind, description);
        this.types.put(typeName, type);
        return type;
    }

    /**
     * Adds a Scalar type to the schema from a given ScalarType and returns it. If the scalar type already exist,
     * returns the existing scalar type.
     *
     * @param scalarType - The ScalarType to be added
     *
     * @return - The created or existing scalar type
     */
    public Type addType(ScalarType scalarType) {
        if (this.types.containsKey(scalarType.getName())) {
            return this.types.get(scalarType.getName());
        }
        Type type = new Type(scalarType.getName(), TypeKind.SCALAR, scalarType.getDescription());
        this.types.put(scalarType.getName(), type);
        return type;
    }

    public boolean containsType(String name) {
        return this.types.containsKey(name);
    }

    public Type getType(String name) {
        return this.types.get(name);
    }

    public String getDescription() {
        return this.description;
    }

    public Type getQueryType() {
        return this.queryType;
    }

    public void setQueryType(Type type) {
        this.queryType = type;
    }

    public void setMutationType(Type type) {
        this.mutationType = type;
    }

    public void addDirective(Directive directive) {
        this.directives.add(directive);
    }
}
