/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.graphql.runtime.schema;

import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ARGS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.DEFAULT_VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ENUM_VALUES_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ENUM_VALUE_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FIELDS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FIELD_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.INPUT_VALUE_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.KIND_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.OF_TYPE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.POSSIBLE_TYPES_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.QUERY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.QUERY_TYPE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SCHEMA_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.TYPES_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.TYPE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.TYPE_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.getArrayTypeFromBMap;
import static io.ballerina.stdlib.graphql.runtime.utils.ModuleUtils.getModule;

/**
 * This class is used to generate a Ballerina {@code __Schema} record from the {@code Schema} object.
 */
public class SchemaRecordGenerator {
    private final Schema schema;
    private Map<String, BMap<BString, Object>> typeRecords;

    public SchemaRecordGenerator(Schema schema) {
        this.schema = schema;
        this.typeRecords = new HashMap<>();
        this.populateTypeRecordMap();
        this.populateFieldsOfTypes();
    }

    public BMap<BString, Object> getSchemaRecord() {
        BMap<BString, Object> schemaRecord = ValueCreator.createRecordValue(getModule(), SCHEMA_RECORD);
        Type typeRecordType = ValueCreator.createRecordValue(getModule(), TYPE_RECORD).getType();
        BMap<BString, Object> typesMap = ValueCreator.createMapValue(typeRecordType);
        for (String typeName : this.typeRecords.keySet()) {
            typesMap.put(StringUtils.fromString(typeName), this.typeRecords.get(typeName));
        }
        schemaRecord.put(TYPES_FIELD, typesMap);
        schemaRecord.put(QUERY_TYPE_FIELD, this.typeRecords.get(QUERY));
        return schemaRecord;
    }

    private void populateTypeRecordMap() {
        for (SchemaType schemaType : this.schema.getTypes().values()) {
            BMap<BString, Object> typeRecord = ValueCreator.createRecordValue(getModule(), TYPE_RECORD);
            typeRecord.put(NAME_FIELD, StringUtils.fromString(schemaType.getName()));
            typeRecord.put(KIND_FIELD, StringUtils.fromString(schemaType.getKind().toString()));
            this.typeRecords.put(schemaType.getName(), typeRecord);
        }
    }

    private void populateFieldsOfTypes() {
        for (SchemaType schemaType : this.schema.getTypes().values()) {
            if (schemaType.getKind() == TypeKind.OBJECT) {
                BMap<BString, Object> typeRecord = this.typeRecords.get(schemaType.getName());
                typeRecord.put(FIELDS_FIELD, getFieldsArray(schemaType));
            }
        }
    }

    // TODO: Optimize
    private BMap<BString, Object> getTypeRecord(SchemaType schemaType) {
        BMap<BString, Object> typeRecord;
        if (this.typeRecords.containsKey(schemaType.getName())) {
            typeRecord = this.typeRecords.get(schemaType.getName());
        } else {
            typeRecord = ValueCreator.createRecordValue(getModule(), TYPE_RECORD);
            typeRecord.put(NAME_FIELD, StringUtils.fromString(schemaType.getName()));
            typeRecord.put(KIND_FIELD, StringUtils.fromString(schemaType.getKind().toString()));
        }
        if (schemaType.getKind() == TypeKind.LIST || schemaType.getKind() == TypeKind.NON_NULL) {
            typeRecord.put(OF_TYPE_FIELD, getTypeRecord(schemaType.getOfType()));
        } else if (schemaType.getKind() == TypeKind.UNION) {
            typeRecord.put(POSSIBLE_TYPES_FIELD, getPossibleTypesArray(schemaType));
        } else if (schemaType.getKind() == TypeKind.ENUM) {
            typeRecord.put(ENUM_VALUES_FIELD, getEnumValuesArray(schemaType));
        }
        return typeRecord;
    }

    private BArray getEnumValuesArray(SchemaType schemaType) {
        BArray enumValuesArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), ENUM_VALUE_RECORD));
        for (Object enumValue : schemaType.getEnumValues()) {
            BMap<BString, Object> enumValueRecord = ValueCreator.createRecordValue(getModule(), ENUM_VALUE_RECORD);
            enumValueRecord.put(NAME_FIELD, enumValue);
            enumValuesArray.append(enumValueRecord);
        }
        return enumValuesArray;
    }

    private BArray getPossibleTypesArray(SchemaType schemaType) {
        BArray possibleTypesArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), TYPE_RECORD));
        for (SchemaType possibleType : schemaType.getPossibleTypes()) {
            possibleTypesArray.append(getTypeRecord(possibleType));
        }
        return possibleTypesArray;
    }

    private BArray getFieldsArray(SchemaType schemaType) {
        BArray fieldsArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), FIELD_RECORD));
        for (SchemaField schemaField : schemaType.getFields()) {
            fieldsArray.append(getFieldRecord(schemaField));
        }
        return fieldsArray;
    }

    private BMap<BString, Object> getFieldRecord(SchemaField schemaField) {
        BMap<BString, Object> fieldRecord = ValueCreator.createRecordValue(getModule(), FIELD_RECORD);
        fieldRecord.put(NAME_FIELD, StringUtils.fromString(schemaField.getName()));
        fieldRecord.put(TYPE_FIELD, getTypeRecord(schemaField.getType()));
        fieldRecord.put(ARGS_FIELD, getInputValueArray(schemaField));
        return fieldRecord;
    }

    private BArray getInputValueArray(SchemaField schemaField) {
        if (schemaField.getArgs().size() == 0) {
            return null;
        }
        BArray inputValueArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), INPUT_VALUE_RECORD));
        for (InputValue inputValue : schemaField.getArgs()) {
            inputValueArray.append(getInputValueRecordFromInputValue(inputValue));
        }
        return inputValueArray;
    }

    private BMap<BString, Object> getInputValueRecordFromInputValue(InputValue inputValue) {
        BMap<BString, Object> inputValueRecord = ValueCreator.createRecordValue(getModule(), INPUT_VALUE_RECORD);
        inputValueRecord.put(NAME_FIELD, StringUtils.fromString(inputValue.getName()));
        inputValueRecord.put(TYPE_FIELD, getTypeRecord(inputValue.getType()));
        if (Objects.nonNull(inputValue.getDefaultValue())) {
            inputValueRecord.put(DEFAULT_VALUE_FIELD, StringUtils.fromString(inputValue.getDefaultValue()));
        }
        return inputValueRecord;
    }

    private SchemaType getOfType(SchemaType schemaType) {
        if (schemaType.getOfType() != null) {
            return getOfType(schemaType.getOfType());
        }
        return schemaType;
    }
}
