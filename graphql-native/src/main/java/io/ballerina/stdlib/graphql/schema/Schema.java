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

package io.ballerina.stdlib.graphql.schema;

import java.util.HashMap;
import java.util.Map;

/**
 * This class represents a GraphQL schema.
 */
public class Schema {
    private Map<String, SchemaType> types;
    private SchemaType queryType;

    public Schema() {
        this.types = new HashMap();
    }

    public void addType(SchemaType type) {
        this.types.put(type.getName(), type);
    }

    public Map<String, SchemaType> getTypes() {
        return this.types;
    }

    public SchemaType getType(String name) {
        return this.types.get(name);
    }

    public void setQueryType(SchemaType queryType) {
        this.addType(queryType);
        this.queryType = queryType;
    }

    public SchemaType getQueryType() {
        return this.queryType;
    }
}
