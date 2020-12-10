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

import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.graphql.schema.Schema;
import io.ballerina.stdlib.graphql.schema.SchemaType;
import io.ballerina.stdlib.graphql.schema.TypeKind;

import static io.ballerina.stdlib.graphql.engine.Utils.FIELD_RECORD;
import static io.ballerina.stdlib.graphql.engine.Utils.INPUT_VALUE_RECORD;
import static io.ballerina.stdlib.graphql.engine.Utils.SCHEMA_RECORD;
import static io.ballerina.stdlib.graphql.engine.Utils.TYPE_RECORD;
import static io.ballerina.stdlib.graphql.engine.Utils.addQueryFieldsForServiceType;
import static io.ballerina.stdlib.graphql.engine.Utils.getSchemaRecordFromSchema;
import static io.ballerina.stdlib.graphql.engine.Utils.getSchemaTypeForBalType;
import static io.ballerina.stdlib.graphql.utils.Utils.OPERATION_QUERY;
import static io.ballerina.stdlib.graphql.utils.Utils.PACKAGE_ID;

/**
 * This handles Ballerina GraphQL Engine.
 */
public class Engine {

    public static BMap<BString, Object> createSchema(BObject service) {
        Schema schema = new Schema();
        initializeIntrospectionTypes(schema);
        ServiceType serviceType = (ServiceType) service.getType();
        SchemaType queryType = new SchemaType(OPERATION_QUERY, TypeKind.OBJECT);
        addQueryFieldsForServiceType(serviceType, queryType, schema);
        schema.setQueryType(queryType);
        return getSchemaRecordFromSchema(schema);
    }

    private static void initializeIntrospectionTypes(Schema schema) {
        Type schemaBalType = ValueCreator.createRecordValue(PACKAGE_ID, SCHEMA_RECORD).getType();
        schema.addType(getSchemaTypeForBalType(schemaBalType, schema));

        Type typeBalType = ValueCreator.createRecordValue(PACKAGE_ID, TYPE_RECORD).getType();
        schema.addType(getSchemaTypeForBalType(typeBalType, schema));

        Type fieldBalType = ValueCreator.createRecordValue(PACKAGE_ID, FIELD_RECORD).getType();
        schema.addType(getSchemaTypeForBalType(fieldBalType, schema));

        Type inputValueBalType = ValueCreator.createRecordValue(PACKAGE_ID, INPUT_VALUE_RECORD).getType();
        schema.addType(getSchemaTypeForBalType(inputValueBalType, schema));
    }
}
