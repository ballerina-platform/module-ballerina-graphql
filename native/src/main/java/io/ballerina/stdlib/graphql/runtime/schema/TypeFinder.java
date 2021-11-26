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
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.Parameter;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.RemoteMethodType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.TableType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.stdlib.graphql.runtime.schema.types.SchemaType;
import io.ballerina.stdlib.graphql.runtime.schema.types.TypeKind;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.MUTATION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.QUERY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SCHEMA_RECORD;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.getMemberTypes;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.getScalarTypeName;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.getTypeName;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.getTypeNameFromType;
import static io.ballerina.stdlib.graphql.runtime.schema.Utils.isEnum;
import static io.ballerina.stdlib.graphql.runtime.utils.ModuleUtils.getModule;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.ERROR_TYPE;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.createError;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.isContext;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.removeFirstElementFromArray;

/**
 * Finds types used in a Ballerina GraphQL service to Generate the Schema.
 */
public class TypeFinder {
    private final ServiceType serviceType;
    Map<String, SchemaType> typeMap;

    public TypeFinder(ServiceType serviceType) {
        this.serviceType = serviceType;
        this.typeMap = new HashMap<>();
    }

    public Map<String, SchemaType> getTypeMap() {
        return this.typeMap;
    }

    public void populateTypes() {
        this.createTypesFromRootService();
        this.getDefaultTypes();
    }

    private void getDefaultTypes() {
        Type schemaRecordType = ValueCreator.createRecordValue(getModule(), SCHEMA_RECORD).getType();
        getSchemaTypeFromBalType(schemaRecordType);
    }

    private void createTypesFromRootService() {
        this.createSchemaType(QUERY, TypeKind.OBJECT, serviceType);
        for (ResourceMethodType resourceMethod : this.serviceType.getResourceMethods()) {
            getTypesFromResourceMethod(resourceMethod, resourceMethod.getResourcePath());
        }
        if (this.serviceType.getRemoteMethods().length > 0) {
            this.createSchemaType(MUTATION, TypeKind.OBJECT, serviceType);
            for (RemoteMethodType remoteMethod : serviceType.getRemoteMethods()) {
                getTypesFromRemoteMethod(remoteMethod);
            }
        }
    }

    private void getTypesFromService(String name, ServiceType serviceType) {
        this.createSchemaType(name, TypeKind.OBJECT, serviceType);
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            getTypesFromResourceMethod(resourceMethod, resourceMethod.getResourcePath());
        }
    }

    private void getTypesFromResourceMethod(ResourceMethodType resourceMethod, String[] resourcePath) {
        if (resourcePath.length > 1) {
            getTypesFromHierarchicalResource(resourceMethod, resourcePath);
        } else {
            getInputTypesFromMethod(resourceMethod);
            getSchemaTypeFromBalType(resourceMethod.getType().getReturnType());
        }
    }

    private void getTypesFromRemoteMethod(RemoteMethodType remoteMethod) {
        getInputTypesFromMethod(remoteMethod);
        getSchemaTypeFromBalType(remoteMethod.getType().getReturnType());
    }

    private void getTypesFromHierarchicalResource(ResourceMethodType resourceMethod, String[] resourcePath) {
        String name = resourcePath[0];
        this.createSchemaType(name, TypeKind.OBJECT, resourceMethod);
        String[] remainingPaths = removeFirstElementFromArray(resourcePath);
        this.getTypesFromResourceMethod(resourceMethod, remainingPaths);
    }

    private void getInputTypesFromMethod(MethodType methodType) {
        for (Parameter parameter : methodType.getParameters()) {
            if (parameter.type.getTag() == TypeTags.RECORD_TYPE_TAG) {
                getInputObjectSchemaType(parameter.type);
            } else {
                getSchemaTypeFromBalType(parameter.type);
            }
        }
    }

    private void getInputObjectSchemaType(Type type) {
        if (!this.typeMap.containsKey(type.getName())) {
            RecordType recordType = (RecordType) type;
            this.createSchemaType(recordType.getName(), TypeKind.INPUT_OBJECT, recordType);
            for (Field field : recordType.getFields().values()) {
                int tag = field.getFieldType().getTag();
                if (tag == TypeTags.RECORD_TYPE_TAG) {
                    getInputObjectSchemaType(field.getFieldType());
                } else {
                    getSchemaTypeFromBalType(field.getFieldType());
                }
            }
        }
    }

    private void getSchemaTypeFromBalType(Type type) {
        int tag = type.getTag();
        if (this.typeMap.containsKey(type.getName())) {
            return;
        }
        if (tag < TypeTags.JSON_TAG) {
            String name = getScalarTypeName(tag);
            this.createSchemaType(name, TypeKind.SCALAR, type);
        } else if (tag == TypeTags.RECORD_TYPE_TAG) {
            RecordType recordType = (RecordType) type;
            this.createSchemaType(recordType.getName(), TypeKind.OBJECT, recordType);
            for (Field field : recordType.getFields().values()) {
                getSchemaTypeFromBalType(field.getFieldType());
            }
        } else if (tag == TypeTags.SERVICE_TAG) {
            ServiceType serviceType = (ServiceType) type;
            getTypesFromService(serviceType.getName(), serviceType);
        } else if (tag == TypeTags.ARRAY_TAG) {
            ArrayType arrayType = (ArrayType) type;
            Type elementType = arrayType.getElementType();
            getSchemaTypeFromBalType(elementType);
        } else if (tag == TypeTags.TABLE_TAG) {
            TableType tableType = (TableType) type;
            Type constrainedType = tableType.getConstrainedType();
            getSchemaTypeFromBalType(constrainedType);
        } else if (tag == TypeTags.UNION_TAG) {
            UnionType unionType = (UnionType) type;
            getTypesFromUnionType(unionType);
        } else if (tag == TypeTags.MAP_TAG) {
            MapType mapType = (MapType) type;
            Type constrainedType = mapType.getConstrainedType();
            getSchemaTypeFromBalType(constrainedType);
        } else if (tag == TypeTags.INTERSECTION_TAG) {
            IntersectionType intersectionType = (IntersectionType) type;
            Type effectiveType = intersectionType.getEffectiveType();
            getSchemaTypeFromBalType(effectiveType);
        } else if (isContext(type)) {
            // Do nothing
        } else {
            String message = "Unsupported type found in GraphQL service: " + type.getName();
            throw createError(message, ERROR_TYPE);
        }
    }

    private void getTypesFromUnionType(UnionType unionType) {
        if (isEnum(unionType)) {
            this.createSchemaType(getTypeNameFromType(unionType), TypeKind.ENUM, unionType);
        } else {
            List<Type> memberTypes = getMemberTypes(unionType);
            if (memberTypes.size() == 1) {
                getSchemaTypeFromBalType(memberTypes.get(0));
            } else {
                String typeName = getTypeName(unionType);
                this.createSchemaType(typeName, TypeKind.UNION, unionType);
            }
            for (Type type : memberTypes) {
                if (type.getTag() != TypeTags.ERROR_TAG && type.getTag() != TypeTags.NULL_TAG) {
                    getSchemaTypeFromBalType(type);
                }
            }
        }
    }

    private void createSchemaType(String name, TypeKind typeKind, Type type) {
        if (!this.typeMap.containsKey(name)) {
            SchemaType schemaType = new SchemaType(name, typeKind, type);
            this.typeMap.put(name, schemaType);
        }
    }
}
