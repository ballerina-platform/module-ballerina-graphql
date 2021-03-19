/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.graphql.runtime.schema.tree;

import io.ballerina.runtime.api.types.Type;

import java.util.HashMap;
import java.util.Map;

/**
 * Represents a node in a tree used in Ballerina GraphQL schema generation.
 *
 * @since 0.2.0
 */
public class Node {
    private String name;
    private Type type;
    private Map<String, Node> children;
    private Node returnType;

    public Node(String name) {
        this(name, null, null);
    }

    public Node(String name, Type type) {
        this(name, type, null);
    }

    public Node(String name, Type type, Node returnType) {
        this.name = name;
        this.type = type;
        this.returnType = returnType;
        this.children = new HashMap<>();
    }

    public Type getType() {
        return this.type;
    }

    public String getName() {
        return this.name;
    }

    public void addChild(Node child) {
        if (child != null) {
            this.children.put(child.getName(), child);
        }
    }

    public Node getChild(String name) {
        return this.children.get(name);
    }

    public boolean hasChild(String name) {
        return this.children.containsKey(name);
    }

    public Node getReturnType() {
        return this.returnType;
    }

    public Map<String, Node> getChildren() {
        return this.children;
    }
}
