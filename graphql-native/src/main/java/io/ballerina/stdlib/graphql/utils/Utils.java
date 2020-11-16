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

package io.ballerina.stdlib.graphql.utils;

import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;

import static io.ballerina.stdlib.graphql.utils.Constants.ERROR;
import static io.ballerina.stdlib.graphql.utils.Constants.FIELD_LOCATION;
import static io.ballerina.stdlib.graphql.utils.Constants.FIELD_LOCATIONS;
import static io.ballerina.stdlib.graphql.utils.Constants.FIELD_NAME;
import static io.ballerina.stdlib.graphql.utils.Constants.PACKAGE_ID;
import static io.ballerina.stdlib.graphql.utils.Constants.RECORD_ERROR_RECORD;
import static io.ballerina.stdlib.graphql.utils.Constants.RECORD_LOCATION;
import static io.ballerina.stdlib.graphql.utils.Constants.RESOURCE_EXECUTION_ERROR;

/**
 * Utility class for Ballerina GraphQL module.
 */
public class Utils {
    private Utils() {
    }

    public static BArray createErrorArray() {
        Type errorType = TypeCreator.createErrorType(ERROR, PACKAGE_ID);
        ArrayType errorArrayType = TypeCreator.createArrayType(errorType);
        return ValueCreator.createArrayValue(errorArrayType);
    }

    public static BError createError(String type, BString message) {
        return ErrorCreator.createDistinctError(type, PACKAGE_ID, message);
    }

    public static BError createError(String type, String message, BMap<BString, Object> record) {
        BMap<BString, Object> errorRecord = createErrorRecord(record);
        BString bMessage = StringUtils.fromString(message);
        return ErrorCreator.createDistinctError(type, PACKAGE_ID, bMessage, errorRecord);
    }

    public static BError createResourceExecutionFailedError(String fieldName, String operationName) {
        String message = "Cannot query field \"" + fieldName + "\" on type \"" + operationName + "\".";
        BString bErrorMessage = StringUtils.fromString(message);
        return createError(RESOURCE_EXECUTION_ERROR, bErrorMessage);
    }

    public static BError createFieldNotFoundError(BMap<BString, Object> field, BString parentType) {
        BMap<BString, Object> location = (BMap<BString, Object>) field.get(FIELD_LOCATION);
        BString fieldName = (BString) field.get(FIELD_NAME);
        String message =
                "Cannot query field \"" + fieldName.getValue() + "\" on type \"" + parentType.getValue() + "\".";
        BMap<BString, Object> errorRecord = createErrorRecord(location);
        return createError(RESOURCE_EXECUTION_ERROR, message, errorRecord);
    }

    public static BMap<BString, Object> createErrorRecord(BMap<BString, Object> record) {
        BMap<BString, Object> location = getLocation(record);
        BArray locations = getLocationsArray(location);
        BMap<BString, Object> errorRecord = ValueCreator.createRecordValue(PACKAGE_ID, RECORD_ERROR_RECORD);
        errorRecord.put(FIELD_LOCATIONS, locations);
        return errorRecord;
    }

    public static BArray getLocationsArray(BMap... locations) {
        Type locationType = ValueCreator.createRecordValue(PACKAGE_ID, RECORD_LOCATION).getType();
        BArray locationsArrayValue = ValueCreator.createArrayValue(TypeCreator.createArrayType(locationType));
        for (BMap location : locations) {
            locationsArrayValue.append(location);
        }
        return locationsArrayValue;
    }

    public static BMap<BString, Object> getLocation(BMap<BString, Object> recordType) {
        return (BMap<BString, Object>) recordType.get(FIELD_LOCATION);
    }
}
