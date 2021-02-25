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
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.stdlib.graphql.utils.Utils;

import java.util.Collection;
import java.util.List;

import static io.ballerina.stdlib.graphql.utils.Utils.createError;

/**
 * This class is used to generate a tree for the GraphQL schema for a given Ballerina GraphQL service.
 */
public class TreeGenerator {

    public static Node createNodeForService(String name, ServiceType serviceType) {
        Node serviceNode = new Node(name, serviceType);
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            serviceNode.addChild(createNodeForResource(resourceMethod, resourceMethod.getResourcePath(), serviceNode));
        }
        return serviceNode;
    }

    public static Node createNodeForResource(ResourceMethodType resourceMethod, String[] resourcePath, Node parent) {
        if (resourcePath == null || resourcePath.length == 0) {
            String message = "Invalid resource path found for the resource";
            throw createError(message, Utils.ErrorCode.NotSupportedError);
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

        Node resourceNode = createNodeForType(name, resourceMethod.getType().getReturnType());
        addArgumentsForResourceNode(resourceNode, resourceMethod);
        return resourceNode;
    }

    private static Node createNodeForType(String name, Type type) {
        int tag = type.getTag();
        if (tag == TypeTags.STRING_TAG || tag == TypeTags.INT_TAG || tag == TypeTags.FLOAT_TAG ||
                tag == TypeTags.DECIMAL_TAG || tag == TypeTags.BOOLEAN_TAG) {
            return new Node(name, type, false);
        } else if (tag == TypeTags.RECORD_TYPE_TAG) {
            return createNodeForRecordType(name, (RecordType) type, false);
        } else if (tag == TypeTags.SERVICE_TAG) {
            ServiceType serviceType = (ServiceType) type;
            String serviceName = serviceType.getName();
            if (serviceName.startsWith("$")) {
                String message = "Returning anonymous service objects are not supported by GraphQL resources";
                throw createError(message, Utils.ErrorCode.NotSupportedError);
            }
            return createNodeForService(name, serviceType);
        } else if (tag == TypeTags.UNION_TAG) {
            return createNodeForUnionType(name, (UnionType) type);
        } else if (tag == TypeTags.ARRAY_TAG) {
            ArrayType arrayType = (ArrayType) type;
            Type elementType = arrayType.getElementType();
            Node node = createNodeForType(name, elementType);
            node.setType(arrayType);
            return node;
        } else {
            String message = "Unsupported type found: " + type.getName();
            throw createError(message, Utils.ErrorCode.NotSupportedError);
        }
    }

    private static Node createNodeForRecordType(String name, RecordType recordType, boolean nullable) {
        Collection<Field> fields = recordType.getFields().values();
        Node recordNode = new Node(name, recordType, nullable);
        for (Field field : fields) {
            recordNode.addChild(createNodeForType(field.getFieldName(), field.getFieldType()));
        }
        return recordNode;
    }

    private static void addArgumentsForResourceNode(Node resourceNode, ResourceMethodType resourceMethod) {
        String[] paramNames = resourceMethod.getParamNames();
        Type[] paramTypes = resourceMethod.getParameterTypes();
        for (int i = 0; i < paramNames.length; i++) {
            resourceNode.addArgument(paramNames[i], paramTypes[i]);
        }
    }

    private static Node createNodeForUnionType(String name, UnionType unionType) {
        // TODO: Finite Type?
        List<Type> memberTypes = unionType.getMemberTypes();
        Type type = getNonNullNonErrorTypeFromUnion(memberTypes);
        Node unionTypeNode = createNodeForType(name, type);
        unionTypeNode.setType(unionType);
        unionTypeNode.setNullable(isNullable(unionType));
        return unionTypeNode;
    }

    private static Type getNonNullNonErrorTypeFromUnion(List<Type> memberTypes) {
        int count = 0;
        Type resultType = null;
        for (Type type : memberTypes) {
            if (type.getTag() != TypeTags.ERROR_TAG && type.getTag() != TypeTags.NULL_TAG) {
                count++;
                resultType = type;
            }
        }
        if (count != 1) {
            String message =
                    "Unsupported union: If a field type is a union, it should be subtype of \"<T>|error?\", except " +
                            "\"error?\"";
            throw createError(message, Utils.ErrorCode.NotSupportedError);
        }
        return resultType;
    }

    private static boolean isNullable(UnionType unionType) {
        for (Type type : unionType.getMemberTypes()) {
            if (type.getTag() == TypeTags.NULL_TAG) {
                return true;
            }
        }
        return false;
    }

    private static String[] removeFirstElementFromArray(String[] array) {
        int length = array.length - 1;
        String[] result = new String[length];
        System.arraycopy(array, 1, result, 0, length);
        return result;
    }
}
