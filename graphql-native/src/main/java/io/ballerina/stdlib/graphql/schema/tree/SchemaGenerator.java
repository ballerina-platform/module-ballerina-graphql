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
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.TableType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.stdlib.graphql.schema.Schema;
import io.ballerina.stdlib.graphql.schema.SchemaField;
import io.ballerina.stdlib.graphql.schema.SchemaType;
import io.ballerina.stdlib.graphql.schema.TypeKind;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

import static io.ballerina.stdlib.graphql.schema.tree.TypeTreeGenerator.getNonNullNonErrorTypeFromUnion;
import static io.ballerina.stdlib.graphql.schema.tree.TypeTreeGenerator.getScalarTypeName;
import static io.ballerina.stdlib.graphql.utils.Utils.INVALID_TYPE_ERROR;
import static io.ballerina.stdlib.graphql.utils.Utils.NOT_SUPPORTED_ERROR;
import static io.ballerina.stdlib.graphql.utils.Utils.createError;

/**
 * Generates a GraphQL schema from a Ballerina service.
 *
 * @since 0.2.0
 */
public class SchemaGenerator {
    private ServiceType serviceType;
    private Map<String, SchemaType> typeMap;

    public SchemaGenerator(ServiceType serviceType) {
        this.serviceType = serviceType;
        this.typeMap = new HashMap<>();
    }

    public Schema generate() {
        this.populateBasicTypes();
        return this.generateSchema();
    }

    public Schema generateSchema() {
        Schema schema = new Schema();
        SchemaTreeGenerator schemaTreeGenerator = new SchemaTreeGenerator(this.serviceType, this.typeMap);
        SchemaType queryType = schemaTreeGenerator.getQueryType();
        schema.setQueryType(queryType);
        for (SchemaType schemaType : this.typeMap.values()) {
            schema.addType(schemaType);
        }
        return schema;
    }

    private void populateBasicTypes() {
        TypeTreeGenerator typeTreeGenerator = new TypeTreeGenerator(this.serviceType);
        Node node = typeTreeGenerator.generateTypeTree();
        populateTypesMap(node);
    }

    private void addType(SchemaType schemaType) {
        this.typeMap.put(schemaType.getName(), schemaType);
    }

    private SchemaType populateTypesMap(Node node) {
        if (node.getChildren() == null || node.getChildren().size() == 0) {
            Type type = node.getType();
            if (type == null) {
                // This code shouldn't be reached
                String message = "Type not found for the resource: " + node.getName();
                throw createError(message, INVALID_TYPE_ERROR);
            } else {
                return getSchemaTypeFromType(type);
            }
        } else {
            for (Node childNode : node.getChildren().values()) {
                populateTypesMap(childNode);
            }
            Type type = node.getType();
            if (type == null) {
                SchemaType schemaType = getSchemaTypeForHierarchicalResource(node);
                this.addType(schemaType);
                return schemaType;
            } else {
                return getSchemaTypeFromType(type);
            }
        }
    }

    private SchemaType getSchemaTypeFromType(Type type) {
        int tag = type.getTag();
        SchemaType schemaType;

        if (tag == TypeTags.INT_TAG || tag == TypeTags.STRING_TAG || tag == TypeTags.DECIMAL_TAG ||
                tag == TypeTags.BOOLEAN_TAG || tag == TypeTags.FLOAT_TAG) {
            String name = getScalarTypeName(tag);
            if (this.typeMap.containsKey(name)) {
                schemaType = this.typeMap.get(name);
            } else {
                schemaType = new SchemaType(name, TypeKind.SCALAR);
            }
        } else if (tag == TypeTags.RECORD_TYPE_TAG) {
            RecordType recordType = (RecordType) type;
            String name = recordType.getName();
            if (this.typeMap.containsKey(name)) {
                schemaType = this.typeMap.get(name);
            } else {
                schemaType = new SchemaType(name, TypeKind.OBJECT);
                Collection<Field> fields = recordType.getFields().values();
                for (Field field : fields) {
                    schemaType.addField(getSchemaFieldFromRecordField(field));
                }
            }
        } else if (tag == TypeTags.ARRAY_TAG) {
            ArrayType arrayType = (ArrayType) type;
            return getSchemaTypeFromType(arrayType.getElementType());
        } else if (tag == TypeTags.TABLE_TAG) {
            TableType tableType = (TableType) type;
            return getSchemaTypeFromType(tableType.getConstrainedType());
        } else if (tag == TypeTags.UNION_TAG) {
            UnionType unionType = (UnionType) type;
            Type mainType = getNonNullNonErrorTypeFromUnion(unionType.getMemberTypes());
            return getSchemaTypeFromType(mainType);
        } else {
            String message = "Unsupported type for schema field: " + type.getName();
            throw createError(message, NOT_SUPPORTED_ERROR);
        }

        this.addType(schemaType);
        return schemaType;
    }

    private SchemaField getSchemaFieldFromRecordField(Field field) {
        SchemaField schemaField = new SchemaField(field.getFieldName());
        schemaField.setType(getSchemaTypeFromType(field.getFieldType()));
        return schemaField;
    }

    private SchemaType getSchemaTypeForHierarchicalResource(Node node) {
        SchemaType schemaType = new SchemaType(node.getName(), TypeKind.OBJECT);
        for (Node childNode : node.getChildren().values()) {
            SchemaField childField = new SchemaField(childNode.getName());
            childField.setType(populateTypesMap(childNode));
            schemaType.addField(childField);
        }
        return schemaType;
    }
}
