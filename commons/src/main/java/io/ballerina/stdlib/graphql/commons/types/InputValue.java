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

import static io.ballerina.stdlib.graphql.commons.Utils.removeEscapeCharacter;

/**
 * Represents the {@code __InputValue} in GraphQL schema.
 */
public class InputValue implements Serializable {
    private static final long serialVersionUID = 1L;
    private final String name;
    private final String description;
    private final Type type;
    private final String defaultValue;

    public InputValue(String name, Type type, String description, String defaultValue) {
        this.name = removeEscapeCharacter(name);
        this.description = description;
        this.type = type;
        this.defaultValue = defaultValue;
    }

    public String getName() {
        return this.name;
    }

    public String getDescription() {
        return this.description;
    }

    public Type getType() {
        return this.type;
    }

    public String getDefaultValue() {
        return this.defaultValue;
    }
}
