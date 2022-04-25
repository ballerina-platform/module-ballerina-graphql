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
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.graphql.compiler.schema.types.Field;
import io.ballerina.stdlib.graphql.compiler.schema.types.InputValue;
import io.ballerina.stdlib.graphql.compiler.schema.types.Schema;
import io.ballerina.stdlib.graphql.compiler.schema.types.Type;
import io.ballerina.stdlib.graphql.compiler.schema.types.TypeKind;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ARGS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.DEFAULT_VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ENUM_VALUES_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ENUM_VALUE_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FIELDS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FIELD_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.INPUT_FIELDS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.INPUT_VALUE_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.INTERFACES_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.KIND_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.MUTATION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.MUTATION_TYPE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.OF_TYPE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.POSSIBLE_TYPES_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.QUERY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.QUERY_TYPE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SCHEMA_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SUBSCRIPTION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SUBSCRIPTION_TYPE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.TYPES_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.TYPE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.TYPE_RECORD;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.getArrayTypeFromBMap;
import static io.ballerina.stdlib.graphql.runtime.utils.ModuleUtils.getModule;

/**
 * This class is used to generate a Ballerina {@code __Schema} record from the {@code Schema} object.
 */
public class SchemaRecordGenerator {
    private final Schema schema;
    private final Map<String, BMap<BString, Object>> typeRecords;

    public SchemaRecordGenerator(Schema schema) {
        this.schema = schema;
        this.typeRecords = new HashMap<>();
        this.populateTypeRecordMap();
        this.populateFieldsOfTypes();
    }

    public BMap<BString, Object> getSchemaRecord() {
        BMap<BString, Object> schemaRecord = ValueCreator.createRecordValue(getModule(), SCHEMA_RECORD);
        BArray typesArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), TYPE_RECORD));
        for (BMap<BString, Object> typeRecord : this.typeRecords.values()) {
            typesArray.append(typeRecord);
        }
        schemaRecord.put(TYPES_FIELD, typesArray);
        schemaRecord.put(QUERY_TYPE_FIELD, this.typeRecords.get(QUERY));
        if (this.typeRecords.containsKey(MUTATION)) {
            schemaRecord.put(MUTATION_TYPE_FIELD, this.typeRecords.get(MUTATION));
        }
        if (this.typeRecords.containsKey(SUBSCRIPTION)) {
            schemaRecord.put(SUBSCRIPTION_TYPE_FIELD, this.typeRecords.get(SUBSCRIPTION));
        }
        return schemaRecord;
    }

    private void populateTypeRecordMap() {
        for (Type type : this.schema.getTypes().values()) {
            BMap<BString, Object> typeRecord = ValueCreator.createRecordValue(getModule(), TYPE_RECORD);
            typeRecord.put(NAME_FIELD, StringUtils.fromString(type.getName()));
            typeRecord.put(KIND_FIELD, StringUtils.fromString(type.getKind().toString()));
            if (type.getKind() == TypeKind.OBJECT) {
                typeRecord.put(INTERFACES_FIELD, getInterfacesArray());
            }
            this.typeRecords.put(type.getName(), typeRecord);
        }
    }

    private void populateFieldsOfTypes() {
        for (Type type : this.schema.getTypes().values()) {
            if (type.getKind() == TypeKind.OBJECT) {
                BMap<BString, Object> typeRecord = this.typeRecords.get(type.getName());
                typeRecord.put(FIELDS_FIELD, getFieldsArray(type));
            } else if (type.getKind() == TypeKind.INPUT_OBJECT) {
                BMap<BString, Object> typeRecord = this.typeRecords.get(type.getName());
                typeRecord.put(INPUT_FIELDS_FIELD, getInputFieldsArray(type));
            }
        }
    }

    private BMap<BString, Object> getTypeRecord(Type type) {
        BMap<BString, Object> typeRecord;
        if (this.typeRecords.containsKey(type.getName())) {
            typeRecord = this.typeRecords.get(type.getName());
        } else {
            typeRecord = ValueCreator.createRecordValue(getModule(), TYPE_RECORD);
            typeRecord.put(NAME_FIELD, StringUtils.fromString(type.getName()));
            typeRecord.put(KIND_FIELD, StringUtils.fromString(type.getKind().toString()));
        }
        if (type.getKind() == TypeKind.LIST || type.getKind() == TypeKind.NON_NULL) {
            typeRecord.put(OF_TYPE_FIELD, getTypeRecord(type.getOfType()));
        } else if (type.getKind() == TypeKind.UNION) {
            typeRecord.put(POSSIBLE_TYPES_FIELD, getPossibleTypesArray(type));
        } else if (type.getKind() == TypeKind.ENUM) {
            typeRecord.put(ENUM_VALUES_FIELD, getEnumValuesArray(type));
        }
        return typeRecord;
    }

    private BArray getEnumValuesArray(Type type) {
        BArray enumValuesArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), ENUM_VALUE_RECORD));
        for (Object enumValue : type.getEnumValues()) {
            BMap<BString, Object> enumValueRecord = ValueCreator.createRecordValue(getModule(), ENUM_VALUE_RECORD);
            enumValueRecord.put(NAME_FIELD, enumValue);
            enumValuesArray.append(enumValueRecord);
        }
        return enumValuesArray;
    }

    private BArray getPossibleTypesArray(Type type) {
        BArray possibleTypesArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), TYPE_RECORD));
        for (Type possibleType : type.getPossibleTypes()) {
            possibleTypesArray.append(getTypeRecord(possibleType));
        }
        return possibleTypesArray;
    }

    private BArray getInterfacesArray() {
        return getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), TYPE_RECORD));
    }

    private BArray getFieldsArray(Type type) {
        BArray fieldsArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), FIELD_RECORD));
        for (Field field : type.getFields()) {
            fieldsArray.append(getFieldRecord(field));
        }
        return fieldsArray;
    }

    private BArray getInputFieldsArray(Type type) {
        BArray inputFieldsArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), INPUT_VALUE_RECORD));
        for (InputValue inputField : type.getInputFields()) {
            inputFieldsArray.append(getInputValueRecordFromInputValue(inputField));
        }
        return inputFieldsArray;
    }

    private BMap<BString, Object> getFieldRecord(Field field) {
        BMap<BString, Object> fieldRecord = ValueCreator.createRecordValue(getModule(), FIELD_RECORD);
        fieldRecord.put(NAME_FIELD, StringUtils.fromString(field.getName()));
        fieldRecord.put(TYPE_FIELD, getTypeRecord(field.getType()));
        fieldRecord.put(ARGS_FIELD, getInputValueArray(field));
        return fieldRecord;
    }

    private BArray getInputValueArray(Field field) {
        BArray inputValueArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), INPUT_VALUE_RECORD));
        for (InputValue inputValue : field.getArgs()) {
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
}
