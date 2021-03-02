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
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.graphql.schema.Schema;
import io.ballerina.stdlib.graphql.schema.tree.SchemaGenerator;
import io.ballerina.stdlib.graphql.utils.CallableUnitCallback;

import java.util.concurrent.CountDownLatch;

import static io.ballerina.stdlib.graphql.engine.EngineUtils.ARGUMENTS_FIELD;
import static io.ballerina.stdlib.graphql.engine.EngineUtils.DATA_RECORD;
import static io.ballerina.stdlib.graphql.engine.EngineUtils.ERRORS_FIELD;
import static io.ballerina.stdlib.graphql.engine.EngineUtils.EXECUTE_SINGLE_RESOURCE_FUNCTION;
import static io.ballerina.stdlib.graphql.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.engine.EngineUtils.SELECTIONS_FIELD;
import static io.ballerina.stdlib.graphql.engine.EngineUtils.VALUE_FIELD;
import static io.ballerina.stdlib.graphql.engine.EngineUtils.getErrorDetailRecord;
import static io.ballerina.stdlib.graphql.engine.EngineUtils.getResourceName;
import static io.ballerina.stdlib.graphql.engine.EngineUtils.getSchemaRecordFromSchema;
import static io.ballerina.stdlib.graphql.engine.EngineUtils.isScalarType;
import static io.ballerina.stdlib.graphql.engine.IntrospectionUtils.initializeIntrospectionTypes;
import static io.ballerina.stdlib.graphql.utils.ModuleUtils.getModule;

/**
 * This handles Ballerina GraphQL Engine.
 */
public class Engine {

    public static Object createSchema(BObject service) {
        try {
            ServiceType serviceType = (ServiceType) service.getType();
            Schema schema = createSchema(serviceType);
            initializeIntrospectionTypes(schema);
            return getSchemaRecordFromSchema(schema);
        } catch (BError e) {
            return e;
        }
    }

    private static Schema createSchema(ServiceType serviceType) {
        SchemaGenerator schemaGenerator = new SchemaGenerator(serviceType);
        return schemaGenerator.generate();
    }

    public static Object executeSingleResource(Environment environment, BObject service, BObject visitor,
                                               BObject fieldNode, BMap<BString, Object> arguments) {
        ServiceType serviceType = (ServiceType) service.getType();
        BString expectedResourceName = fieldNode.getStringValue(NAME_FIELD);

        Module module = getModule();
        StrandMetadata metadata = new StrandMetadata(module.getOrg(), module.getName(), module.getVersion(),
                                                     EXECUTE_SINGLE_RESOURCE_FUNCTION);

        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            String resourceName = getResourceName(resourceMethod);
            if (resourceName.equals(expectedResourceName.getValue())) {
                Object[] args = getArgsForResource(resourceMethod, arguments);
                CountDownLatch latch = new CountDownLatch(1);
                CallableUnitCallback callback = new CallableUnitCallback(latch);
                environment.getRuntime().invokeMethodAsync(service, resourceMethod.getName(), null, metadata,
                                                           callback, args);
                try {
                    latch.await();
                } catch (InterruptedException e) {
                    // Ignore
                }
                Object result = callback.getResult();
                if (result instanceof BError) {
                    BArray errors = visitor.getArrayValue(ERRORS_FIELD);
                    errors.append(getErrorDetailRecord((BError) result, fieldNode));
                } else if (result instanceof BMap) {
                    BMap<BString, Object> resultRecord = (BMap<BString, Object>) result;
                    return getDataFromRecord(fieldNode, resultRecord);
                } else if (result instanceof BArray) {
                    return getDataFromArray(fieldNode, (BArray) result);
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

    public static Object getDataFromBalType(BObject fieldNode, Object data) {
        if (data instanceof BArray) {
            return getDataFromArray(fieldNode, (BArray) data);
        } else if (data instanceof BMap) {
            return getDataFromRecord(fieldNode, (BMap<BString, Object>) data);
        } else {
            return data;
        }
    }

    private static BArray getDataFromArray(BObject fieldNode, BArray result) {
        if (isScalarType(result.getElementType())) {
            return result;
        } else {
            BArray resultArray = ValueCreator.createArrayValue(getDataRecordArrayType());
            for (int i = 0; i < result.size(); i++) {
                BMap<BString, Object> resultRecord = (BMap<BString, Object>) result.get(i);
                BMap<BString, Object> arrayField = getDataFromRecord(fieldNode, resultRecord);
                resultArray.append(arrayField);
            }
            return resultArray;
        }
    }

    private static BMap<BString, Object> getDataFromRecord(BObject fieldNode, BMap<BString, Object> record) {
        BArray selections = fieldNode.getArrayValue(SELECTIONS_FIELD);
        BMap<BString, Object> data = ValueCreator.createRecordValue(getModule(), DATA_RECORD);
        for (int i = 0; i < selections.size(); i++) {
            BObject subfieldNode = (BObject) selections.get(i);
            BString fieldName = subfieldNode.getStringValue(NAME_FIELD);
            Object fieldValue = record.get(fieldName);
            if (fieldValue instanceof BMap) {
                data.put(fieldName, getDataFromRecord(subfieldNode, (BMap<BString, Object>) fieldValue));
            } else if (fieldValue instanceof BArray) {
                data.put(fieldName, getDataFromArray(subfieldNode, (BArray) fieldValue));
            } else {
                data.put(fieldName, fieldValue);
            }
        }
        return data;
    }

    private static BMap<BString, Object> getArgumentsFromField(BObject fieldNode) {
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

    private static Object[] getArgsForResource(ResourceMethodType resourceMethod, BMap<BString, Object> arguments) {
        String[] paramNames = resourceMethod.getParamNames();
        Object[] result = new Object[paramNames.length * 2];
        for (int i = 0, j = 0; i < paramNames.length; i += 1, j += 2) {
            result[j] = arguments.get(StringUtils.fromString(paramNames[i]));
            result[j + 1] = true;
        }
        return result;
    }

    private static ArrayType getDataRecordArrayType() {
        BMap<BString, Object> data = ValueCreator.createRecordValue(getModule(), DATA_RECORD);
        return TypeCreator.createArrayType(data.getType());
    }
}
