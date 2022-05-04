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

import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.flags.SymbolFlags;
import io.ballerina.runtime.api.flags.TypeFlags;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.graphql.compiler.schema.types.Directive;
import io.ballerina.stdlib.graphql.compiler.schema.types.DirectiveLocation;
import io.ballerina.stdlib.graphql.compiler.schema.types.EnumValue;
import io.ballerina.stdlib.graphql.compiler.schema.types.Field;
import io.ballerina.stdlib.graphql.compiler.schema.types.InputValue;
import io.ballerina.stdlib.graphql.compiler.schema.types.Schema;
import io.ballerina.stdlib.graphql.compiler.schema.types.Type;
import io.ballerina.stdlib.graphql.compiler.schema.types.TypeKind;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ARGS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.DEFAULT_VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.DEPRECATION_REASON_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.DESCRIPTION_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.DIRECTIVES_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.DIRECTIVE_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ENUM_VALUES_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ENUM_VALUE_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FIELDS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FIELD_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.INPUT_FIELDS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.INPUT_VALUE_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.INTERFACES_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.IS_DEPRECATED_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.KIND_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.LOCATIONS_FIELD;
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
        schemaRecord.put(DESCRIPTION_FIELD, StringUtils.fromString(this.schema.getDescription()));
        BArray typesArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), TYPE_RECORD));
        for (BMap<BString, Object> typeRecord : this.typeRecords.values()) {
            typesArray.append(typeRecord);
        }
        schemaRecord.put(TYPES_FIELD, typesArray);
        schemaRecord.put(QUERY_TYPE_FIELD, this.typeRecords.get(QUERY));
        schemaRecord.put(MUTATION_TYPE_FIELD, this.typeRecords.get(MUTATION));
        schemaRecord.put(SUBSCRIPTION_TYPE_FIELD, this.typeRecords.get(SUBSCRIPTION));
        schemaRecord.put(DIRECTIVES_FIELD, getDirectives());
        schemaRecord.freezeDirect();
        return schemaRecord;
    }

    private void populateTypeRecordMap() {
        for (Type type : this.schema.getTypes().values()) {
            BMap<BString, Object> typeRecord = ValueCreator.createRecordValue(getModule(), TYPE_RECORD);
            typeRecord.put(NAME_FIELD, StringUtils.fromString(type.getName()));
            typeRecord.put(KIND_FIELD, StringUtils.fromString(type.getKind().toString()));
            typeRecord.put(DESCRIPTION_FIELD, StringUtils.fromString(type.getDescription()));
            this.typeRecords.put(type.getName(), typeRecord);
        }
    }

    private void populateFieldsOfTypes() {
        for (Map.Entry<String, Type> entry : this.schema.getTypes().entrySet()) {
            Type type = entry.getValue();
            BMap<BString, Object> typeRecord = this.typeRecords.get(entry.getKey());
            if (type.getKind() == TypeKind.OBJECT || type.getKind() == TypeKind.INTERFACE) {
                typeRecord.put(FIELDS_FIELD, getFieldsArray(type));
                typeRecord.put(INTERFACES_FIELD, getInterfacesArray(type));
            }
            if (type.getKind() == TypeKind.INTERFACE || entry.getValue().getKind() == TypeKind.UNION) {
                typeRecord.put(POSSIBLE_TYPES_FIELD, getPossibleTypesArray(type));
            }
            if (type.getKind() == TypeKind.ENUM) {
                typeRecord.put(ENUM_VALUES_FIELD, getEnumValuesArray(type));
            }
            if (type.getKind() == TypeKind.INPUT_OBJECT) {
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
            typeRecord.put(DESCRIPTION_FIELD, StringUtils.fromString(type.getDescription()));
        }
        if (type.getKind() == TypeKind.LIST || type.getKind() == TypeKind.NON_NULL) {
            typeRecord.put(OF_TYPE_FIELD, getTypeRecord(type.getOfType()));
        }
        return typeRecord;
    }

    private BArray getEnumValuesArray(Type type) {
        BArray enumValuesArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), ENUM_VALUE_RECORD));
        for (EnumValue enumValue : type.getEnumValues()) {
            enumValuesArray.append(getEnumValueRecord(enumValue));
        }
        return enumValuesArray;
    }

    private BMap<BString, Object> getEnumValueRecord(EnumValue enumValue) {
        BMap<BString, Object> enumValueRecord = ValueCreator.createRecordValue(getModule(), ENUM_VALUE_RECORD);
        enumValueRecord.put(NAME_FIELD, StringUtils.fromString(enumValue.getName()));
        enumValueRecord.put(DESCRIPTION_FIELD, StringUtils.fromString(enumValue.getDescription()));
        enumValueRecord.put(IS_DEPRECATED_FIELD, enumValue.isDeprecated());
        enumValueRecord.put(DEPRECATION_REASON_FIELD, StringUtils.fromString(enumValue.getDeprecationReason()));
        return enumValueRecord;
    }

    private BArray getPossibleTypesArray(Type type) {
        BArray possibleTypesArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), TYPE_RECORD));
        for (Type possibleType : type.getPossibleTypes()) {
            possibleTypesArray.append(getTypeRecord(possibleType));
        }
        return possibleTypesArray;
    }

    private BArray getInterfacesArray(Type type) {
        BArray interfacesArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), TYPE_RECORD));
        for (Type interfaceType : type.getInterfaces()) {
            interfacesArray.append(getTypeRecord(interfaceType));
        }
        return interfacesArray;
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
        fieldRecord.put(DESCRIPTION_FIELD, StringUtils.fromString(field.getDescription()));
        fieldRecord.put(TYPE_FIELD, getTypeRecord(field.getType())); // TODO:
        fieldRecord.put(ARGS_FIELD, getInputValueArray(field.getArgs()));
        fieldRecord.put(IS_DEPRECATED_FIELD, field.isDeprecated());
        fieldRecord.put(DEPRECATION_REASON_FIELD, StringUtils.fromString(field.getDeprecationReason()));
        return fieldRecord;
    }

    private BArray getInputValueArray(List<InputValue> inputValues) {
        BArray inputValueArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), INPUT_VALUE_RECORD));
        for (InputValue inputValue : inputValues) {
            inputValueArray.append(getInputValueRecordFromInputValue(inputValue));
        }
        return inputValueArray;
    }

    private BMap<BString, Object> getInputValueRecordFromInputValue(InputValue inputValue) {
        BMap<BString, Object> inputValueRecord = ValueCreator.createRecordValue(getModule(), INPUT_VALUE_RECORD);
        inputValueRecord.put(NAME_FIELD, StringUtils.fromString(inputValue.getName()));
        inputValueRecord.put(DESCRIPTION_FIELD, StringUtils.fromString(inputValue.getDescription()));
        inputValueRecord.put(TYPE_FIELD, getTypeRecord(inputValue.getType()));
        inputValueRecord.put(DEFAULT_VALUE_FIELD, StringUtils.fromString(inputValue.getDefaultValue()));
        return inputValueRecord;
    }

    private BArray getDirectives() {
        BArray directivesArray = getArrayTypeFromBMap(ValueCreator.createRecordValue(getModule(), DIRECTIVE_RECORD));
        for (Directive directive : this.schema.getDirectives()) {
            directivesArray.append(getDirectiveRecord(directive));
        }
        return directivesArray;
    }

    private BMap<BString, Object> getDirectiveRecord(Directive directive) {
        BMap<BString, Object> directiveRecord = ValueCreator.createRecordValue(getModule(), DIRECTIVE_RECORD);
        directiveRecord.put(NAME_FIELD, StringUtils.fromString(directive.getName()));
        directiveRecord.put(DESCRIPTION_FIELD, StringUtils.fromString(directive.getDescription()));
        directiveRecord.put(LOCATIONS_FIELD, getDirectiveLocationsArray(directive));
        directiveRecord.put(ARGS_FIELD, getInputValueArray(directive.getArgs()));
        return directiveRecord;
    }

    private BArray getDirectiveLocationsArray(Directive directive) {
        BArray directiveLocationsArray = ValueCreator.createArrayValue(getDirectiveLocationArrayType());
        for (DirectiveLocation location : directive.getLocations()) {
            directiveLocationsArray.append(StringUtils.fromString(location.toString()));
        }
        return directiveLocationsArray;
    }

    private ArrayType getDirectiveLocationArrayType() {
        List<io.ballerina.runtime.api.types.Type> memberTypes = new ArrayList<>();
        for (DirectiveLocation directiveLocation : DirectiveLocation.values()) {
            memberTypes.add(TypeCreator.createFiniteType(directiveLocation.toString(),
                                                         Set.of(StringUtils.fromString(directiveLocation.toString())),
                                                         TypeFlags.ANYDATA));
        }
        UnionType enumType = TypeCreator.createUnionType(memberTypes, TypeFlags.ANYDATA, SymbolFlags.ENUM);
        return TypeCreator.createArrayType(enumType);
    }
}
