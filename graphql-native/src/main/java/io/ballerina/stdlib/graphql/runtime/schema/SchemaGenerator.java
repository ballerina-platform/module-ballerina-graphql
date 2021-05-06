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

package io.ballerina.stdlib.graphql.runtime.schema;

import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.stdlib.graphql.runtime.schema.types.Schema;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.QUERY;

/**
 * Generates a GraphQL schema from a Ballerina service.
 *
 * @since 0.2.0
 */
public class SchemaGenerator {
    private final ServiceType serviceType;

    public SchemaGenerator(ServiceType serviceType) {
        this.serviceType = serviceType;
    }

    public Schema generate() {
        return this.generateSchema();
    }

    public Schema generateSchema() {
        TypeFinder typeFinder = new TypeFinder(this.serviceType);
        typeFinder.find();
        FieldFinder fieldFinder = new FieldFinder(typeFinder.getTypeMap());
        fieldFinder.populateFields();
        Schema newSchema = new Schema();
        newSchema.setTypes(fieldFinder.getTypeMap());
        newSchema.setQueryType(fieldFinder.getType(QUERY));
        return newSchema;
    }
}
