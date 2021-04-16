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

import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.graphql.runtime.schema.InputValue;
import io.ballerina.stdlib.graphql.runtime.schema.Schema;
import io.ballerina.stdlib.graphql.runtime.schema.SchemaField;
import io.ballerina.stdlib.graphql.runtime.schema.SchemaType;
import io.ballerina.stdlib.graphql.runtime.schema.TypeKind;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import static io.ballerina.runtime.api.TypeTags.BOOLEAN_TAG;
import static io.ballerina.runtime.api.TypeTags.FLOAT_TAG;
import static io.ballerina.runtime.api.TypeTags.INT_TAG;
import static io.ballerina.runtime.api.TypeTags.STRING_TAG;
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
    public static final String TYPE_KIND_ENUM = "__TypeKind";
    public static final String ENUM_VALUE_RECORD = "__EnumValue";

    // Schema related record field names
    private static final BString QUERY_TYPE_FIELD = StringUtils.fromString("queryType");
    private static final BString TYPES_FIELD = StringUtils.fromString("types");
    private static final BString TYPE_FIELD = StringUtils.fromString("type");
    static final BString NAME_FIELD = StringUtils.fromString("name");
    private static final BString KIND_FIELD = StringUtils.fromString("kind");
    static final BString FIELDS_FIELD = StringUtils.fromString("fields");
    private static final BString ARGS_FIELD = StringUtils.fromString("args");
    private static final BString DEFAULT_VALUE_FIELD = StringUtils.fromString("defaultValue");
    private static final BString ENUM_VALUES_FIELD = StringUtils.fromString("enumValues");
    private static final BString OF_TYPE_FIELD = StringUtils.fromString("ofType");

    // Schema related type names
    public static final String INTEGER = "Int";
    public static final String STRING = "String";
    public static final String BOOLEAN = "Boolean";
    public static final String FLOAT = "Float";
    public static final String DECIMAL = "Decimal";
    public static final String QUERY = "Query";

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

    public static String getResourceName(ResourceMethodType resourceMethod) {
        String[] nameArray = resourceMethod.getResourcePath();
        int nameIndex = nameArray.length;
        return nameArray[nameIndex - 1];
    }

    static BMap<BString, Object> getSchemaRecordFromSchema(Schema schema) {
        BMap<BString, Object> schemaRecord = ValueCreator.createRecordValue(getModule(), SCHEMA_RECORD);
        BMap<BString, Object> types = getTypeRecordMapFromSchema(schema.getTypes());
        schemaRecord.put(TYPES_FIELD, types);
        schemaRecord.put(QUERY_TYPE_FIELD, getTypeRecordFromTypeObject(schema.getQueryType()));
        return schemaRecord;
    }

    private static BMap<BString, Object> getTypeRecordMapFromSchema(Map<String, SchemaType> types) {
        BMap<BString, Object> typeRecord = ValueCreator.createRecordValue(getModule(), TYPE_RECORD);
        MapType typesMapType = TypeCreator.createMapType(typeRecord.getType());
        BMap<BString, Object> typesMap = ValueCreator.createMapValue(typesMapType);
        for (SchemaType type : types.values()) {
            typesMap.put(StringUtils.fromString(type.getName()), getTypeRecordFromTypeObject(type));
        }
        return typesMap;
    }

    static BMap<BString, Object> getTypeRecordFromTypeObject(SchemaType typeObject) {
        if (typeObject == null) {
            return null;
        }
        BMap<BString, Object> typeRecord = ValueCreator.createRecordValue(getModule(), TYPE_RECORD);
        typeRecord.put(KIND_FIELD, StringUtils.fromString(typeObject.getKind().toString()));
        typeRecord.put(NAME_FIELD, StringUtils.fromString(typeObject.getName()));
        Collection<SchemaField> fields = typeObject.getFields();
        if (fields != null && fields.size() > 0) {
            typeRecord.put(FIELDS_FIELD, getFieldArrayFromFields(fields));
        }
        List<Object> enumValues = typeObject.getEnumValues();
        if (enumValues != null && enumValues.size() > 0) {
            typeRecord.put(ENUM_VALUES_FIELD, getEnumValuesMapFromEnumValues(enumValues));
        }
        SchemaType ofType = typeObject.getOfType();
        if (ofType != null) {
            typeRecord.put(OF_TYPE_FIELD, getTypeRecordFromTypeObject(ofType));
        }
        return typeRecord;
    }

    private static BArray getFieldArrayFromFields(Collection<SchemaField> fields) {
        BMap<BString, Object> fieldRecord = ValueCreator.createRecordValue(getModule(), FIELD_RECORD);
        ArrayType arrayType = TypeCreator.createArrayType(fieldRecord.getType());
        BArray fieldArray = ValueCreator.createArrayValue(arrayType);

        for (SchemaField field : fields) {
            fieldArray.append(getFieldRecordFromObject(field));
        }
        return fieldArray;
    }

    private static BArray getEnumValuesMapFromEnumValues(List<Object> enumValues) {
        Type elementType = ValueCreator.createRecordValue(getModule(), ENUM_VALUE_RECORD).getType();
        BArray result = ValueCreator.createArrayValue(TypeCreator.createArrayType(elementType));
        for (Object value : enumValues) {
            BMap<BString, Object> enumRecord = ValueCreator.createRecordValue(getModule(), ENUM_VALUE_RECORD);
            enumRecord.put(NAME_FIELD, value);
            result.append(enumRecord);
        }
        return result;
    }

    private static BMap<BString, Object> getFieldRecordFromObject(SchemaField fieldObject) {
        BMap<BString, Object> fieldRecord = ValueCreator.createRecordValue(getModule(), FIELD_RECORD);
        fieldRecord.put(NAME_FIELD, StringUtils.fromString(fieldObject.getName()));
        SchemaType type = fieldObject.getType();
        if (type != null) {
            fieldRecord.put(TYPE_FIELD, getTypeRecordFromTypeObject(type));
        } else {
            fieldRecord.put(TYPE_FIELD, getTypeRecordFromTypeObject(createNonNullType()));
        }
        List<InputValue> args = fieldObject.getArgs();
        if (args != null && args.size() > 0) {
            fieldRecord.put(ARGS_FIELD, getInputMapFromInputs(args));
        }
        return fieldRecord;
    }

    private static BMap<BString, Object> getInputMapFromInputs(List<InputValue> inputValues) {
        BMap<BString, Object> inputValueRecord = ValueCreator.createRecordValue(getModule(), INPUT_VALUE_RECORD);
        MapType inputValueRecordMapType = TypeCreator.createMapType(inputValueRecord.getType());
        BMap<BString, Object> inputValueRecordMap = ValueCreator.createMapValue(inputValueRecordMapType);

        for (InputValue inputValue : inputValues) {
            BMap<BString, Object> inputRecord = getInputRecordFromObject(inputValue);
            inputValueRecordMap.put(StringUtils.fromString(inputValue.getName()), inputRecord);
        }
        return inputValueRecordMap;
    }

    private static BMap<BString, Object> getInputRecordFromObject(InputValue inputValue) {
        BMap<BString, Object> inputValueRecord = ValueCreator.createRecordValue(getModule(), INPUT_VALUE_RECORD);
        inputValueRecord.put(NAME_FIELD, StringUtils.fromString(inputValue.getName()));
        inputValueRecord.put(TYPE_FIELD, getTypeRecordFromTypeObject(inputValue.getType()));
        if (Objects.nonNull(inputValue.getDefaultValue())) {
            inputValueRecord.put(DEFAULT_VALUE_FIELD, StringUtils.fromString(inputValue.getDefaultValue()));
        }
        return inputValueRecord;
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

    private static SchemaType createNonNullType() {
        return new SchemaType(null, TypeKind.NON_NULL);
    }

    static boolean isScalarType(Type type) {
        int tag = type.getTag();
        return tag == INT_TAG || tag == FLOAT_TAG || tag == BOOLEAN_TAG || tag == STRING_TAG;
    }
}
