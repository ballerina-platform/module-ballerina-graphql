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

package io.ballerina.stdlib.graphql.compiler.schema.generator;

import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.stdlib.graphql.compiler.schema.types.Type;
import io.ballerina.stdlib.graphql.compiler.schema.types.TypeKind;

import java.util.Map;

/**
 * Finds the fields of the GraphQL schema and subsequent objects.
 */
public class FieldFinder {
    private final Map<String, Type> typeMap;
    private final ServiceDeclarationSymbol serviceDeclarationSymbol;

    public FieldFinder(Map<String, Type> typeMap, ServiceDeclarationSymbol serviceDeclarationSymbol) {
        this.typeMap = typeMap;
        this.serviceDeclarationSymbol = serviceDeclarationSymbol;
    }

    public void findFields() {
        for (Type type : this.typeMap.values()) {
            if (type.getTypeKind() == TypeKind.OBJECT || type.getTypeKind() == TypeKind.INPUT_OBJECT) {
                findFields(type);
            }
        }
    }

    private void findFields(Type type) {

    }
}
