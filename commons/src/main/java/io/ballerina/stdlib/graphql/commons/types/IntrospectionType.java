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

/**
 * Stores the default introspection types in a GraphQL schema.
 */
public enum IntrospectionType {
    SCHEMA(TypeKind.OBJECT, TypeName.SCHEMA.getName(), Description.SCHEMA.getDescription()),
    TYPE(TypeKind.OBJECT, TypeName.TYPE.getName(), Description.TYPE.getDescription()),
    FIELD(TypeKind.OBJECT, TypeName.FIELD.getName(), Description.FIELD.getDescription()),
    INPUT_VALUE(TypeKind.OBJECT, TypeName.INPUT_VALUE.getName(), Description.INPUT_VALUE.getDescription()),
    ENUM_VALUE(TypeKind.OBJECT, TypeName.ENUM_VALUE.getName(), Description.ENUM_VALUE.getDescription()),
    TYPE_KIND(TypeKind.ENUM, TypeName.TYPE_KIND.getName(), Description.TYPE_KIND.getDescription()),
    DIRECTIVE(TypeKind.OBJECT, TypeName.DIRECTIVE.getName(), Description.DIRECTIVE.getDescription()),
    DIRECTIVE_LOCATION(TypeKind.ENUM, TypeName.DIRECTIVE_LOCATION.getName(),
                       Description.DIRECTIVE_LOCATION.getDescription());

    private final TypeKind typeKind;
    private final String name;
    private final String description;

    IntrospectionType(TypeKind typeKind, String name, String description) {
        this.typeKind = typeKind;
        this.name = name;
        this.description = description;
    }

    public TypeKind getTypeKind() {
        return this.typeKind;
    }

    public String getName() {
        return this.name;
    }

    public String getDescription() {
        return this.description;
    }
}
