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
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.ResourceFunctionType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.graphql.schema.InputValue;
import io.ballerina.stdlib.graphql.schema.Schema;
import io.ballerina.stdlib.graphql.schema.SchemaField;
import io.ballerina.stdlib.graphql.schema.SchemaType;
import io.ballerina.stdlib.graphql.schema.TypeKind;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import static io.ballerina.runtime.api.TypeTags.BOOLEAN_TAG;
import static io.ballerina.runtime.api.TypeTags.FLOAT_TAG;
import static io.ballerina.runtime.api.TypeTags.INT_TAG;
import static io.ballerina.runtime.api.TypeTags.RECORD_TYPE_TAG;
import static io.ballerina.runtime.api.TypeTags.SERVICE_TAG;
import static io.ballerina.runtime.api.TypeTags.STRING_TAG;

/**
 * This class provides utility functions for Ballerina GraphQL engine.
 */
public class Utils {

    private Utils() {}

    // Schema related record types
    public static final String SCHEMA_RECORD = "__Schema";
    public static final String FIELD_RECORD = "__Field";
    public static final String TYPE_RECORD = "__Type";
    public static final String INPUT_VALUE_RECORD = "__InputValue";

    // Schema related record field names
    private static final BString QUERY_TYPE_FIELD = StringUtils.fromString("queryType");
    private static final BString TYPES_FIELD = StringUtils.fromString("types");
    private static final BString TYPE_FIELD = StringUtils.fromString("type");
    static final BString NAME_FIELD = StringUtils.fromString("name");
    private static final BString KIND_FIELD = StringUtils.fromString("kind");
    private static final BString FIELDS_FIELD = StringUtils.fromString("fields");
    private static final BString ARGS_FIELD = StringUtils.fromString("args");
    private static final BString DEFAULT_VALUE_FIELD = StringUtils.fromString("defaultValue");

    // Schema related type names
    // TODO: Make these values "graphql-specific" names
    static final String INTEGER = "int";
    static final String STRING = "string";
    static final String BOOLEAN = "boolean";
    static final String FLOAT = "float";
    static final String ID = "id";
    static final String QUERY = "Query";

    // Visitor object fields
    static final BString SERVICE_TYPE_FIELD = StringUtils.fromString("serviceType");
    static final BString ERRORS_FIELD = StringUtils.fromString("errors");

    // Inter-op function names
    static final String EXECUTE_SINGLE_RESOURCE_FUNCTION = "executeSingleResource";

    // Record Types
    static final String LOCATION_RECORD = "Location";
    static final String ERROR_DETAIL_RECORD = "ErrorDetail";
    static final String DATA_RECORD = "Data";

    // Record fields
    static final BString LOCATION_FIELD = StringUtils.fromString("location");
    static final BString LOCATIONS_FIELD = StringUtils.fromString("locations");
    static final BString MESSAGE_FIELD = StringUtils.fromString("message");
    static final BString SELECTIONS_FIELD = StringUtils.fromString("selections");


    static void addQueryFieldsForServiceType(ServiceType serviceType, SchemaType schemaType, Schema schema) {
        ResourceFunctionType[] resourceFunctions = serviceType.getResourceFunctions();
        for (ResourceFunctionType resourceFunction : resourceFunctions) {
            schemaType.addField(getFieldForResource(resourceFunction, schema));
        }
    }

    private static SchemaField getFieldForResource(ResourceFunctionType resourceFunction, Schema schema) {
        String fieldName = getResourceName(resourceFunction);
        // TODO: Check accessor: Only get allowed
        SchemaField field = new SchemaField(fieldName, resourceFunction.getType().getReturnParameterType().getTag());
        addArgsToField(field, resourceFunction, schema);
        field.setType(getSchemaTypeForBalType(resourceFunction.getType().getReturnParameterType(), schema));
        return field;
    }

    static String getResourceName(ResourceFunctionType resourceFunction) {
        String[] nameArray = resourceFunction.getResourcePath();
        int nameIndex = nameArray.length;
        return nameArray[nameIndex - 1];
    }

    // TODO: Simplify
    static SchemaType getSchemaTypeForBalType(Type type, Schema schema) {
        int tag = type.getTag();
        if (schema.getType(type.getName()) != null) {
            return schema.getType(type.getName());
        }
        if (tag == INT_TAG) {
            SchemaType schemaType = new SchemaType(INTEGER, TypeKind.SCALAR);
            schema.addType(schemaType);
            return schemaType;
        } else if (tag == STRING_TAG) {
            SchemaType schemaType = new SchemaType(STRING, TypeKind.SCALAR);
            schema.addType(schemaType);
            return schemaType;
        } else if (tag == BOOLEAN_TAG) {
            SchemaType schemaType = new SchemaType(BOOLEAN, TypeKind.SCALAR);
            schema.addType(schemaType);
            return schemaType;
        } else if (tag == FLOAT_TAG) {
            SchemaType schemaType = new SchemaType(FLOAT, TypeKind.SCALAR);
            schema.addType(schemaType);
            return schemaType;
        } else if (tag == RECORD_TYPE_TAG) {
            RecordType record = (RecordType) type;
            SchemaType fieldType = new SchemaType(record.getName(), TypeKind.OBJECT);
            Collection<Field> recordFields = record.getFields().values();
            for (Field recordField : recordFields) {
                SchemaField field = new SchemaField(recordField.getFieldName(), tag);
                field.setType(getSchemaTypeForBalType(recordField.getFieldType(), schema));
                fieldType.addField(field);
            }
            schema.addType(fieldType);
            return fieldType;
        } else if (tag == SERVICE_TAG) {
            ServiceType service = (ServiceType) type;
            SchemaType fieldType = new SchemaType(service.getName(), TypeKind.OBJECT);
            addQueryFieldsForServiceType(service, fieldType, schema);
            schema.addType(fieldType);
            return fieldType;
        } else {
            // TODO: Fix this to return an error
            return new SchemaType(ID, TypeKind.SCALAR);
        }
    }

    private static void addArgsToField(SchemaField field, ResourceFunctionType resourceFunction, Schema schema) {
        Type[] parameterTypes = resourceFunction.getParameterTypes();
        String[] parameterNames = resourceFunction.getParamNames();

        if (parameterNames.length == 0) {
            return;
        }
        // TODO: Handle default values (https://github.com/ballerina-platform/ballerina-lang/issues/27417)
        for (int i = 0; i < parameterNames.length; i++) {
            field.addArg(getInputValue(parameterNames[i], parameterTypes[i], schema));
        }
    }

    private static InputValue getInputValue(String name, Type type, Schema schema) {
        SchemaType inputType = getSchemaTypeForBalType(type, schema);
        // TODO: Handle record fields. Records can't be inputs yet
        return new InputValue(name, inputType);
    }

    static BMap<BString, Object> getSchemaRecordFromSchema(Environment environment, Schema schema) {
        Module module = environment.getCurrentModule();
        BMap<BString, Object> schemaRecord = ValueCreator.createRecordValue(module, SCHEMA_RECORD);
        BMap<BString, Object> types = getTypeRecordMapFromSchema(module, schema.getTypes());
        schemaRecord.put(TYPES_FIELD, types);
        schemaRecord.put(QUERY_TYPE_FIELD, getTypeRecordFromTypeObject(module, schema.getQueryType()));
        return schemaRecord;
    }

    // TODO: Can we re-use the same type record, when needed?
    private static BMap<BString, Object> getTypeRecordMapFromSchema(Module module, Map<String, SchemaType> types) {
        BMap<BString, Object> typeRecord = ValueCreator.createRecordValue(module, TYPE_RECORD);
        MapType typesMapType = TypeCreator.createMapType(typeRecord.getType());
        BMap<BString, Object> typesMap = ValueCreator.createMapValue(typesMapType);
        for (SchemaType type : types.values()) {
            typesMap.put(StringUtils.fromString(type.getName()), getTypeRecordFromTypeObject(module, type));
        }
        return typesMap;
    }

    static BMap<BString, Object> getTypeRecordFromTypeObject(Module module, SchemaType typeObject) {
        BMap<BString, Object> typeRecord = ValueCreator.createRecordValue(module, TYPE_RECORD);
        typeRecord.put(KIND_FIELD, StringUtils.fromString(typeObject.getKind().toString()));
        typeRecord.put(NAME_FIELD, StringUtils.fromString(typeObject.getName()));
        typeRecord.put(FIELDS_FIELD, getFieldMapFromFields(module, typeObject.getFields()));
        return typeRecord;
    }

    private static BMap<BString, Object> getFieldMapFromFields(Module module, List<SchemaField> fields) {
        BMap<BString, Object> fieldRecord = ValueCreator.createRecordValue(module, FIELD_RECORD);
        MapType fieldRecordMapType = TypeCreator.createMapType(fieldRecord.getType());
        BMap<BString, Object> fieldRecordMap = ValueCreator.createMapValue(fieldRecordMapType);

        for (SchemaField field : fields) {
            fieldRecordMap.put(StringUtils.fromString(field.getName()), getFieldRecordFromObject(module, field));
        }
        return fieldRecordMap;
    }

    private static BMap<BString, Object> getFieldRecordFromObject(Module module, SchemaField fieldObject) {
        BMap<BString, Object> fieldRecord = ValueCreator.createRecordValue(module, FIELD_RECORD);
        fieldRecord.put(NAME_FIELD, StringUtils.fromString(fieldObject.getName()));
        fieldRecord.put(TYPE_FIELD, getTypeRecordFromTypeObject(module, fieldObject.getType()));
        fieldRecord.put(ARGS_FIELD, getInputMapFromInputs(module, fieldObject.getArgs()));
        return fieldRecord;
    }

    private static BMap<BString, Object> getInputMapFromInputs(Module module, List<InputValue> inputValues) {
        BMap<BString, Object> inputValueRecord = ValueCreator.createRecordValue(module, INPUT_VALUE_RECORD);
        MapType inputValueRecordMapType = TypeCreator.createMapType(inputValueRecord.getType());
        BMap<BString, Object> inputValueRecordMap = ValueCreator.createMapValue(inputValueRecordMapType);

        for (InputValue inputValue : inputValues) {
            BMap<BString, Object> inputRecord = getInputRecordFromObject(module, inputValue);
            inputValueRecordMap.put(StringUtils.fromString(inputValue.getName()), inputRecord);
        }
        return inputValueRecordMap;
    }

    private static BMap<BString, Object> getInputRecordFromObject(Module module, InputValue inputValue) {
        BMap<BString, Object> inputValueRecord = ValueCreator.createRecordValue(module, INPUT_VALUE_RECORD);
        inputValueRecord.put(NAME_FIELD, StringUtils.fromString(inputValue.getName()));
        inputValueRecord.put(TYPE_FIELD, getTypeRecordFromTypeObject(module, inputValue.getType()));
        if (Objects.nonNull(inputValue.getDefaultValue())) {
            inputValueRecord.put(DEFAULT_VALUE_FIELD, StringUtils.fromString(inputValue.getDefaultValue()));
        }
        return inputValueRecord;
    }

    static BMap<BString, Object> getErrorDetailRecord(Module module, BError error, BObject fieldNode) {
        BMap<BString, Object> location = fieldNode.getMapValue(LOCATION_FIELD);
        ArrayType locationsArrayType = TypeCreator.createArrayType(location.getType());
        BArray locations = ValueCreator.createArrayValue(locationsArrayType);
        locations.append(location);
        BMap<BString, Object> errorDetail = ValueCreator.createRecordValue(module, ERROR_DETAIL_RECORD);
        errorDetail.put(MESSAGE_FIELD, StringUtils.fromString(error.getMessage()));
        errorDetail.put(LOCATIONS_FIELD, locations);
        return errorDetail;
    }
}
