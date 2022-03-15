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

import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.schema.types.Type;
import io.ballerina.stdlib.graphql.compiler.schema.types.defaults.DefaultType;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceFinder;

import java.util.Map;

/**
 * Generates the GraphQL schema from a given, valid, Ballerina service.
 */
public class SchemaGenerator {
    private TypeFinder typeFinder;

    public void initialize(InterfaceFinder interfaceFinder) {
        this.typeFinder = new TypeFinder(interfaceFinder);
    }

    public void generate(SyntaxNodeAnalysisContext context) {
        this.typeFinder.findTypes(context);
        Map<String, Type> typeMap = this.typeFinder.getTypeMap();
        Type string = typeMap.get(DefaultType.STRING.getName());
    }
}
