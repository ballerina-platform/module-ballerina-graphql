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

/**
 * Represents the {@code __DirectiveLocation} enum in GraphQL schema.
 */
public enum DirectiveLocation {
    QUERY("Location adjacent to a query operation."),
    MUTATION("Location adjacent to a mutation operation."),
    SUBSCRIPTION("Location adjacent to a subscription operation."),
    FIELD("Location adjacent to a field."),
    FRAGMENT_DEFINITION("Location adjacent to a fragment definition."),
    FRAGMENT_SPREAD("Location adjacent to a fragment spread."),
    INLINE_FRAGMENT("Location adjacent to an inline fragment."),
    VARIABLE_DEFINITION("Location adjacent to a variable definition."),
    SCHEMA("Location adjacent to a schema definition."),
    SCALAR("Location adjacent to a scalar definition."),
    OBJECT("Location adjacent to an object type definition."),
    FIELD_DEFINITION("Location adjacent to a field definition."),
    ARGUMENT_DEFINITION("Location adjacent to an argument definition."),
    INTERFACE("Location adjacent to an interface definition."),
    UNION("Location adjacent to a union definition."),
    ENUM("Location adjacent to an enum definition."),
    ENUM_VALUE("Location adjacent to an enum value definition."),
    INPUT_OBJECT("Location adjacent to an input object type definition."),
    INPUT_FIELD_DEFINITION("Location adjacent to an input object field definition.");

    private final String description;

    DirectiveLocation(String description) {
        this.description = description;
    }

    public String getDescription() {
        return this.description;
    }
}
