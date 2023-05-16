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
 * Stores default type names of a GraphQL schema.
 */
public enum TypeName {
    STRING("String"),
    INT("Int"),
    FLOAT("Float"),
    BOOLEAN("Boolean"),
    DECIMAL("Decimal"),
    ID("ID"),
    UPLOAD("Upload"),
    SCHEMA("__Schema"),
    TYPE("__Type"),
    FIELD("__Field"),
    INPUT_VALUE("__InputValue"),
    ENUM_VALUE("__EnumValue"),
    TYPE_KIND("__TypeKind"),
    DIRECTIVE("__Directive"),
    DIRECTIVE_LOCATION("__DirectiveLocation"),
    QUERY("Query"),
    MUTATION("Mutation"),
    SUBSCRIPTION("Subscription"),

    // Type names used in federated subgraph schema
    ANY("_Any"),
    FIELD_SET("FieldSet"),
    LINK_IMPORT("link__Import"),
    LINK_PURPOSE("link__Purpose"),
    ENTITY("_Entity"),
    SERVICE("_Service");

    private final String name;

    TypeName(String name) {
        this.name = name;
    }

    public String getName() {
        return this.name;
    }
}
