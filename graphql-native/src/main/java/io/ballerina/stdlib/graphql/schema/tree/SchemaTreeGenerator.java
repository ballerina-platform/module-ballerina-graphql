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

package io.ballerina.stdlib.graphql.schema.tree;

import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.flags.SymbolFlags;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.TableType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.stdlib.graphql.schema.InputValue;
import io.ballerina.stdlib.graphql.schema.SchemaField;
import io.ballerina.stdlib.graphql.schema.SchemaType;
import io.ballerina.stdlib.graphql.schema.TypeKind;

import java.util.Collection;
import java.util.Map;

import static io.ballerina.stdlib.graphql.engine.EngineUtils.QUERY;
import static io.ballerina.stdlib.graphql.schema.tree.TypeTreeGenerator.getNonNullNonErrorTypeFromUnion;
import static io.ballerina.stdlib.graphql.schema.tree.TypeTreeGenerator.getScalarTypeName;
import static io.ballerina.stdlib.graphql.utils.Utils.INVALID_TYPE_ERROR;
import static io.ballerina.stdlib.graphql.utils.Utils.createError;
import static io.ballerina.stdlib.graphql.utils.Utils.removeFirstElementFromArray;

/**
 * Generates a tree of fields found in a ballerina service to create a schema.
 *
 * @since 0.2.0
 */
public class SchemaTreeGenerator {
    private final ServiceType serviceType;
    private final Map<String, SchemaType> typeMap;

    public SchemaTreeGenerator(ServiceType serviceType, Map<String, SchemaType> typeMap) {
        this.serviceType = serviceType;
        this.typeMap = typeMap;
    }

    public SchemaType getQueryType() {
        SchemaType queryType = new SchemaType(QUERY, TypeKind.OBJECT);
        addFieldsForServiceType(serviceType, queryType);
        return queryType;
    }

    private void addFieldsForServiceType(ServiceType serviceType, SchemaType parent) {
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            parent.addField(createFieldForResource(resourceMethod, resourceMethod.getResourcePath(), parent));
        }
    }

    private SchemaField createFieldForResource(ResourceMethodType resourceMethod, String[] resourcePath,
                                               SchemaType parent) {
        String name = resourcePath[0];
        SchemaField schemaField;
        if (parent.hasField(name)) {
            schemaField = parent.getField(name);
        } else {
            schemaField = new SchemaField(name);
        }

        if (resourcePath.length > 1) {
            String[] paths = removeFirstElementFromArray(resourcePath);
            SchemaType schemaType = getType(name);
            schemaType.addField(createFieldForResource(resourceMethod, paths, schemaType));
            schemaField.setType(schemaType);
        } else {
            addArgumentsForSchemaField(resourceMethod, schemaField);
            schemaField.setType(getSchemaTypeForField(resourceMethod.getType().getReturnType()));
        }
        return schemaField;
    }

    private SchemaType getSchemaTypeForField(Type type) {
        int tag = type.getTag();
        if (tag == TypeTags.ARRAY_TAG) {
            return getSchemaTypeForArrayType((ArrayType) type);
        } else if (tag == TypeTags.UNION_TAG) {
            return getSchemaTypeForUnionType((UnionType) type);
        } else if (tag == TypeTags.RECORD_TYPE_TAG) {
            SchemaType schemaType = getNonNullType();
            SchemaType ofType = createSchemaTypeForRecordType((RecordType) type);
            schemaType.setOfType(ofType);
            return schemaType;
        } else if (tag == TypeTags.SERVICE_TAG) {
            SchemaType schemaType = getNonNullType();
            addFieldsForServiceType((ServiceType) type, schemaType);
            return schemaType;
        } else if (tag == TypeTags.TABLE_TAG) {
            SchemaType schemaType = getNonNullType();
            SchemaType ofType = createSchemaTypeForTableType((TableType) type);
            schemaType.setOfType(ofType);
            return schemaType;
        } else {
            String typeName = getScalarTypeName(tag);
            SchemaType schemaType = getNonNullType();
            schemaType.setOfType(getType(typeName));
            return schemaType;
        }
    }

    private SchemaType getType(String typeName) {
        if (this.typeMap.containsKey(typeName)) {
            return this.typeMap.get(typeName);
        } else {
            // TODO: Redundant error, since this type cannot be null
            String message = "Type information not found: " + typeName;
            throw createError(message, INVALID_TYPE_ERROR);
        }
    }

    private SchemaType getSchemaTypeForArrayType(ArrayType arrayType) {
        Type elementType = arrayType.getElementType();
        SchemaType internalType = getSchemaTypeForField(elementType);

        SchemaType returnType = getNonNullType();
        SchemaType ofType = new SchemaType(null, TypeKind.LIST);
        ofType.setOfType(internalType);
        returnType.setOfType(ofType);
        return returnType;
    }

    private SchemaType getSchemaTypeForUnionType(UnionType unionType) {
        Type mainType = getNonNullNonErrorTypeFromUnion(unionType.getMemberTypes());
        SchemaType schemaType = getSchemaTypeForField(mainType);
        return schemaType.getOfType();
    }

    private SchemaType createSchemaTypeForRecordType(RecordType recordType) {
        Collection<Field> fields = recordType.getFields().values();
        SchemaType schemaType = new SchemaType(recordType.getName(), TypeKind.OBJECT);
        for (Field field : fields) {
            SchemaField schemaField = new SchemaField(field.getFieldName());
            SchemaType fieldType = getSchemaTypeForField(field.getFieldType());
            if (SymbolFlags.isFlagOn(field.getFlags(), SymbolFlags.OPTIONAL)) {
                schemaField.setType(fieldType.getOfType());
            } else {
                schemaField.setType(fieldType);
            }
            schemaType.addField(schemaField);
        }
        return schemaType;
    }

    private SchemaType createSchemaTypeForTableType(TableType tableType) {
        Type constrainedType = tableType.getConstrainedType();
        SchemaType internalType = getSchemaTypeForField(constrainedType);

        SchemaType returnType = getNonNullType();
        SchemaType ofType = new SchemaType(null, TypeKind.LIST);
        ofType.setOfType(internalType);
        returnType.setOfType(ofType);
        return returnType;
    }

    private void addArgumentsForSchemaField(ResourceMethodType resourceMethod, SchemaField field) {
        Type[] parameterTypes = resourceMethod.getParameterTypes();
        String[] parameterNames = resourceMethod.getParamNames();

        if (parameterNames.length == 0) {
            return;
        }
        // TODO: Handle default values (https://github.com/ballerina-platform/ballerina-lang/issues/27417)
        for (int i = 0; i < parameterNames.length; i++) {
            field.addArg(getInputValue(parameterNames[i], parameterTypes[i]));
        }
    }

    private InputValue getInputValue(String name, Type type) {
        SchemaType inputType = getSchemaTypeForField(type);
        // TODO: Handle record fields. Records can't be inputs yet
        return new InputValue(name, inputType);
    }

    private static SchemaType getNonNullType() {
        return new SchemaType(null, TypeKind.NON_NULL);
    }
}
