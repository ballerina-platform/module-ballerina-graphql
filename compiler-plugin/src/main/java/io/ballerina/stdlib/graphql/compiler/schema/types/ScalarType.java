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
 * Stores the default scalar types in a GraphQL schema.
 */
public enum ScalarType {
    STRING(Name.STRING, Description.STRING),
    INT(Name.INT, Description.INT),
    FLOAT(Name.FLOAT, Description.FLOAT),
    BOOLEAN(Name.BOOLEAN, Description.BOOLEAN),
    DECIMAL(Name.DECIMAL, Description.DECIMAL);

    private final Name name;
    private final Description description;

    ScalarType(Name name, Description description) {
        this.name = name;
        this.description = description;
    }

    public String getName() {
        return this.name.getName();
    }

    public String getDescription() {
        return this.description.getDescription();
    }
}
