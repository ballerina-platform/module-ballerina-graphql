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
import java.util.List;

import static io.ballerina.stdlib.graphql.commons.utils.TypeUtils.removeEscapeCharacter;

/**
 * Represents the {@code __Field} in GraphQL schema.
 */
public class Field implements Serializable {
    private static final long serialVersionUID = 1L;
    private final String name;
    private final String description;
    private Type type;
    private final boolean isDeprecated;
    private final String deprecationReason;
    private final Position position;
    private final List<InputValue> args;

    public Field(String name, String description) {
        this(name, description, null, false, null, null);
    }

    public Field(String name, Type type) {
        this(name, null, type);
    }

    public Field(String name, String description, Type type) {
        this(name, description, type, false, null, null);
    }

    public Field(String name, String description, Type type, boolean isDeprecated, String deprecationReason,
                 Position position) {
        this.name = removeEscapeCharacter(name);
        this.description = description;
        this.type = type;
        this.isDeprecated = isDeprecated;
        this.deprecationReason = deprecationReason;
        this.position = position;
        this.args = new ArrayList<>();
    }

    public String getName() {
        return this.name;
    }

    public void addArg(InputValue inputValue) {
        this.args.add(inputValue);
    }

    public String getDescription() {
        return this.description;
    }

    public Type getType() {
        return this.type;
    }

    public boolean isDeprecated() {
        return this.isDeprecated;
    }

    public String getDeprecationReason() {
        return this.deprecationReason;
    }

    public List<InputValue> getArgs() {
        return this.args;
    }

    public Position getPosition() {
        return position;
    }

    public void setType(Type type) {
        this.type = type;
    }
}
