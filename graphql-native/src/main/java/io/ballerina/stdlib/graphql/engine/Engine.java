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
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ResourceFunctionType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BFuture;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.graphql.schema.Schema;
import io.ballerina.stdlib.graphql.schema.SchemaType;
import io.ballerina.stdlib.graphql.schema.TypeKind;

import static io.ballerina.stdlib.graphql.engine.Utils.EXECUTE_SINGLE_RESOURCE_METADATA;
import static io.ballerina.stdlib.graphql.engine.Utils.FIELD_RECORD;
import static io.ballerina.stdlib.graphql.engine.Utils.INPUT_VALUE_RECORD;
import static io.ballerina.stdlib.graphql.engine.Utils.NAME_FIELD;
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

    public static BFuture executeSingleResource(Environment environment, BObject visitor, BObject fieldNode,
                                                BMap<BString, Object> arguments) {
        BObject service = (BObject) visitor.get(SERVICE_TYPE_FIELD);
        ServiceType serviceType = (ServiceType) service.getType();
        BString expectedResourceName = fieldNode.getStringValue(NAME_FIELD);

        for (ResourceFunctionType resourceFunction : serviceType.getResourceFunctions()) {
            String resourceName = getResourceName(resourceFunction);
            if (resourceName.equals(expectedResourceName.getValue())) {
                Object[] args = getArgsForResource(resourceFunction, arguments);
                BFuture future = environment.getRuntime().invokeMethodAsync(service, resourceFunction.getName(), null,
                                                                            EXECUTE_SINGLE_RESOURCE_METADATA, null,
                                                                            null, null,
                                                                            args);
                return future;
            }
        }
        return null;
    }

    public static Object[] getArgsForResource(ResourceFunctionType resourceFunction, BMap<BString, Object> arguments) {
        String[] paramNames = resourceFunction.getParamNames();
        Object[] result = new Object[paramNames.length * 2];
        for (int i = 0, j = 0; i < paramNames.length; i += 1, j += 2) {
            result[j] = arguments.get(StringUtils.fromString(paramNames[i]));;
            result[j + 1] = true;
        }
        return result;
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
