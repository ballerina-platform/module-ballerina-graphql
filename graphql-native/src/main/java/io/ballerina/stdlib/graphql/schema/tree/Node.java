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

package io.ballerina.stdlib.graphql.schema.tree;

import io.ballerina.runtime.api.types.Type;

import java.util.HashMap;
import java.util.Map;

/**
 * Represents a Node in the GraphQL schema generated for a Ballerina Service.
 */
public class Node {
    private String name;
    private Type type;
    private Map<String, Node> children;
    private Map<String, Type> arguments;
    private boolean nullable;

    public Node(String name) {
        this.name = name;
        this.children = new HashMap<>();
        this.arguments = new HashMap<>();
    }

    public Node(String name, Type type) {
        this.name = name;
        this.type = type;
        this.children = new HashMap<>();
        this.arguments = new HashMap<>();
    }

    public Node(String name, Type type, boolean nullable) {
        this.name = name;
        this.type = type;
        this.nullable = nullable;
        this.children = new HashMap<>();
        this.arguments = new HashMap<>();
    }

    public void setType(Type type) {
        this.type = type;
    }

    public Type getType() {
        return this.type;
    }

    public void addArgument(String name, Type argument) {
        this.arguments.put(name, argument);
    }

    public Map<String, Type> getArguments() {
        return this.arguments;
    }

    public void addChild(Node child) {
        this.children.put(child.name, child);
    }

    public void setNullable(boolean nullable) {
        this.nullable = nullable;
    }

    public boolean hasChild(String name) {
        return this.children.containsKey(name);
    }

    public Node getChild(String name) {
        return this.children.get(name);
    }
}
