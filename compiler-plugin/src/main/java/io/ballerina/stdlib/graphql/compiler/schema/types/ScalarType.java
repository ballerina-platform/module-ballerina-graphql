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
    STRING(TypeName.STRING, Description.STRING),
    INT(TypeName.INT, Description.INT),
    FLOAT(TypeName.FLOAT, Description.FLOAT),
    BOOLEAN(TypeName.BOOLEAN, Description.BOOLEAN),
    DECIMAL(TypeName.DECIMAL, Description.DECIMAL);

    private final TypeName typeName;
    private final Description description;

    ScalarType(TypeName typeName, Description description) {
        this.typeName = typeName;
        this.description = description;
    }

    public String getName() {
        return this.typeName.getName();
    }

    public String getDescription() {
        return this.description.getDescription();
    }
}
