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

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.stdlib.graphql.schema.Schema;
import io.ballerina.stdlib.graphql.schema.SchemaField;
import io.ballerina.stdlib.graphql.schema.SchemaType;
import io.ballerina.stdlib.graphql.schema.TypeKind;

import static io.ballerina.stdlib.graphql.engine.EngineUtils.FIELD_RECORD;
import static io.ballerina.stdlib.graphql.engine.EngineUtils.INPUT_VALUE_RECORD;
import static io.ballerina.stdlib.graphql.engine.EngineUtils.TYPE_KIND_ENUM;
import static io.ballerina.stdlib.graphql.engine.EngineUtils.TYPE_RECORD;

/**
 * This class creates the introspection types for the Schema.
 */
public class IntrospectionUtils {
    private static final String NAME = "name";
    private static final String KIND = "kind";
    private static final String FIELDS = "fields";
    private static final String ENUM_VALUES = "enumValues";
    private static final String TYPE = "type";
    private static final String ARGS = "args";
    private static final String DEFAULT_VALUE = "defaultValue";

    static void initializeIntrospectionTypes(Schema schema) {
        schema.addType(createTypeKindSchemaType());
        schema.addType(createTypeSchemaType());
        schema.addType(createFieldSchemaType());
        schema.addType(createInputValueSchemaType());
    }

    private static SchemaType createTypeKindSchemaType() {
        SchemaType typeKindSchemaType = new SchemaType(TYPE_KIND_ENUM, TypeKind.ENUM, false);
        typeKindSchemaType.addEnumValue(StringUtils.fromString(TypeKind.SCALAR.toString()));
        typeKindSchemaType.addEnumValue(StringUtils.fromString(TypeKind.OBJECT.toString()));
        typeKindSchemaType.addEnumValue(StringUtils.fromString(TypeKind.ENUM.toString()));
        return typeKindSchemaType;
    }

    private static SchemaType createTypeSchemaType() {
        SchemaType typeSchemaType = new SchemaType(TYPE_RECORD, TypeKind.OBJECT, false);
        typeSchemaType.addField(new SchemaField(NAME));
        typeSchemaType.addField(new SchemaField(KIND));
        typeSchemaType.addField(new SchemaField(FIELDS));
        typeSchemaType.addField(new SchemaField(ENUM_VALUES));
        return typeSchemaType;
    }

    private static SchemaType createFieldSchemaType() {
        SchemaType fieldSchemaType = new SchemaType(FIELD_RECORD, TypeKind.OBJECT, false);
        fieldSchemaType.addField(new SchemaField(NAME));
        fieldSchemaType.addField(new SchemaField(TYPE));
        fieldSchemaType.addField(new SchemaField(ARGS));
        return fieldSchemaType;
    }

    private static SchemaType createInputValueSchemaType() {
        SchemaType inputValueSchemaType = new SchemaType(INPUT_VALUE_RECORD, TypeKind.OBJECT, false);
        inputValueSchemaType.addField(new SchemaField(NAME));
        inputValueSchemaType.addField(new SchemaField(TYPE));
        inputValueSchemaType.addField(new SchemaField(DEFAULT_VALUE));
        return inputValueSchemaType;
    }
}
