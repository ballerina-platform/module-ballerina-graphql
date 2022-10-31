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
 * Stores the names of the default types in a GraphQL schema.
 */
public enum FieldName {
    DESCRIPTION("description"),
    TYPES("types"),
    QUERY_TYPE("queryType"),
    MUTATION_TYPE("mutationType"),
    SUBSCRIPTION_TYPE("subscriptionType"),
    DIRECTIVES("directives"),
    KIND("kind"),
    NAME("name"),
    FIELDS("fields"),
    INTERFACES("interfaces"),
    POSSIBLE_TYPES("possibleTypes"),
    ENUM_VALUES("enumValues"),
    INPUT_FIELDS("inputFields"),
    OF_TYPE("ofType"),
    ARGS("args"),
    TYPE("type"),
    IS_DEPRECATED("isDeprecated"),
    DEPRECATION_REASON("deprecationReason"),
    DEFAULT_VALUE("defaultValue"),
    LOCATIONS("locations");

    private final String name;

    FieldName(String name) {
        this.name = name;
    }

    public String getName() {
        return this.name;
    }
}
