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
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.Parameter;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.RemoteMethodType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.StreamType;
import io.ballerina.runtime.api.types.TableType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.stdlib.graphql.runtime.schema.types.InputValue;
import io.ballerina.stdlib.graphql.runtime.schema.types.SchemaField;
import io.ballerina.stdlib.graphql.runtime.schema.types.SchemaType;
import io.ballerina.stdlib.graphql.runtime.schema.types.TypeKind;

import java.util.List;
import java.util.Map;
import java.util.Objects;

import static io.ballerina.runtime.api.TypeTags.STREAM_TAG;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ARGS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.BOOLEAN;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ENUM_VALUES_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FALSE;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FIELDS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FIELD_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.INCLUDE_DEPRECATED;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.KEY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.MUTATION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SCHEMA_RECORD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.STRING;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SUBSCRIBE_ACCESSOR;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SUBSCRIPTION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.TYPE_RECORD;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.getEffectiveType;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.getMemberTypes;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.getTypeName;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.getTypeNameFromType;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.isEnum;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.isRequired;
import static io.ballerina.stdlib.graphql.runtime.utils.ModuleUtils.getModule;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.isContext;
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
        this.addSchemaTypeFields();
        SchemaType mutationType = populateFieldsForMutationType();
        SchemaType subscriptionType = populateFieldsForSubscriptionType();
        populateFieldsForQueryType();
        if (mutationType != null) {
            this.typeMap.put(MUTATION, mutationType);
        }
        if (subscriptionType != null) {
            this.typeMap.put(SUBSCRIPTION, subscriptionType);
        }
        this.addAdditionalInputValuesToTypeFields();
    }

    public SchemaType populateFieldsForMutationType() {
        SchemaType mutationType = null;
        if (this.typeMap.containsKey(MUTATION)) {
            mutationType = this.typeMap.remove(MUTATION);
            ServiceType serviceType = (ServiceType) mutationType.getBalType();
            for (RemoteMethodType remoteMethod : serviceType.getRemoteMethods()) {
                mutationType.addField(getFieldsFromRemoteMethodType(remoteMethod));
            }
        }
        return mutationType;
    }

    public SchemaType populateFieldsForSubscriptionType() {
        SchemaType subscriptionType = null;
        if (this.typeMap.containsKey(SUBSCRIPTION)) {
            subscriptionType = this.typeMap.remove(SUBSCRIPTION);
            ServiceType serviceType = (ServiceType) subscriptionType.getBalType();
            for (ResourceMethodType resourceMethodType : serviceType.getResourceMethods()) {
                if (Objects.equals(resourceMethodType.getAccessor(), SUBSCRIBE_ACCESSOR)) {
                    String[] resourcePath = resourceMethodType.getResourcePath();
                    subscriptionType.addField(getFieldsFromResourceMethodType(resourceMethodType, resourcePath));
                }
            }
        }
        return subscriptionType;
    }

    public void populateFieldsForQueryType() {
        for (SchemaType schemaType : this.typeMap.values()) {
            populateFieldsOfSchemaQueryType(schemaType);
        }
    }

    private void addAdditionalInputValuesToTypeFields() {
        SchemaType schemaType = this.getType(TYPE_RECORD);
        SchemaField fieldsSchemaField = schemaType.getField(FIELDS_FIELD.getValue());
        fieldsSchemaField.addArg(getIncludeDeprecatedInputValue());

        SchemaField enumValuesField = schemaType.getField(ENUM_VALUES_FIELD.getValue());
        enumValuesField.addArg(getIncludeDeprecatedInputValue());

        SchemaType fieldType = this.getType(FIELD_RECORD);
        SchemaField argsField = fieldType.getField(ARGS_FIELD.getValue());
        argsField.addArg(getIncludeDeprecatedInputValue());
    }

    private InputValue getIncludeDeprecatedInputValue() {
        InputValue inputValue = new InputValue(INCLUDE_DEPRECATED, this.getType(BOOLEAN));
        inputValue.setDefaultValue(FALSE);
        return inputValue;
    }

    private void addSchemaTypeFields() {
        SchemaType schemaType = new SchemaType(SCHEMA_RECORD, TypeKind.OBJECT,
                                               ValueCreator.createRecordValue(getModule(), SCHEMA_RECORD).getType());
        this.typeMap.put(SCHEMA_RECORD, schemaType);
    }

    public Map<String, SchemaType> getTypeMap() {
        return this.typeMap;
    }

    public SchemaType getType(String name) {
        return this.typeMap.get(name);
    }

    private void populateFieldsOfSchemaQueryType(SchemaType schemaType) {
        if (schemaType.getKind() == TypeKind.NON_NULL || schemaType.getKind() == TypeKind.LIST) {
            populateFieldsOfSchemaQueryType(schemaType.getOfType());
        } else if (schemaType.getKind() == TypeKind.ENUM) {
            UnionType unionType = (UnionType) schemaType.getBalType();
            for (Type memberType : unionType.getMemberTypes()) {
                schemaType.addEnumValue(memberType.getZeroValue());
            }
        } else if (schemaType.getKind() == TypeKind.OBJECT || schemaType.getKind() == TypeKind.INPUT_OBJECT) {
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
            return getSchemaTypeFromUnionType((UnionType) type);
        } else if (tag == TypeTags.ARRAY_TAG) {
            ArrayType arrayType = (ArrayType) type;
            SchemaType schemaType = new SchemaType(null, TypeKind.LIST);
            Type elementType = arrayType.getElementType();
            SchemaType elementSchemaType = getSchemaTypeFromType(elementType);
            if (elementType.isNilable()) {
                schemaType.setOfType(elementSchemaType);
            } else {
                SchemaType nonNullType = getNonNullType(elementSchemaType);
                schemaType.setOfType(nonNullType);
            }
            return schemaType;
        } else if (tag == TypeTags.TABLE_TAG) {
            TableType tableType = (TableType) type;
            SchemaType schemaType = new SchemaType(null, TypeKind.LIST);
            schemaType.setOfType(getSchemaTypeFromType(tableType.getConstrainedType()));
            return schemaType;
        } else if (tag == TypeTags.INTERSECTION_TAG) {
            return getSchemaTypeFromType(getEffectiveType(type));
        } else {
            return this.typeMap.get(getTypeNameFromType(type));
        }
    }

    private SchemaType getSchemaTypeFromUnionType(UnionType unionType) {
        if (isEnum(unionType)) {
            return this.typeMap.get(getTypeNameFromType(unionType));
        }
        List<Type> memberTypes = getMemberTypes(unionType);
        if (memberTypes.size() == 1) {
            return getSchemaTypeFromType(memberTypes.get(0));
        } else {
            SchemaType schemaType = this.getType(getTypeName(unionType));
            for (Type memberType : memberTypes) {
                SchemaType possibleType = this.typeMap.get(getTypeNameFromType(memberType));
                schemaType.addPossibleType(possibleType);
            }
            return schemaType;
        }
    }

    private void getFieldsFromRecordType(SchemaType schemaType) {
        RecordType recordType = (RecordType) schemaType.getBalType();
        for (Field field : recordType.getFields().values()) {
            if (schemaType.getKind() == TypeKind.INPUT_OBJECT) {
                getFieldsFromInputObjectType(schemaType, field);
            } else {
                SchemaField schemaField = new SchemaField(field.getFieldName());
                setTypeForField(field, schemaField);
                if (getEffectiveType(field.getFieldType()).getTag() == TypeTags.MAP_TAG) {
                    SchemaType nonNullType = getNonNullType(this.typeMap.get(STRING));
                    nonNullType.setOfType(this.typeMap.get(STRING));
                    schemaField.addArg(new InputValue(KEY, nonNullType));
                }
                schemaType.addField(schemaField);
            }
        }
    }

    private void getFieldsFromInputObjectType(SchemaType schemaType, Field field) {
        SchemaType fieldType = getSchemaTypeFromType(field.getFieldType());
        if (field.getFieldType().isNilable() || !isRequired(field)) {
            schemaType.addInputField(new InputValue(field.getFieldName(), fieldType));
        } else {
            SchemaType wrapperType = getNonNullType(fieldType);
            schemaType.addInputField(new InputValue(field.getFieldName(), wrapperType));
        }
    }

    private void getFieldsFromServiceType(SchemaType schemaType) {
        ServiceType serviceType = (ServiceType) schemaType.getBalType();
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            String[] resourcePath = resourceMethod.getResourcePath();
            schemaType.addField(getFieldsFromResourceMethodType(resourceMethod, resourcePath));
        }
    }

    private SchemaField getFieldsFromRemoteMethodType(RemoteMethodType remoteMethod) {
        SchemaField schemaField = new SchemaField(remoteMethod.getName());
        addArgsToSchemaField(remoteMethod, schemaField);
        setTypeForField(remoteMethod, schemaField);
        return schemaField;
    }

    private SchemaField getFieldsFromResourceMethodType(ResourceMethodType resourceMethod, String[] resourcePath) {
        SchemaField schemaField = new SchemaField(resourcePath[0]);
        if (resourcePath.length > 1) {
            SchemaType fieldType = this.typeMap.get(resourcePath[0]);
            String[] remainingPath = removeFirstElementFromArray(resourcePath);
            fieldType.addField(getFieldsFromResourceMethodType(resourceMethod, remainingPath));
            schemaField.setType(fieldType);
        } else {
            setTypeForField(resourceMethod, schemaField);
            addArgsToSchemaField(resourceMethod, schemaField);
        }
        return schemaField;
    }

    private void setTypeForField(MethodType method, SchemaField schemaField) {
        Type resourceReturnType = method.getType().getReturnType();
        if (resourceReturnType.getTag() == STREAM_TAG) {
            resourceReturnType = ((StreamType) resourceReturnType).getConstrainedType();
        }
        SchemaType fieldType = getSchemaTypeFromType(resourceReturnType);
        if (resourceReturnType.isNilable()) {
            schemaField.setType(fieldType);
        } else {
            SchemaType nonNullType = getNonNullType(fieldType);
            schemaField.setType(nonNullType);
        }
    }

    private void setTypeForField(Field field, SchemaField schemaField) {
        SchemaType fieldType = getSchemaTypeFromType(field.getFieldType());
        if (field.getFieldType().isNilable() || !isRequired(field)) {
            schemaField.setType(fieldType);
        } else {
            SchemaType nonNullType = getNonNullType(fieldType);
            schemaField.setType(nonNullType);
        }
    }

    private void addArgsToSchemaField(MethodType method, SchemaField schemaField) {
        for (Parameter parameter : method.getParameters()) {
            if (isContext(parameter.type)) {
                continue;
            }
            Type inputType = getInputType(parameter.type);
            SchemaType parameterType;
            if (inputType.getTag() == TypeTags.ARRAY_TAG) {
                parameterType = getSchemaTypeFromType(inputType);
            } else {
                parameterType = this.getType(getTypeNameFromType(inputType));
            }
            if (!parameter.type.isNilable()) {
                parameterType = getNonNullType(parameterType);
            }
            InputValue inputValue = new InputValue(parameter.name, parameterType);
            if (parameter.isDefault) {
                inputValue.setDefaultValue(inputType.getZeroValue().toString());
            }
            schemaField.addArg(inputValue);
        }
    }

    private static SchemaType getNonNullType(SchemaType schemaType) {
        SchemaType wrapperType = new SchemaType(null, TypeKind.NON_NULL);
        wrapperType.setOfType(schemaType);
        return wrapperType;
    }

    private static Type getInputType(Type type) {
        if (type.getTag() == TypeTags.UNION_TAG) {
            UnionType unionType = (UnionType) type;
            if (isEnum(unionType)) {
                return type;
            }
            for (Type memberType : unionType.getOriginalMemberTypes()) {
                if (memberType.getTag() == TypeTags.NULL_TAG) {
                    continue;
                }
                return memberType;
            }
        } else if (type.getTag() == TypeTags.INTERSECTION_TAG) {
            return getEffectiveType(type);
        }
        return type;
    }
}
