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

import java.io.Serializable;

/**
 * Represents the {@code __EnumValue} type in GraphQL schema.
 */
public class EnumValue implements Serializable {
    private static final long serialVersionUID = 1L;
    private final String name;
    private final String description;
    private final boolean isDeprecated;
    private final String deprecationReason;

    public EnumValue(String name, String description) {
        this(name, description, false, null);
    }

    public EnumValue(String name, String description, boolean isDeprecated, String deprecationReason) {
        this.name = name;
        this.description = description;
        this.isDeprecated = isDeprecated;
        this.deprecationReason = deprecationReason;
    }

    public String getName() {
        return this.name;
    }

    public String getDescription() {
        return this.description;
    }

    public boolean isDeprecated() {
        return this.isDeprecated;
    }

    public String getDeprecationReason() {
        return this.deprecationReason;
    }
}
