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
 * Represents the {@code __TypeKind} enum in GraphQL schema.
 */
public enum TypeKind {
    SCALAR("Indicates this type is a scalar."),
    OBJECT("Indicates this type is an object. `fields` and `interfaces` are valid fields."),
    INTERFACE("Indicates this type is an interface. `fields`, `interfaces`, and `possibleTypes` are valid fields."),
    UNION("Indicates this type is a union. `possibleTypes` is a valid field."),
    ENUM("Indicates this type is an enum. `enumValues` is a valid field."),
    INPUT_OBJECT("Indicates this type is an input object. `inputFields` is a valid field."),
    LIST("Indicates this type is a list. `ofType` is a valid field."),
    NON_NULL("Indicates this type is a non-null. `ofType` is a valid field.");

    private final String description;

    TypeKind(String description) {
        this.description = description;
    }

    public String getDescription() {
        return this.description;
    }
}
