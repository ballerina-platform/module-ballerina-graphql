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

import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.stdlib.graphql.compiler.schema.types.Schema;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

/**
 * Stores the mapping between a Ballerina service node and the generated GraphQL schema.
 * Ballerina service node includes both SERVICE_DECLARATION and MODULE_VAR_DECL of graphql:Service.
 */
public class GraphqlModifierContext {
    private final Map<Node, Schema> nodeSchemaMap;
    private final ArrayList<Integer> schemaHashCode;

    public GraphqlModifierContext() {
        this.nodeSchemaMap = new HashMap<>();
        this.schemaHashCode = new ArrayList<>();
    }

    public void add(Node node, Schema schema) {
        this.nodeSchemaMap.put(node, schema);
    }

    public Map<Node, Schema> getNodeSchemaMap() {
        return this.nodeSchemaMap;
    }

    public void addSchemaHashCode(int hashCode) {
        this.schemaHashCode.add(hashCode);
    }

    public ArrayList<Integer> getSchemaHashCodes() {
        return this.schemaHashCode;
    }
}
