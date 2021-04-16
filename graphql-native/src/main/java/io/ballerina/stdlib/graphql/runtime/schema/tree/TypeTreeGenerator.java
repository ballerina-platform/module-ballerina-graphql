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

package io.ballerina.stdlib.graphql.runtime.schema.tree;

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

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.BOOLEAN;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.DECIMAL;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FLOAT;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.INTEGER;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.QUERY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.STRING;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.INVALID_TYPE_ERROR;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.NOT_SUPPORTED_ERROR;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.createError;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.removeFirstElementFromArray;

/**
 * Generates a tree of types found in a ballerina service.
 *
 * @since 0.2.0
 */
public class TypeTreeGenerator {
    private final ServiceType serviceType;
    private final SchemaGenerator schemaGenerator;

    public TypeTreeGenerator(SchemaGenerator schemaGenerator) {
        this.serviceType = schemaGenerator.getServiceType();
        this.schemaGenerator = schemaGenerator;
    }

    public Node generateTypeTree() {
        return createNodeForService(QUERY, serviceType);
    }

    private Node createNodeForService(String name, ServiceType serviceType) {
        Node serviceNode = new Node(name);
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            serviceNode.addChild(createNodeForResource(resourceMethod, resourceMethod.getResourcePath(),
                                                       serviceNode));
        }
        return serviceNode;
    }

    private Node createNodeForResource(ResourceMethodType resourceMethod, String[] resourcePath, Node parent) {
        if (resourcePath == null || resourcePath.length == 0) {
            String message = "Invalid resource path found for the resource";
            throw createError(message, INVALID_TYPE_ERROR);
        }

        String name = resourcePath[0];
        if (resourcePath.length > 1) {
            String[] paths = removeFirstElementFromArray(resourcePath);
            Node resourceNode;
            if (parent.hasChild(name)) {
                resourceNode = parent.getChild(name);
            } else {
                resourceNode = new Node(name);
            }
            resourceNode.addChild(createNodeForResource(resourceMethod, paths, resourceNode));
            return resourceNode;
        }
        Type[] inputTypes = resourceMethod.getParameterTypes();
        for (Type inputType : inputTypes) {
            schemaGenerator.addType(schemaGenerator.getSchemaTypeFromType(inputType));
        }
        Node returnTypeNode = createNodeForType(name, resourceMethod.getType().getReturnType());
        return new Node(name, null, returnTypeNode);
    }

    private Node createNodeForType(String name, Type type) {
        int tag = type.getTag();
        if (tag == TypeTags.STRING_TAG || tag == TypeTags.INT_TAG || tag == TypeTags.FLOAT_TAG ||
                tag == TypeTags.DECIMAL_TAG || tag == TypeTags.BOOLEAN_TAG) {
            return new Node(getScalarTypeName(tag), type);
        } else if (tag == TypeTags.RECORD_TYPE_TAG) {
            return createNodeForRecordType(name, (RecordType) type);
        } else if (tag == TypeTags.SERVICE_TAG) {
            ServiceType serviceType = (ServiceType) type;
            String serviceName = serviceType.getName();
            if (serviceName.startsWith("$")) {
                String message = "Returning anonymous service objects are not supported by GraphQL resources";
                throw createError(message, NOT_SUPPORTED_ERROR);
            }
            return createNodeForService(serviceName, serviceType);
        } else if (tag == TypeTags.ARRAY_TAG) {
            ArrayType arrayType = (ArrayType) type;
            Type elementType = arrayType.getElementType();
            return createNodeForType(name, elementType);
        } else if (tag == TypeTags.UNION_TAG) {
            return createNodeForUnionType(name, (UnionType) type);
        } else if (tag == TypeTags.TABLE_TAG) {
            TableType tableType = (TableType) type;
            return createNodeForTableType(name, tableType);
        } else {
            String message = "Unsupported type found: " + type.getName();
            throw createError(message, NOT_SUPPORTED_ERROR);
        }
    }

    private Node createNodeForRecordType(String name, RecordType recordType) {
        Collection<Field> fields = recordType.getFields().values();
        Node recordNode = new Node(name, recordType);
        for (Field field : fields) {
            Node fieldNode = createNodeForType(field.getFieldName(), field.getFieldType());
            recordNode.addChild(fieldNode);
        }
        return recordNode;
    }

    private Node createNodeForUnionType(String name, UnionType unionType) {
        Type type = getNonNullNonErrorTypeFromUnion(unionType);
        if (type.getTag() == TypeTags.UNION_TAG) {
            return new Node(type.getName(), type);
        }
        return createNodeForType(name, type);
    }

    private Node createNodeForTableType(String name, TableType tableType) {
        Type constrainedType = tableType.getConstrainedType();
        Node tableNode = new Node(name, tableType);
        Node node = createNodeForType(constrainedType.getName(), constrainedType);
        tableNode.addChild(node);
        return tableNode;
    }

    public static Type getNonNullNonErrorTypeFromUnion(UnionType unionType) {
        int count = 0;
        Type resultType = null;
        List<Type> memberTypes = getMemberTypes(unionType);
        for (Type type : memberTypes) {
            if (type.getTag() != TypeTags.ERROR_TAG && type.getTag() != TypeTags.NULL_TAG) {
                count++;
                resultType = type;
            }
        }
        if (count != 1) {
            String message =
                    "Unsupported union: If a field type is a union, it should be a subtype of \"<T>|error?\", except " +
                            "\"error?\"";
            throw createError(message, NOT_SUPPORTED_ERROR);
        }
        return resultType;
    }

    private static List<Type> getMemberTypes(UnionType unionType) {
        List<Type> members = new ArrayList<>();
        if (SymbolFlags.isFlagOn(unionType.getFlags(), SymbolFlags.ENUM)) {
            members.add(unionType);
        } else {
            List<Type> originalMembers = unionType.getOriginalMemberTypes();
            for (Type type : originalMembers) {
                if (type.getTag() == TypeTags.UNION_TAG) {
                    members.addAll(getMemberTypes((UnionType) type));
                } else {
                    members.add(type);
                }
            }
        }
        return members;
    }

    public static String getScalarTypeName(int tag) {
        if (tag == TypeTags.INT_TAG) {
            return INTEGER;
        } else if (tag == TypeTags.DECIMAL_TAG) {
            return DECIMAL;
        } else if (tag == TypeTags.FLOAT_TAG) {
            return FLOAT;
        } else if (tag == TypeTags.BOOLEAN_TAG) {
            return BOOLEAN;
        } else {
            return STRING;
        }
    }
}
