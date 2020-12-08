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

package io.ballerina.stdlib.graphql.engine;

import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.graphql.schema.Schema;
import io.ballerina.stdlib.graphql.schema.SchemaType;

import static io.ballerina.stdlib.graphql.engine.Utils.addQueryFieldsForServiceType;
import static io.ballerina.stdlib.graphql.engine.Utils.getSchemaRecordFromSchema;

/**
 * This handles Ballerina GraphQL Engine.
 */
public class Engine {

    public static BMap<BString, Object> createSchema(BObject service) {
        Schema schema = new Schema();
        SchemaType queryType = schema.getQueryType();
        ServiceType serviceType = (ServiceType) service.getType();
        addQueryFieldsForServiceType(serviceType, queryType, schema);
        return getSchemaRecordFromSchema(schema);
    }
}
