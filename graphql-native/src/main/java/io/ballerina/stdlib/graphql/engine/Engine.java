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

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ResourceFunctionType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.graphql.schema.Schema;
import io.ballerina.stdlib.graphql.schema.SchemaType;
import io.ballerina.stdlib.graphql.schema.TypeKind;

import static io.ballerina.stdlib.graphql.engine.Utils.EXECUTE_RESOURCE_METADATA;
import static io.ballerina.stdlib.graphql.engine.Utils.FIELD_RECORD;
import static io.ballerina.stdlib.graphql.engine.Utils.FIELD_TYPE_FIELD;
import static io.ballerina.stdlib.graphql.engine.Utils.INPUT_VALUE_RECORD;
import static io.ballerina.stdlib.graphql.engine.Utils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.engine.Utils.PRIMITIVE;
import static io.ballerina.stdlib.graphql.engine.Utils.SCHEMA_RECORD;
import static io.ballerina.stdlib.graphql.engine.Utils.SERVICE_TYPE_FIELD;
import static io.ballerina.stdlib.graphql.engine.Utils.TYPE_RECORD;
import static io.ballerina.stdlib.graphql.engine.Utils.addQueryFieldsForServiceType;
import static io.ballerina.stdlib.graphql.engine.Utils.getResourceName;
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

    public static void executeResources(Environment environment, BObject visitor, BObject fieldNode) {
        BObject service = (BObject) visitor.get(SERVICE_TYPE_FIELD);
        ServiceType serviceType = (ServiceType) service.getType();
        BString expectedResourceName = fieldNode.getStringValue(NAME_FIELD);
        BString returnType = fieldNode.getStringValue(FIELD_TYPE_FIELD);

        for (ResourceFunctionType resourceFunction : serviceType.getResourceFunctions()) {
            String resourceName = getResourceName(resourceFunction);
            if (resourceName.equals(expectedResourceName.getValue())) {
                executeResource(environment, returnType, service, resourceFunction, visitor, fieldNode);
                break;
            }
        }
    }

    public static void executeResource(Environment environment, BString returnType, BObject service,
                                       ResourceFunctionType resourceFunction, BObject visitor,
                                       BObject fieldNode) {
        if (returnType.getValue().equals(PRIMITIVE.getValue())) {
            executePrimitiveResource(environment, service, resourceFunction.getName(), resourceFunction, visitor,
                                     fieldNode);
        }
    }

    public static void executePrimitiveResource(Environment environment, BObject service, String resourceName,
                                                ResourceFunctionType resourceFunction, BObject visitor,
                                                BObject fieldNode) {
        Type returnType = resourceFunction.getType().getReturnType();
        Callback callback = new CallableUnitCallback(visitor, fieldNode);
        environment.getRuntime().invokeMethodAsync(service, resourceName, null, EXECUTE_RESOURCE_METADATA, callback,
                                                   null, returnType);
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
