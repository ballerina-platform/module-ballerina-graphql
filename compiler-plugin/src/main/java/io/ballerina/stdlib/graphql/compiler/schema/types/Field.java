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
import java.util.ArrayList;
import java.util.List;

import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.removeEscapeCharacter;

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
    private final List<InputValue> args;

    public Field(String name, String description) {
        this(name, description, null, false, null);
    }

    public Field(String name, Type type) {
        this(name, type, null);
    }

    public Field(String name, Type type, String description) {
        this(name, description, type, false, null);
    }

    public Field(String name, String description, Type type, boolean isDeprecated, String deprecationReason) {
        this.name = removeEscapeCharacter(name);
        this.description = description;
        this.type = type;
        this.isDeprecated = isDeprecated;
        this.deprecationReason = deprecationReason;
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

    public void setType(Type type) {
        this.type = type;
    }
}
