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

import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import static io.ballerina.runtime.api.TypeTags.BOOLEAN_TAG;
import static io.ballerina.runtime.api.TypeTags.FLOAT_TAG;
import static io.ballerina.runtime.api.TypeTags.INT_TAG;
import static io.ballerina.runtime.api.TypeTags.STRING_TAG;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.isEnum;
import static io.ballerina.stdlib.graphql.runtime.utils.ModuleUtils.getModule;

/**
 * This class provides utility functions for Ballerina GraphQL engine.
 */
public class EngineUtils {

    private EngineUtils() {
    }

    // Schema related record types
    public static final String SCHEMA_RECORD = "__Schema";
    public static final String FIELD_RECORD = "__Field";
    public static final String TYPE_RECORD = "__Type";
    public static final String INPUT_VALUE_RECORD = "__InputValue";
    public static final String ENUM_VALUE_RECORD = "__EnumValue";

    // Schema related record field names
    public static final BString QUERY_TYPE_FIELD = StringUtils.fromString("queryType");
    public static final BString TYPES_FIELD = StringUtils.fromString("types");
    public static final BString TYPE_FIELD = StringUtils.fromString("type");
    public static final BString NAME_FIELD = StringUtils.fromString("name");
    public static final BString KIND_FIELD = StringUtils.fromString("kind");
    public static final BString FIELDS_FIELD = StringUtils.fromString("fields");
    public static final BString ARGS_FIELD = StringUtils.fromString("args");
    public static final BString DEFAULT_VALUE_FIELD = StringUtils.fromString("defaultValue");
    public static final BString ENUM_VALUES_FIELD = StringUtils.fromString("enumValues");
    public static final BString OF_TYPE_FIELD = StringUtils.fromString("ofType");
    public static final BString POSSIBLE_TYPES_FIELD = StringUtils.fromString("possibleTypes");
    public static final BString INTERFACES_FIELD = StringUtils.fromString("interfaces");

    // Schema related values
    public static final String INCLUDE_DEPRECATED = "includeDeprecated";
    public static final String FALSE = "false";

    // Schema related type names
    public static final String INTEGER = "Int";
    public static final String STRING = "String";
    public static final String BOOLEAN = "Boolean";
    public static final String FLOAT = "Float";
    public static final String DECIMAL = "Decimal";
    public static final String QUERY = "Query";

    // Input values
    public static final String KEY = "key";

    // Visitor object fields
    static final BString ERRORS_FIELD = StringUtils.fromString("errors");

    // Record Types
    static final String ERROR_DETAIL_RECORD = "ErrorDetail";
    static final String DATA_RECORD = "Data";

    // Record fields
    static final BString LOCATION_FIELD = StringUtils.fromString("location");
    static final BString LOCATIONS_FIELD = StringUtils.fromString("locations");
    static final BString MESSAGE_FIELD = StringUtils.fromString("message");
    static final BString SELECTIONS_FIELD = StringUtils.fromString("selections");
    static final BString ARGUMENTS_FIELD = StringUtils.fromString("arguments");
    static final BString VALUE_FIELD = StringUtils.fromString("value");
    static final BString IS_FRAGMENT_FIELD = StringUtils.fromString("isFragment");
    static final BString NODE_FIELD = StringUtils.fromString("node");
    static final BString ON_TYPE_FIELD = StringUtils.fromString("onType");

    // Native Data Fields
    public static final String GRAPHQL_SERVICE_OBJECT = "graphql.service.object";

    public static String getResourceName(ResourceMethodType resourceMethod) {
        String[] nameArray = resourceMethod.getResourcePath();
        int nameIndex = nameArray.length;
        return nameArray[nameIndex - 1];
    }

    static BMap<BString, Object> getErrorDetailRecord(BError error, BObject node) {
        BMap<BString, Object> location = node.getMapValue(LOCATION_FIELD);
        ArrayType locationsArrayType = TypeCreator.createArrayType(location.getType());
        BArray locations = ValueCreator.createArrayValue(locationsArrayType);
        locations.append(location);
        BMap<BString, Object> errorDetail = ValueCreator.createRecordValue(getModule(), ERROR_DETAIL_RECORD);
        errorDetail.put(MESSAGE_FIELD, StringUtils.fromString(error.getMessage()));
        errorDetail.put(LOCATIONS_FIELD, locations);
        return errorDetail;
    }

    static BMap<BString, Object> createDataRecord() {
        return ValueCreator.createRecordValue(getModule(), DATA_RECORD);
    }

    static boolean isScalarType(Type type) {
        int tag = type.getTag();
        if (tag == TypeTags.UNION_TAG) {
            if (isEnum((UnionType) type)) {
                return true;
            }
        }
        return tag == INT_TAG || tag == FLOAT_TAG || tag == BOOLEAN_TAG || tag == STRING_TAG;
    }

    // Temporary fix until https://github.com/ballerina-platform/ballerina-lang/issues/30728 is fixed
    static String getNameFromRecordTypeMap(BMap<BString, Object> record) {
        String name = record.getType().getName();
        if (name.contains("&")) {
            name = name.split("&")[0];
            String[] typeNameArray = name.split(":");
            name = typeNameArray[typeNameArray.length - 1].strip();
        }
        return name;
    }
}
