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

import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.ResourceFunctionType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import static io.ballerina.runtime.api.TypeTags.BOOLEAN_TAG;
import static io.ballerina.runtime.api.TypeTags.FLOAT_TAG;
import static io.ballerina.runtime.api.TypeTags.INT_TAG;
import static io.ballerina.runtime.api.TypeTags.RECORD_TYPE_TAG;
import static io.ballerina.runtime.api.TypeTags.SERVICE_TAG;
import static io.ballerina.runtime.api.TypeTags.STRING_TAG;
import static io.ballerina.stdlib.graphql.utils.Constants.FIELD_FIELDS;
import static io.ballerina.stdlib.graphql.utils.Constants.FIELD_INPUTS;
import static io.ballerina.stdlib.graphql.utils.Constants.FIELD_KIND;
import static io.ballerina.stdlib.graphql.utils.Constants.FIELD_NAME;
import static io.ballerina.stdlib.graphql.utils.Constants.PACKAGE_ID;
import static io.ballerina.stdlib.graphql.utils.Constants.RECORD_FIELD;
import static io.ballerina.stdlib.graphql.utils.Constants.RECORD_INPUT;
import static io.ballerina.stdlib.graphql.utils.Constants.RECORD_SCHEMA;

/**
 * This handles Ballerina GraphQL Engine.
 */
public class Engine {
    public static BMap<BString, Object> createSchema(BObject service) {
        ServiceType serviceType = (ServiceType) service.getType();
        ResourceFunctionType[] resourceFunctions = serviceType.getResourceFunctions();
        BMap<BString, Object> schemaRecord = getSchemaRecord();
        BArray fieldArray = getFieldArray();
        for (ResourceFunctionType resourceFunction : resourceFunctions) {
            fieldArray.append(handleResource(resourceFunction));
        }
        schemaRecord.put(FIELD_FIELDS, fieldArray);
        return schemaRecord;
    }

    private static BMap<BString, Object> handleResource(ResourceFunctionType resourceFunction) {
        BMap<BString, Object> fieldRecord = ValueCreator.createRecordValue(PACKAGE_ID, RECORD_FIELD);
        BString fieldName = getResourceName(resourceFunction);
        BArray arguments = getResourceInputs(resourceFunction);
        BArray fields = getResourceFields(resourceFunction);
        Type returnType = resourceFunction.getType().getReturnType();
        fieldRecord.put(FIELD_NAME, fieldName);
        fieldRecord.put(FIELD_KIND, ValueCreator.createTypedescValue(returnType));
        fieldRecord.put(FIELD_INPUTS, arguments);
        fieldRecord.put(FIELD_FIELDS, fields);
        return fieldRecord;
    }

    private static BMap<BString, Object> getSchemaRecord() {
        return ValueCreator.createRecordValue(PACKAGE_ID, RECORD_SCHEMA);
    }

    private static BArray getFieldArray() {
        BMap<BString, Object> fieldRecord = ValueCreator.createRecordValue(PACKAGE_ID, RECORD_FIELD);
        ArrayType fieldArrayType = TypeCreator.createArrayType(fieldRecord.getType());
        return ValueCreator.createArrayValue(fieldArrayType);
    }

    private static BString getResourceName(ResourceFunctionType resourceFunction) {
        String[] nameArray = resourceFunction.getResourcePath();
        int nameIndex = nameArray.length;
        return StringUtils.fromString(nameArray[nameIndex - 1]);
    }

    // TODO: Check for non-required, default parameters
    private static BArray getResourceInputs(ResourceFunctionType resourceFunction) {
        String[] inputNames = resourceFunction.getParamNames();
        Type[] inputTypes = resourceFunction.getParameterTypes();
        if (inputNames.length == 0) {
            return null;
        }
        BMap<BString, Object> inputRecord = ValueCreator.createRecordValue(PACKAGE_ID, RECORD_INPUT);
        ArrayType inputArrayType = TypeCreator.createArrayType(inputRecord.getType());
        BArray inputArray = ValueCreator.createArrayValue(inputArrayType);

        for (int i = 0; i < inputNames.length; i++) {
            inputRecord = ValueCreator.createRecordValue(PACKAGE_ID, RECORD_INPUT);
            inputRecord.put(FIELD_NAME, StringUtils.fromString(inputNames[i]));
            inputRecord.put(FIELD_KIND, ValueCreator.createTypedescValue(inputTypes[i]));
            inputArray.append(inputRecord);
        }
        return inputArray;
    }

    private static BArray getResourceFields(ResourceFunctionType resourceFunction) {
        BArray fields = getFieldArray();
        int resourceReturnTypeTag = resourceFunction.getType().getReturnType().getTag();
        switch (resourceReturnTypeTag) {
            case RECORD_TYPE_TAG:
                // TODO: get record fields
            case SERVICE_TAG:
                // TODO: Get resources
            case INT_TAG:
            case STRING_TAG:
            case BOOLEAN_TAG:
            case FLOAT_TAG:
                return null;
            default:
                // TODO: Return error
        }
        return null;
    }
}
