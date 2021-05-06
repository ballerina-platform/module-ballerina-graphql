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

import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.TableType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.stdlib.graphql.runtime.schema.types.InputValue;
import io.ballerina.stdlib.graphql.runtime.schema.types.SchemaField;
import io.ballerina.stdlib.graphql.runtime.schema.types.SchemaType;
import io.ballerina.stdlib.graphql.runtime.schema.types.TypeKind;

import java.util.List;
import java.util.Map;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.KEY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.QUERY_TYPE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SCHEMA_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.STRING;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.TYPES_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.TYPE_RECORD;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.getMemberTypes;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.getTypeNameFromType;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.isEnum;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.isOptional;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.isReturningErrorOrNil;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.removeFirstElementFromArray;

/**
 * This class is used to populate the fields of each type found at {@code TypeFinder} class.
 */
public class FieldFinder {

    private final Map<String, SchemaType> typeMap;

    public FieldFinder(Map<String, SchemaType> typeMap) {
        this.typeMap = typeMap;
    }

    public void populateFields() {
        for (SchemaType schemaType : this.typeMap.values()) {
            populateFieldsOfSchemaType(schemaType);
        }
        this.addSchemaTypeFields();
    }

    private void addSchemaTypeFields() {
        SchemaType schemaType = new SchemaType(SCHEMA_RECORD, TypeKind.OBJECT);
        SchemaField queryTypeField = new SchemaField(QUERY_TYPE_FIELD.getValue());
        queryTypeField.setType(this.typeMap.get(TYPE_RECORD));
        schemaType.addField(queryTypeField);

        SchemaField typesField = new SchemaField(TYPES_FIELD.getValue());
        SchemaType typesFieldWrapper =  getNonNullType();
        SchemaType typesFieldType = new SchemaType(null, TypeKind.LIST);
        typesFieldType.setOfType(this.typeMap.get(TYPE_RECORD));
        typesFieldWrapper.setOfType(typesFieldType);
        typesField.setType(typesFieldWrapper);
        schemaType.addField(typesField);

        this.typeMap.put(SCHEMA_RECORD, schemaType);
    }

    public Map<String, SchemaType> getTypeMap() {
        return this.typeMap;
    }

    public SchemaType getType(String name) {
        return this.typeMap.get(name);
    }

    private void populateFieldsOfSchemaType(SchemaType schemaType) {
        if (schemaType.getKind() == TypeKind.SCALAR) {
            // Do nothing
        } else if (schemaType.getKind() == TypeKind.NON_NULL || schemaType.getKind() == TypeKind.LIST) {
            populateFieldsOfSchemaType(schemaType.getOfType());
        } else if (schemaType.getKind() == TypeKind.ENUM) {
            UnionType unionType = (UnionType) schemaType.getBalType();
            for (Type memberType : unionType.getMemberTypes()) {
                schemaType.addEnumValue(memberType.getZeroValue());
            }
        } else { // OBJECT
            findFieldsForObjectKindSchemaTypes(schemaType);
        }
    }

    private void findFieldsForObjectKindSchemaTypes(SchemaType schemaType) {
        Type balType = schemaType.getBalType();
        int tag = balType.getTag();
        if (tag == TypeTags.SERVICE_TAG) {
            getFieldsFromServiceType(schemaType);
        } else if (tag == TypeTags.RECORD_TYPE_TAG) {
            getFieldsFromRecordType(schemaType);
        }
    }

    private SchemaType getSchemaTypeFromType(Type type) {
        int tag = type.getTag();
        if (tag == TypeTags.UNION_TAG) {
            UnionType unionType = (UnionType) type;
            if (isEnum(unionType)) {
                return this.typeMap.get(getTypeNameFromType(unionType));
            }
            List<Type> memberTypes = getMemberTypes(unionType);
            if (memberTypes.size() == 1) {
                return getSchemaTypeFromType(memberTypes.get(0));
            } else {
                SchemaType schemaType = new SchemaType(getTypeNameFromType(unionType), TypeKind.UNION);
                for (Type memberType : memberTypes) {
                    SchemaType possibleType = this.typeMap.get(getTypeNameFromType(memberType));
                    schemaType.addPossibleType(possibleType);
                }
                return schemaType;
            }
        } else if (tag == TypeTags.ARRAY_TAG) {
            ArrayType arrayType = (ArrayType) type;
            SchemaType schemaType = new SchemaType(null, TypeKind.LIST);
            schemaType.setOfType(getSchemaTypeFromType(arrayType.getElementType()));
            return schemaType;
        } else if (tag == TypeTags.TABLE_TAG) {
            TableType tableType = (TableType) type;
            SchemaType schemaType = new SchemaType(null, TypeKind.LIST);
            schemaType.setOfType(getSchemaTypeFromType(tableType.getConstrainedType()));
            return schemaType;
        } else {
            if (isReturningErrorOrNil(type)) {
                return this.typeMap.get(getTypeNameFromType(type));
            } else {
                SchemaType schemaType = getNonNullType();
                schemaType.setOfType(this.typeMap.get(getTypeNameFromType(type)));
                return schemaType;
            }
        }
    }

    private void getFieldsFromRecordType(SchemaType schemaType) {
        RecordType recordType = (RecordType) schemaType.getBalType();
        for (Field field : recordType.getFields().values()) {
            SchemaField schemaField = new SchemaField(field.getFieldName());
            SchemaType fieldType = getSchemaTypeFromType(field.getFieldType());
            if (!isOptional(field)) {
                SchemaType wrapperType = getNonNullType();
                wrapperType.setOfType(fieldType);
            }
            schemaField.setType(fieldType);
            if (field.getFieldType().getTag() == TypeTags.MAP_TAG) {
                schemaField.addArg(new InputValue(KEY, this.typeMap.get(STRING)));
            }
            schemaType.addField(schemaField);
        }
    }

    private void getFieldsFromServiceType(SchemaType schemaType) {
        ServiceType serviceType = (ServiceType) schemaType.getBalType();
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            String[] resourcePath = resourceMethod.getResourcePath();
            schemaType.addField(getFieldsFromResourceMethodType(resourceMethod, resourcePath));
        }
    }

    private SchemaField getFieldsFromResourceMethodType(ResourceMethodType resourceMethod, String[] resourcePath) {
        SchemaField schemaField = new SchemaField(resourcePath[0]);
        if (resourcePath.length > 1) {
            SchemaType fieldType = this.typeMap.get(resourcePath[0]);
            String[] remainingPath = removeFirstElementFromArray(resourcePath);
            fieldType.addField(getFieldsFromResourceMethodType(resourceMethod, remainingPath));
            schemaField.setType(fieldType);
        } else {
            Type resourceReturnType = resourceMethod.getType().getReturnType();
            SchemaType fieldType = getSchemaTypeFromType(resourceReturnType);
            if (resourceReturnType.isNilable()) {
                schemaField.setType(fieldType);
            } else {
                SchemaType nonNullType = getNonNullType();
                nonNullType.setOfType(fieldType);
                schemaField.setType(nonNullType);
            }
            addArgsToSchemaField(resourceMethod, schemaField);
        }
        return schemaField;
    }

    private void addArgsToSchemaField(ResourceMethodType resourceMethod, SchemaField schemaField) {
        String[] paramNames = resourceMethod.getParamNames();
        Type[] paramTypes = resourceMethod.getParameterTypes();
        Boolean[] paramDefaultability = resourceMethod.getParamDefaultability();
        for (int i = 0; i < paramNames.length; i++) {
            SchemaType inputValueType = this.typeMap.get(getTypeNameFromType(paramTypes[i]));
            InputValue inputValue;
            if (paramDefaultability[i]) {
                inputValue = new InputValue(paramNames[i], inputValueType, paramTypes[i].getZeroValue().toString());
            } else {
                SchemaType nonNullType = getNonNullType();
                nonNullType.setOfType(inputValueType);
                inputValue = new InputValue(paramNames[i], nonNullType);
            }
            schemaField.addArg(inputValue);
        }
    }

    private static SchemaType getNonNullType() {
        return new SchemaType(null, TypeKind.NON_NULL);
    }
}
