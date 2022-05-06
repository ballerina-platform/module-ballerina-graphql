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
 * Stores the fields of the introspection types of a GraphQL schema.
 */
public enum IntrospectionField {
    DESCRIPTION(FieldName.DESCRIPTION.getName(), null),
    TYPES(FieldName.TYPES.getName(), Description.TYPES.getDescription()),
    QUERY_TYPE(FieldName.QUERY_TYPE.getName(), Description.QUERY_TYPE.getDescription()),
    MUTATION_TYPE(FieldName.MUTATION_TYPE.getName(), Description.MUTATION_TYPE.getDescription()),
    SUBSCRIPTION_TYPE(FieldName.SUBSCRIPTION_TYPE.getName(), Description.SUBSCRIPTION_TYPE.getDescription()),
    DIRECTIVES(FieldName.DIRECTIVES.getName(), Description.DIRECTIVES.getDescription()),
    KIND(FieldName.KIND.getName(), null),
    NAME(FieldName.NAME.getName(), null),
    INTERFACES(FieldName.INTERFACES.getName(), null),
    POSSIBLE_TYPES(FieldName.POSSIBLE_TYPES.getName(), null),
    ENUM_VALUES(FieldName.ENUM_VALUES.getName(), null),
    INPUT_FIELDS(FieldName.INPUT_FIELDS.getName(), null),
    OF_TYPE(FieldName.OF_TYPE.getName(), null),
    ARGS(FieldName.ARGS.getName(), null),
    TYPE(FieldName.TYPE.getName(), null),
    IS_DEPRECATED(FieldName.IS_DEPRECATED.getName(), null),
    DEPRECATED_REASON(FieldName.DEPRECATION_REASON.getName(), null),
    DEFAULT_VALUE(FieldName.DEFAULT_VALUE.getName(), Description.DEFAULT_VALUE.getDescription()),
    LOCATIONS(FieldName.LOCATIONS.getName(), null);


    private final String name;
    private final String description;

    IntrospectionField(String name, String description) {
        this.name = name;
        this.description = description;
    }

    public String getName() {
        return this.name;
    }

    public String getDescription() {
        return this.description;
    }
}
