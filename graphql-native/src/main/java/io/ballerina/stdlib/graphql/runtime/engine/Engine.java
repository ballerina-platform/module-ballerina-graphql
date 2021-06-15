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

package io.ballerina.stdlib.graphql.runtime.engine;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.graphql.runtime.schema.FieldFinder;
import io.ballerina.stdlib.graphql.runtime.schema.SchemaRecordGenerator;
import io.ballerina.stdlib.graphql.runtime.schema.TypeFinder;
import io.ballerina.stdlib.graphql.runtime.schema.types.Schema;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ARGUMENTS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.GRAPHQL_SERVICE_OBJECT;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isPathsMatching;
import static io.ballerina.stdlib.graphql.runtime.engine.ResponseGenerator.getDataFromResult;
import static io.ballerina.stdlib.graphql.runtime.engine.ResponseGenerator.getDataFromService;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.STRAND_METADATA;

/**
 * This handles Ballerina GraphQL Engine.
 */
public class Engine {
    private Engine() {
    }

    public static Object createSchema(BObject service) {
        try {
            ServiceType serviceType = (ServiceType) service.getType();
            Schema schema = createSchema(serviceType);
            SchemaRecordGenerator schemaRecordGenerator = new SchemaRecordGenerator(schema);
            return schemaRecordGenerator.getSchemaRecord();
        } catch (BError e) {
            return e;
        }
    }

    private static Schema createSchema(ServiceType serviceType) {
        TypeFinder typeFinder = new TypeFinder(serviceType);
        typeFinder.populateTypes();

        FieldFinder fieldFinder = new FieldFinder(typeFinder.getTypeMap());
        fieldFinder.populateFields();

        return new Schema(fieldFinder.getTypeMap());
    }

    public static void attachServiceToEngine(BObject service, BObject engine) {
        engine.addNativeData(GRAPHQL_SERVICE_OBJECT, service);
    }

    public static void executeService(Environment environment, BObject engine, BObject visitor, BObject node,
                                      BMap<BString, Object> data) {
        BObject service = (BObject) engine.getNativeData(GRAPHQL_SERVICE_OBJECT);
        List<String> paths = new ArrayList<>();
        paths.add(node.getStringValue(NAME_FIELD).getValue());
        executeResource(environment, service, visitor, node, data, paths);
    }

    public static void getResult(Environment environment, BObject visitor, BObject node, Object result,
                                 BMap<BString, Object> data) {
        getDataFromResult(environment, visitor, node, result, data);
    }

    static void executeResource(Environment environment, BObject service, BObject visitor, BObject node,
                                BMap<BString, Object> data, List<String> paths) {
        ServiceType serviceType = (ServiceType) service.getType();
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            if (isPathsMatching(resourceMethod, paths)) {
                getResourceExecutionResult(environment, service, visitor, node, resourceMethod, data);
                return;
            }
        }
        // The resource not found. This should be a resource with hierarchical paths
        getDataFromService(environment, service, visitor, node, data, paths);
    }

    private static void getResourceExecutionResult(Environment environment, BObject service, BObject visitor,
                                                   BObject node, ResourceMethodType resourceMethod,
                                                   BMap<BString, Object> data) {
        BMap<BString, Object> arguments = getArgumentsFromField(node);
        Object[] args = getArgsForResource(resourceMethod, arguments);
        CountDownLatch latch = new CountDownLatch(1);
        ResourceCallback callback = new ResourceCallback(environment, latch, visitor, node, data);
        environment.getRuntime().invokeMethodAsync(service, resourceMethod.getName(), null, STRAND_METADATA,
                                                   callback, args);
        try {
            latch.await();
        } catch (InterruptedException e) {
            // Ignore
        }
    }

    public static BMap<BString, Object> getArgumentsFromField(BObject node) {
        BArray argumentArray = node.getArrayValue(ARGUMENTS_FIELD);
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
            if (arguments.get(StringUtils.fromString(paramNames[i])) == null) {
                result[j] = resourceMethod.getParameterTypes()[i].getZeroValue();
                result[j + 1] = false;
            } else {
                result[j] = arguments.get(StringUtils.fromString(paramNames[i]));
                result[j + 1] = true;
            }
        }
        return result;
    }
}
