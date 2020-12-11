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

import io.ballerina.runtime.api.async.StrandMetadata;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.ResourceFunctionType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
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
import static io.ballerina.runtime.api.constants.RuntimeConstants.BALLERINA_BUILTIN_PKG_PREFIX;
import static io.ballerina.stdlib.graphql.utils.Utils.MODULE_NAME;
import static io.ballerina.stdlib.graphql.utils.Utils.MODULE_VERSION;
import static io.ballerina.stdlib.graphql.utils.Utils.PACKAGE_ID;

/**
 * This class provides utility functions for Ballerina GraphQL engine.
 */
public class Utils {

    // Schema related record types
    public static final String SCHEMA_RECORD = "__Schema";
    public static final String FIELD_RECORD = "__Field";
    public static final String TYPE_RECORD = "__Type";
    public static final String INPUT_VALUE_RECORD = "__InputValue";
    public static final String OUTPUT_OBJECT_RECORD = "OutputObject";
    public static final String DATA_RECORD = "Data";
    public static final String ERROR_DETAIL_RECORD = "ErrorDetail";
    public static final String LOCATION_RECORD = "Location";

    public static final String RUNTIME_ERROR = "RuntimeError";

    // Schema related record field names
    private static final BString QUERY_TYPE_FIELD = StringUtils.fromString("queryType");
    private static final BString TYPES_FIELD = StringUtils.fromString("types");
    private static final BString TYPE_FIELD = StringUtils.fromString("type");
    static final BString NAME_FIELD = StringUtils.fromString("name");
    private static final BString KIND_FIELD = StringUtils.fromString("kind");
    private static final BString FIELDS_FIELD = StringUtils.fromString("fields");
    private static final BString ARGS_FIELD = StringUtils.fromString("args");
    private static final BString DEFAULT_VALUE_FIELD = StringUtils.fromString("defaultValue");
    private static final BString RETURN_TYPE_FIELD = StringUtils.fromString("returnType");
    private static final BString MESSAGE_FIELD = StringUtils.fromString("message");
    private static final BString LOCATION_FIELD = StringUtils.fromString("location");
    private static final BString LOCATIONS_FIELD = StringUtils.fromString("locations");
    static final BString DATA_FIELD = StringUtils.fromString("data");
    static final BString ERRORS_FIELD = StringUtils.fromString("errors");

    // Schema related constants
    private static final BString VALUE_OBJECT = StringUtils.fromString("OBJECT");

    // Schema related type names
    static final String INTEGER = "int";
    static final String STRING = "string";
    static final String BOOLEAN = "boolean";
    static final String FLOAT = "float";
    static final String ID = "id";

    // Field return types
    static final BString PRIMITIVE = StringUtils.fromString("PRIMITIVE");
    static final BString RECORD = StringUtils.fromString("RECORD");
    static final BString SERVICE = StringUtils.fromString("SERVICE");

    // Visitor object fields
    static final BString SERVICE_TYPE_FIELD = StringUtils.fromString("serviceType");
    static final BString OUTPUT_OBJECT_FIELD = StringUtils.fromString("outputObject");
    static final BString SELECTIONS_FIELD = StringUtils.fromString("selections");
    static final BString FIELD_TYPE_FIELD = StringUtils.fromString("fieldType");

    // Inter-op function names
    static final String EXECUTE_RESOURCE_FUNCTION = "executeResources";
    static final String EXECUTE_SINGLE_RESOURCE_FUNCTION = "executeSingleResource";


    public static final StrandMetadata EXECUTE_RESOURCE_METADATA =
            new StrandMetadata(BALLERINA_BUILTIN_PKG_PREFIX, MODULE_NAME, MODULE_VERSION, EXECUTE_RESOURCE_FUNCTION);
    public static final StrandMetadata EXECUTE_SINGLE_RESOURCE_METADATA =
            new StrandMetadata(BALLERINA_BUILTIN_PKG_PREFIX, MODULE_NAME, MODULE_VERSION, EXECUTE_RESOURCE_FUNCTION);

    static void addQueryFieldsForServiceType(ServiceType serviceType, SchemaType schemaType, Schema schema) {
        ResourceFunctionType[] resourceFunctions = serviceType.getResourceFunctions();
        for (ResourceFunctionType resourceFunction : resourceFunctions) {
            schemaType.addField(getFieldForResource(resourceFunction, schema));
        }
    }

    private static SchemaField getFieldForResource(ResourceFunctionType resourceFunction, Schema schema) {
        String fieldName = getResourceName(resourceFunction);
        // TODO: Check accessor: Only get allowed
        SchemaField field = new SchemaField(fieldName, resourceFunction.getReturnParameterType().getTag());
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

    static BMap<BString, Object> getSchemaRecordFromSchema(Schema schema) {
        BMap<BString, Object> schemaRecord = ValueCreator.createRecordValue(PACKAGE_ID, SCHEMA_RECORD);
        BMap<BString, Object> types = getTypeRecordMapFromSchema(schema.getTypes());
        schemaRecord.put(TYPES_FIELD, types);
        schemaRecord.put(QUERY_TYPE_FIELD, getTypeRecordFromTypeObject(schema.getQueryType()));
        return schemaRecord;
    }

    // TODO: Can we re-use the same type record, when needed?
    private static BMap<BString, Object> getTypeRecordMapFromSchema(Map<String, SchemaType> types) {
        BMap<BString, Object> typeRecord = ValueCreator.createRecordValue(PACKAGE_ID, TYPE_RECORD);
        MapType typesMapType = TypeCreator.createMapType(typeRecord.getType());
        BMap<BString, Object> typesMap = ValueCreator.createMapValue(typesMapType);
        for (SchemaType type : types.values()) {
            typesMap.put(StringUtils.fromString(type.getName()), getTypeRecordFromTypeObject(type));
        }
        return typesMap;
    }

    static BMap<BString, Object> getTypeRecordFromTypeObject(SchemaType typeObject) {
        BMap<BString, Object> typeRecord = ValueCreator.createRecordValue(PACKAGE_ID, TYPE_RECORD);
        typeRecord.put(KIND_FIELD, StringUtils.fromString(typeObject.getKind().toString()));
        typeRecord.put(NAME_FIELD, StringUtils.fromString(typeObject.getName()));
        typeRecord.put(FIELDS_FIELD, getFieldMapFromFields(typeObject.getFields()));
        return typeRecord;
    }

    private static BMap<BString, Object> getFieldMapFromFields(List<SchemaField> fields) {
        BMap<BString, Object> fieldRecord = ValueCreator.createRecordValue(PACKAGE_ID, FIELD_RECORD);
        MapType fieldRecordMapType = TypeCreator.createMapType(fieldRecord.getType());
        BMap<BString, Object> fieldRecordMap = ValueCreator.createMapValue(fieldRecordMapType);

        for (SchemaField field : fields) {
            fieldRecordMap.put(StringUtils.fromString(field.getName()), getFieldRecordFromObject(field));
        }
        return fieldRecordMap;
    }

    private static BMap<BString, Object> getFieldRecordFromObject(SchemaField fieldObject) {
        BMap<BString, Object> fieldRecord = ValueCreator.createRecordValue(PACKAGE_ID, FIELD_RECORD);
        fieldRecord.put(NAME_FIELD, StringUtils.fromString(fieldObject.getName()));
        fieldRecord.put(TYPE_FIELD, getTypeRecordFromTypeObject(fieldObject.getType()));
        fieldRecord.put(ARGS_FIELD, getInputMapFromInputs(fieldObject.getArgs()));
        fieldRecord.put(RETURN_TYPE_FIELD, getTypeFromTag(fieldObject.getTypeTag()));
        return fieldRecord;
    }

    private static BMap<BString, Object> getInputMapFromInputs(List<InputValue> inputValues) {
        BMap<BString, Object> inputValueRecord = ValueCreator.createRecordValue(PACKAGE_ID, INPUT_VALUE_RECORD);
        MapType inputValueRecordMapType = TypeCreator.createMapType(inputValueRecord.getType());
        BMap<BString, Object> inputValueRecordMap = ValueCreator.createMapValue(inputValueRecordMapType);

        for (InputValue inputValue : inputValues) {
            inputValueRecordMap.put(StringUtils.fromString(inputValue.getName()), getInputRecordFromObject(inputValue));
        }
        return inputValueRecordMap;
    }

    private static BMap<BString, Object> getInputRecordFromObject(InputValue inputValue) {
        BMap<BString, Object> inputValueRecord = ValueCreator.createRecordValue(PACKAGE_ID, INPUT_VALUE_RECORD);
        inputValueRecord.put(NAME_FIELD, StringUtils.fromString(inputValue.getName()));
        inputValueRecord.put(TYPE_FIELD, getTypeRecordFromTypeObject(inputValue.getType()));
        if (Objects.nonNull(inputValue.getDefaultValue())) {
            inputValueRecord.put(DEFAULT_VALUE_FIELD, StringUtils.fromString(inputValue.getDefaultValue()));
        }
        return inputValueRecord;
    }

    static BMap<BString, Object> getOutputObject() {
        BMap<BString, Object> outputObject = ValueCreator.createRecordValue(PACKAGE_ID, OUTPUT_OBJECT_RECORD);
        outputObject.put(DATA_FIELD, getDataRecord());
        outputObject.put(ERRORS_FIELD, getErrorDetailArray());
        return outputObject;
    }

    static BMap<BString, Object> getDataRecord() {
        return ValueCreator.createRecordValue(PACKAGE_ID, DATA_RECORD);
    }

    static BArray getErrorDetailArray() {
        BMap<BString, Object> errorDetail = ValueCreator.createRecordValue(PACKAGE_ID, ERROR_DETAIL_RECORD);
        return ValueCreator.createArrayValue(TypeCreator.createArrayType(errorDetail.getType()));
    }

    static BMap<BString, Object> getErrorDetailRecord(BString message, BObject fieldNode) {
        BMap<BString, Object> errorDetail = ValueCreator.createRecordValue(PACKAGE_ID, ERROR_DETAIL_RECORD);
        errorDetail.put(MESSAGE_FIELD, message);
        errorDetail.put(LOCATIONS_FIELD, getLocationArrayFromNode(fieldNode));
        return errorDetail;
    }

    private static BArray getLocationArrayFromNode(BObject node) {
        BMap<BString, Object> location = node.getMapValue(LOCATION_FIELD);
        BMap<BString, Object> locationRecord = ValueCreator.createRecordValue(PACKAGE_ID, LOCATION_RECORD);
        BArray locationArray = ValueCreator.createArrayValue(TypeCreator.createArrayType(locationRecord.getType()));
        locationArray.append(location);
        return locationArray;
    }

    static BString getTypeFromTag(int tag) {
        switch (tag) {
            case RECORD_TYPE_TAG:
                return RECORD;
            case SERVICE_TAG:
                return SERVICE;
            default:
                return PRIMITIVE;
        }
    }
}
