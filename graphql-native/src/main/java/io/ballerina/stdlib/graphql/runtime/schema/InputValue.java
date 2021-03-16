/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.graphql.runtime.schema;

/**
 * This class represents an InputValue of a GraphQL field.
 */
public class InputValue {
    private String name;
    private SchemaType type;
    private String defaultValue;

    public InputValue(String name, SchemaType type) {
        this(name, type, null);
    }

    public InputValue(String name, SchemaType type, String defaultValue) {
        this.name = name;
        this.type = type;
        this.defaultValue = defaultValue;
    }

    public String getName() {
        return name;
    }

    public SchemaType getType() {
        return type;
    }

    public String getDefaultValue() {
        return defaultValue;
    }
}
