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
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Represents the {@code Schema} type in GraphQL schema.
 */
public class Schema implements Serializable {
    private static final long serialVersionUID = 1L;
    private final String description;
    private final Map<String, Type> types;
    private final List<Directive> directives;
    private final List<Type> entities;
    private final boolean isSubgraph;
    private Type queryType;
    private Type mutationType = null;
    private Type subscriptionType = null;
    private static final String REPRESENTATIONS_ARGUMENT = "representations";
    private static final String SDL_FIELD = "sdl";

    public static final String SERVICE_RESOLVER_NAME = "_service";
    public static final String ENTITIES_RESOLVER_NAME = "_entities";

    /**
     * Creates the schema.
     *
     * @param description - The description of the schema
     */
    public Schema(String description, boolean isSubgraph) {
        this.description = description;
        this.types = new LinkedHashMap<>();
        this.directives = new ArrayList<>();
        this.entities = new ArrayList<>();
        this.isSubgraph = isSubgraph;
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

    public Map<String, Type> getTypes() {
        return this.types;
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

    public Type getMutationType() {
        return this.mutationType;
    }

    public void setSubscriptionType(Type type) {
        this.subscriptionType = type;
    }

    public Type getSubscriptionType() {
        return this.subscriptionType;
    }

    public void addDirective(Directive directive) {
        this.directives.add(directive);
    }

    public void addDirective(FederatedDirective directive) {
        this.directives.add(new Directive(directive));
    }

    public List<Directive> getDirectives() {
        return this.directives;
    }

    public void addEntity(Type federatedEntities) {
        if (!isSubgraph()) {
            return;
        }
        this.entities.add(federatedEntities);
    }

    public List<Type> getEntities() {
        return this.entities;
    }

    public void addSubgraphSchemaAdditions() {
        if (!isSubgraph()) {
            return;
        }
        ScalarType.getFederatedScalarTypes().forEach(this::addType);
        Arrays.stream(FederatedEnumValue.values())
                .forEach(enumType -> this.types.put(enumType.getName(), enumType.getEnumTypeWithValues()));
        Arrays.stream(FederatedDirective.values()).forEach(this::addDirective);
        this.addFederatedServiceTypeWithResolver();
        this.addFederatedEntitiesWithResolver();
    }

    private void addFederatedServiceTypeWithResolver() {
        Type service = addType(TypeName.SERVICE.getName(), TypeKind.OBJECT, null);

        Type nonNullableString = new Type(TypeKind.NON_NULL, getType(TypeName.STRING.getName()));
        service.addField(new Field(SDL_FIELD, nonNullableString));
        Field serviceField = new Field(SERVICE_RESOLVER_NAME, new Type(TypeKind.NON_NULL, service));
        Type query = getQueryType();
        query.addField(serviceField);
    }

    private void addFederatedEntitiesWithResolver() {
        if (this.entities.size() == 0) {
            return;
        }

        Type entity = addType(TypeName.ENTITY.getName(), TypeKind.UNION, null);
        getEntities().forEach(entity::addPossibleType);

        Field entities = new Field(ENTITIES_RESOLVER_NAME,
                                   new Type(TypeKind.NON_NULL, new Type(TypeKind.LIST, entity)));
        Type nonNullableAnyScalar = new Type(TypeKind.NON_NULL, getType(TypeName.ANY.getName()));
        Type nonNullableListOfAny = new Type(TypeKind.NON_NULL, new Type(TypeKind.LIST, nonNullableAnyScalar));
        entities.addArg(new InputValue(REPRESENTATIONS_ARGUMENT, nonNullableListOfAny, null, null));
        Type query = getQueryType();
        query.addField(entities);
    }

    public boolean isSubgraph() {
        return isSubgraph;
    }
}
