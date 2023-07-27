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

import java.util.List;

/**
 * Stores the default scalar types in a GraphQL schema.
 */
public enum ScalarType {
    STRING(TypeName.STRING, Description.STRING, true),
    INT(TypeName.INT, Description.INT, true),
    FLOAT(TypeName.FLOAT, Description.FLOAT, true),
    BOOLEAN(TypeName.BOOLEAN, Description.BOOLEAN, true),
    DECIMAL(TypeName.DECIMAL, Description.DECIMAL, false),
    ID(TypeName.ID, Description.ID, true),
    UPLOAD(TypeName.UPLOAD, Description.UPLOAD, false),

    // Scalars used in federation subgraph schema
    ANY(TypeName.ANY, null, false),
    FIELD_SET(TypeName.FIELD_SET, null, false),
    LINK_IMPORT(TypeName.LINK_IMPORT, null, false);

    private final TypeName typeName;
    private final Description description;
    private final boolean isInbuiltType;

    ScalarType(TypeName typeName, Description description, Boolean isInbuiltType) {
        this.typeName = typeName;
        this.description = description;
        this.isInbuiltType = isInbuiltType;
    }

    public String getName() {
        return this.typeName.getName();
    }

    public String getDescription() {
        if (this.description == null) {
            return null;
        }
        return this.description.getDescription();
    }

    public Boolean isInbuiltType() {
        return this.isInbuiltType;
    }

    public static List<ScalarType> getFederatedScalarTypes() {
        return List.of(ANY, FIELD_SET, LINK_IMPORT);
    }
}
