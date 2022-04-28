/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.graphql.compiler.schema.generator;

import io.ballerina.stdlib.graphql.compiler.schema.types.DirectiveLocation;
import io.ballerina.stdlib.graphql.compiler.schema.types.EnumValue;
import io.ballerina.stdlib.graphql.compiler.schema.types.Field;
import io.ballerina.stdlib.graphql.compiler.schema.types.FieldName;
import io.ballerina.stdlib.graphql.compiler.schema.types.InputValue;
import io.ballerina.stdlib.graphql.compiler.schema.types.IntrospectionField;
import io.ballerina.stdlib.graphql.compiler.schema.types.IntrospectionType;
import io.ballerina.stdlib.graphql.compiler.schema.types.ScalarType;
import io.ballerina.stdlib.graphql.compiler.schema.types.Schema;
import io.ballerina.stdlib.graphql.compiler.schema.types.Type;
import io.ballerina.stdlib.graphql.compiler.schema.types.TypeKind;
import io.ballerina.stdlib.graphql.compiler.schema.types.TypeName;

import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getWrapperType;

/**
 * Creates introspection types for a GraphQL schema.
 */
public class IntrospectionTypeCreator {
    private final Schema schema;

    private static final String INCLUDE_DEPRECATED_ARG_NAME = "includeDeprecated";
    private static final String INCLUDE_DEPRECATED_DEFAULT_VALUE = "false";

    public IntrospectionTypeCreator(Schema schema) {
        this.schema = schema;
    }

    public void addIntrospectionTypes() {
        addDefaultSchemaTypes();
        addFieldsToSchemaType();
        addFieldsToTypeType();
        addFieldsToFieldType();
        addFieldsToInputValueType();
        addFieldsToEnumValueType();
        addValuesToTypeKindType();
        addFieldsToDirectiveType();
        addValuesToDirectiveLocationType();
    }

    private void addDefaultSchemaTypes() {
        // String and Boolean types are required for the Introspection types, even if the user does not use them.
        // Therefore, these two types are added first, to make them appear before the introspection types.
        this.schema.addType(ScalarType.STRING);
        this.schema.addType(ScalarType.BOOLEAN);
        for (IntrospectionType type : IntrospectionType.values()) {
            addType(type.getName(), type.getTypeKind(), type.getDescription());
        }
    }

    private void addFieldsToSchemaType() {
        Type schemaType = this.schema.getType(IntrospectionType.SCHEMA.getName());
        schemaType.addField(getDescriptionField());
        schemaType.addField(getTypesField());
        schemaType.addField(
                getIntrospectionField(IntrospectionField.QUERY_TYPE, getWrapperType(getTypeType(), TypeKind.NON_NULL)));
        schemaType.addField(getIntrospectionField(IntrospectionField.MUTATION_TYPE, getTypeType()));
        schemaType.addField(getIntrospectionField(IntrospectionField.SUBSCRIPTION_TYPE, getTypeType()));
        schemaType.addField(getDirectivesField());
    }

    private void addFieldsToTypeType() {
        Type type = this.schema.getType(IntrospectionType.TYPE.getName());
        type.addField(getIntrospectionField(IntrospectionField.KIND,
                                            getWrapperType(this.schema.getType(TypeName.TYPE_KIND.getName()),
                                                           TypeKind.NON_NULL)));
        type.addField(getIntrospectionField(IntrospectionField.NAME, getStringType()));
        type.addField(getDescriptionField());
        type.addField(getFieldsField());
        type.addField(getInterfacesField());
        type.addField(getPossibleTypesField());
        type.addField(getEnumValuesField());
        type.addField(getInputFieldsField());
        type.addField(getIntrospectionField(IntrospectionField.OF_TYPE, getTypeType()));
    }

    private void addFieldsToFieldType() {
        Type type = this.schema.getType(IntrospectionType.FIELD.getName());
        type.addField(getIntrospectionField(IntrospectionField.NAME, getNonNullStringType()));
        type.addField(getDescriptionField());
        type.addField(getArgsField());
        type.addField(getIntrospectionField(IntrospectionField.TYPE, getWrapperType(getTypeType(), TypeKind.NON_NULL)));
        type.addField(getIsDeprecatedField());
        type.addField(getDeprecationReasonField());
    }

    private void addFieldsToInputValueType() {
        Type type = this.schema.getType(IntrospectionType.INPUT_VALUE.getName());
        type.addField(getIntrospectionField(IntrospectionField.NAME, getNonNullStringType()));
        type.addField(getDescriptionField());
        type.addField(getIntrospectionField(IntrospectionField.TYPE, getWrapperType(getTypeType(), TypeKind.NON_NULL)));
        type.addField(getIntrospectionField(IntrospectionField.DEFAULT_VALUE, getStringType()));
    }

    private void addFieldsToEnumValueType() {
        Type type = this.schema.getType(IntrospectionType.ENUM_VALUE.getName());
        type.addField(getIntrospectionField(IntrospectionField.NAME, getNonNullStringType()));
        type.addField(getDescriptionField());
        type.addField(getIsDeprecatedField());
        type.addField(getDeprecationReasonField());
    }

    private void addValuesToTypeKindType() {
        Type typeKindType = this.schema.getType(IntrospectionType.TYPE_KIND.getName());
        for (TypeKind typeKind : TypeKind.values()) {
            typeKindType.addEnumValue(new EnumValue(typeKind.name(), typeKind.getDescription()));
        }
    }

    private void addFieldsToDirectiveType() {
        Type type = this.schema.getType(IntrospectionType.DIRECTIVE.getName());
        type.addField(getIntrospectionField(IntrospectionField.NAME, getNonNullStringType()));
        type.addField(getDescriptionField());
        type.addField(getLocationsField());
        type.addField(getArgsField());
    }

    private void addValuesToDirectiveLocationType() {
        Type directiveLocationType = this.schema.getType(IntrospectionType.DIRECTIVE_LOCATION.getName());
        for (DirectiveLocation location : DirectiveLocation.values()) {
            directiveLocationType.addEnumValue(new EnumValue(location.name(), location.getDescription()));
        }
    }

    private void addType(String name, TypeKind kind, String description) {
        this.schema.addType(name, kind, description);
    }

    private Field getDescriptionField() {
        Type stringType = getStringType();
        return getIntrospectionField(IntrospectionField.DESCRIPTION, stringType);
    }

    private Field getTypesField() {
        Type arrayMemberType = getWrapperType(getTypeType(), TypeKind.NON_NULL);
        Type arrayType = getWrapperType(getWrapperType(arrayMemberType, TypeKind.LIST), TypeKind.NON_NULL);
        return getIntrospectionField(IntrospectionField.TYPES, arrayType);
    }

    private Field getDirectivesField() {
        Type arrayMemberType = getWrapperType(getDirectiveType(), TypeKind.NON_NULL);
        Type arrayType = getWrapperType(getWrapperType(arrayMemberType, TypeKind.LIST), TypeKind.NON_NULL);
        return getIntrospectionField(IntrospectionField.DIRECTIVES, arrayType);
    }

    private Field getFieldsField() {
        Type arrayMemberType = getWrapperType(this.schema.getType(TypeName.FIELD.getName()), TypeKind.NON_NULL);
        Type arrayType = getWrapperType(arrayMemberType, TypeKind.LIST);
        Field field = new Field(FieldName.FIELDS.getName(), arrayType);
        field.addArg(getIncludeDeprecatedArg());
        return field;
    }

    private Field getInterfacesField() {
        Type arrayMemberType = getWrapperType(getTypeType(), TypeKind.NON_NULL);
        Type arrayType = getWrapperType(arrayMemberType, TypeKind.LIST);
        return getIntrospectionField(IntrospectionField.INTERFACES, arrayType);
    }

    private Field getPossibleTypesField() {
        Type arrayMemberType = getWrapperType(getTypeType(), TypeKind.NON_NULL);
        Type arrayType = getWrapperType(arrayMemberType, TypeKind.LIST);
        return getIntrospectionField(IntrospectionField.POSSIBLE_TYPES, arrayType);
    }

    private Field getEnumValuesField() {
        Type arrayMemberType = getWrapperType(getEnumValueType(), TypeKind.NON_NULL);
        Type arrayType = getWrapperType(arrayMemberType, TypeKind.LIST);
        Field enumValuesField = getIntrospectionField(IntrospectionField.ENUM_VALUES, arrayType);
        enumValuesField.addArg(getIncludeDeprecatedArg());
        return enumValuesField;
    }

    private Field getInputFieldsField() {
        Type arrayMemberType = getWrapperType(getInputValueType(), TypeKind.NON_NULL);
        Type arrayType = getWrapperType(arrayMemberType, TypeKind.LIST);
        return getIntrospectionField(IntrospectionField.INPUT_FIELDS, arrayType);
    }

    private Field getArgsField() {
        Type arrayMemberType = getWrapperType(getInputValueType(), TypeKind.NON_NULL);
        Type arrayType = getWrapperType(getWrapperType(arrayMemberType, TypeKind.LIST), TypeKind.NON_NULL);
        return getIntrospectionField(IntrospectionField.ARGS, arrayType);
    }

    private Field getIsDeprecatedField() {
        Type type = getWrapperType(getBooleanType(), TypeKind.NON_NULL);
        return getIntrospectionField(IntrospectionField.IS_DEPRECATED, type);
    }

    private Field getLocationsField() {
        Type directiveLocationType = this.schema.getType(IntrospectionType.DIRECTIVE_LOCATION.getName());
        Type arrayMemberType = getWrapperType(directiveLocationType, TypeKind.NON_NULL);
        Type arrayType = getWrapperType(getWrapperType(arrayMemberType, TypeKind.LIST), TypeKind.NON_NULL);
        return getIntrospectionField(IntrospectionField.LOCATIONS, arrayType);
    }

    private Field getDeprecationReasonField() {
        return getIntrospectionField(IntrospectionField.DEPRECATED_REASON, getStringType());
    }

    private InputValue getIncludeDeprecatedArg() {
        return new InputValue(INCLUDE_DEPRECATED_ARG_NAME, getBooleanType(), null, INCLUDE_DEPRECATED_DEFAULT_VALUE);
    }

    private Type getNonNullStringType() {
        return getWrapperType(getStringType(), TypeKind.NON_NULL);
    }

    private Type getStringType() {
        return this.schema.addType(ScalarType.STRING);
    }

    private Type getBooleanType() {
        return this.schema.addType(ScalarType.BOOLEAN);
    }

    private Type getTypeType() {
        return this.schema.getType(IntrospectionType.TYPE.getName());
    }

    private Type getDirectiveType() {
        return this.schema.getType(IntrospectionType.DIRECTIVE.getName());
    }

    private Type getEnumValueType() {
        return this.schema.getType(IntrospectionType.ENUM_VALUE.getName());
    }

    private Type getInputValueType() {
        return this.schema.getType(IntrospectionType.INPUT_VALUE.getName());
    }

    private static Field getIntrospectionField(IntrospectionField introspectionField, Type type) {
        return new Field(introspectionField.getName(), type, introspectionField.getDescription());
    }
}
