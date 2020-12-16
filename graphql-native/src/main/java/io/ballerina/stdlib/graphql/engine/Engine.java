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
import io.ballerina.runtime.api.Module;
import io.ballerina.runtime.api.async.StrandMetadata;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ResourceFunctionType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.graphql.schema.Schema;
import io.ballerina.stdlib.graphql.schema.SchemaType;
import io.ballerina.stdlib.graphql.schema.TypeKind;
import io.ballerina.stdlib.graphql.utils.CallableUnitCallback;

import java.util.concurrent.CountDownLatch;

import static io.ballerina.stdlib.graphql.engine.Utils.ARGUMENTS_FIELD;
import static io.ballerina.stdlib.graphql.engine.Utils.DATA_RECORD;
import static io.ballerina.stdlib.graphql.engine.Utils.ERRORS_FIELD;
import static io.ballerina.stdlib.graphql.engine.Utils.EXECUTE_SINGLE_RESOURCE_FUNCTION;
import static io.ballerina.stdlib.graphql.engine.Utils.FIELD_RECORD;
import static io.ballerina.stdlib.graphql.engine.Utils.INPUT_VALUE_RECORD;
import static io.ballerina.stdlib.graphql.engine.Utils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.engine.Utils.QUERY;
import static io.ballerina.stdlib.graphql.engine.Utils.SCHEMA_RECORD;
import static io.ballerina.stdlib.graphql.engine.Utils.SELECTIONS_FIELD;
import static io.ballerina.stdlib.graphql.engine.Utils.TYPE_RECORD;
import static io.ballerina.stdlib.graphql.engine.Utils.VALUE_FIELD;
import static io.ballerina.stdlib.graphql.engine.Utils.addQueryFieldsForServiceType;
import static io.ballerina.stdlib.graphql.engine.Utils.getErrorDetailRecord;
import static io.ballerina.stdlib.graphql.engine.Utils.getResourceName;
import static io.ballerina.stdlib.graphql.engine.Utils.getSchemaRecordFromSchema;
import static io.ballerina.stdlib.graphql.engine.Utils.getSchemaTypeForBalType;

/**
 * This handles Ballerina GraphQL Engine.
 */
public class Engine {

    public static BMap<BString, Object> createSchema(Environment environment, BObject service) {
        Schema schema = new Schema();
        initializeIntrospectionTypes(environment, schema);
        ServiceType serviceType = (ServiceType) service.getType();
        SchemaType queryType = new SchemaType(QUERY, TypeKind.OBJECT);
        addQueryFieldsForServiceType(serviceType, queryType, schema);
        schema.setQueryType(queryType);
        return getSchemaRecordFromSchema(environment, schema);
    }

    public static Object executeSingleResource(Environment environment, BObject service, BObject visitor,
                                               BObject fieldNode, BMap<BString, Object> arguments) {
        ServiceType serviceType = (ServiceType) service.getType();
        BString expectedResourceName = fieldNode.getStringValue(NAME_FIELD);

        Module module = environment.getCurrentModule();
        StrandMetadata metadata = new StrandMetadata(module.getOrg(), module.getName(), module.getVersion(),
                                                     EXECUTE_SINGLE_RESOURCE_FUNCTION);

        for (ResourceFunctionType resourceFunction : serviceType.getResourceFunctions()) {
            String resourceName = getResourceName(resourceFunction);
            if (resourceName.equals(expectedResourceName.getValue())) {
                Object[] args = getArgsForResource(resourceFunction, arguments);
                CountDownLatch latch = new CountDownLatch(1);
                CallableUnitCallback callback = new CallableUnitCallback(latch);
                environment.getRuntime().invokeMethodAsync(service, resourceFunction.getName(), null, metadata,
                                                           callback, args);
                try {
                    latch.await();
                } catch (InterruptedException e) {
                    // Ignore
                }
                Object result = callback.getResult();
                if (result instanceof BError) {
                    BArray errors = visitor.getArrayValue(ERRORS_FIELD);
                    errors.append(getErrorDetailRecord(environment.getCurrentModule(), (BError) result, fieldNode));
                } else if (result instanceof BMap) {
                    BMap<BString, Object> resultRecord = (BMap<BString, Object>) result;
                    return getSelectionsFromRecord(fieldNode, resultRecord, module);
                } else if (result instanceof BObject) {
                    BObject subService = (BObject) result;
                    BArray selections = fieldNode.getArrayValue(SELECTIONS_FIELD);
                    BMap<BString, Object> data = ValueCreator.createRecordValue(module, DATA_RECORD);
                    for (int i = 0; i < selections.size(); i++) {
                        BObject subField = (BObject) selections.get(i);
                        BMap<BString, Object> subfieldArgs = getArgumentsFromField(subField);
                        Object subFieldValue = executeSingleResource(environment, subService, visitor, subField,
                                                                     subfieldArgs);
                        data.put(subField.getStringValue(NAME_FIELD), subFieldValue);
                    }
                    return data;
                } else {
                    return result;
                }
            }
        }
        return null;
    }

    public static BMap<BString, Object> getArgumentsFromField(BObject fieldNode) {
        BArray argumentArray = fieldNode.getArrayValue(ARGUMENTS_FIELD);
        BMap<BString, Object> argumentsMap = ValueCreator.createMapValue();
        for (int i = 0; i < argumentArray.size(); i++) {
            BObject argumentNode = (BObject) argumentArray.get(i);
            BMap<BString, Object> argNameRecord = (BMap<BString, Object>) argumentNode.getMapValue(NAME_FIELD);
            BMap<BString, Object> argValueRecord = (BMap<BString, Object>) argumentNode.getMapValue(VALUE_FIELD);
            BString argName = argNameRecord.getStringValue(VALUE_FIELD);
            Object argValue = argValueRecord.get(VALUE_FIELD);
            argumentsMap.put(argName, argValue);
        }
        return argumentsMap;
    }

    public static Object[] getArgsForResource(ResourceFunctionType resourceFunction, BMap<BString, Object> arguments) {
        String[] paramNames = resourceFunction.getParamNames();
        Object[] result = new Object[paramNames.length * 2];
        for (int i = 0, j = 0; i < paramNames.length; i += 1, j += 2) {
            result[j] = arguments.get(StringUtils.fromString(paramNames[i]));
            result[j + 1] = true;
        }
        return result;
    }

    private static void initializeIntrospectionTypes(Environment environment, Schema schema) {
        Type schemaBalType = ValueCreator.createRecordValue(environment.getCurrentModule(), SCHEMA_RECORD).getType();
        schema.addType(getSchemaTypeForBalType(schemaBalType, schema));

        Type typeBalType = ValueCreator.createRecordValue(environment.getCurrentModule(), TYPE_RECORD).getType();
        schema.addType(getSchemaTypeForBalType(typeBalType, schema));

        Type fieldBalType = ValueCreator.createRecordValue(environment.getCurrentModule(), FIELD_RECORD).getType();
        schema.addType(getSchemaTypeForBalType(fieldBalType, schema));

        Type inputValueBalType = ValueCreator.createRecordValue(environment.getCurrentModule(), INPUT_VALUE_RECORD)
                .getType();
        schema.addType(getSchemaTypeForBalType(inputValueBalType, schema));
    }

    private static BMap<BString, Object> getSelectionsFromRecord(BObject fieldNode, BMap<BString, Object> record,
                                                                 Module module) {
        BArray selections = fieldNode.getArrayValue(SELECTIONS_FIELD);
        BMap<BString, Object> data = ValueCreator.createRecordValue(module, DATA_RECORD);
        for (int i = 0; i < selections.size(); i++) {
            BObject subfieldNode = (BObject) selections.get(i);
            BString fieldName = subfieldNode.getStringValue(NAME_FIELD);
            Object fieldValue = record.get(fieldName);
            if (fieldValue instanceof BMap) {
                data.put(fieldName, getSelectionsFromRecord(subfieldNode, (BMap<BString, Object>) fieldValue, module));
            } else {
                data.put(fieldName, fieldValue);
            }
        }
        return data;
    }
}
