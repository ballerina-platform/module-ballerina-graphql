/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.graphql.runtime.engine.meta;

import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.RemoteMethodType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.StreamType;
import io.ballerina.runtime.api.types.TableType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.graphql.runtime.utils.Utils;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.MUTATION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.QUERY;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SUBSCRIBE_ACCESSOR;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.SUBSCRIPTION;
import static io.ballerina.stdlib.graphql.runtime.utils.ModuleUtils.getModule;

/**
 * This class analyzes the Ballerina service and extracts the meta information.
 */
public class ServiceAnalyzer {

    private static final BString packageName = StringUtils.fromString(getModule().toString());
    private static final BString serviceConfigName = StringUtils.fromString("ServiceConfig");
    private static final BString resourceConfigName = StringUtils.fromString("ResourceConfig");
    private static final BString queryComplexityConfigKey = StringUtils.fromString("queryComplexityConfig");
    private static final BString defaultComplexityKey = StringUtils.fromString("defaultFieldComplexity");
    private static final BString complexityKey = StringUtils.fromString("complexity");

    private final Map<String, Resource> resourceMap;
    private final ServiceType serviceType;
    private final Long defaultQueryComplexity;
    private final Set<Type> visitedTypes = new HashSet<>();

    public ServiceAnalyzer(ServiceType serviceType) {
        this.resourceMap = new HashMap<>();
        this.serviceType = serviceType;
        BMap<BString, Object> serviceConfig = getServiceConfig(serviceType);
        this.defaultQueryComplexity = getDefaultQueryComplexity(serviceConfig);
    }

    public void analyze() {
        for (ResourceMethodType resourceMethod : this.serviceType.getResourceMethods()) {
            String typeName = getRootTypeName(resourceMethod);
            analyzeResourceMethod(resourceMethod, typeName);
        }

        for (RemoteMethodType remoteMethod : this.serviceType.getRemoteMethods()) {
            String coordinate = MUTATION + "." + remoteMethod.getName();
            analyzeRemoteMethod(remoteMethod, coordinate);
        }
    }

    private void analyzeResourceMethod(ResourceMethodType resourceMethod, String typeName) {
        String coordinate = getSchemaCoordinate(typeName, resourceMethod);
        if (this.resourceMap.containsKey(coordinate)) {
            return;
        }
        BMap<BString, Object> resourceConfig = getResourceConfig(resourceMethod);
        Long complexity = getComplexity(coordinate, resourceConfig);
        Resource resource = new Resource(complexity);
        this.resourceMap.put(coordinate, resource);
        analyzeType(resourceMethod.getType().getReturnType());
    }

    private void analyzeRemoteMethod(RemoteMethodType remoteMethod, String coordinate) {
        BMap<BString, Object> resourceConfig = getResourceConfig(remoteMethod);
        Long complexity = getComplexity(coordinate, resourceConfig);
        Resource resource = new Resource(complexity);
        this.resourceMap.put(coordinate, resource);
        analyzeType(remoteMethod.getType().getReturnType());
    }

    private void analyzeType(Type type) {
        Type impliedType = TypeUtils.getImpliedType(type);
        if (!visitedTypes.add(impliedType)) {
            return;
        }

        try {
            switch (impliedType.getTag()) {
                case TypeTags.SERVICE_TAG:
                    analyzeServiceType((ServiceType) impliedType);
                    break;
                case TypeTags.UNION_TAG:
                    analyzeUnionType((UnionType) impliedType);
                    break;
                case TypeTags.ARRAY_TAG:
                    analyzeType(((ArrayType) impliedType).getElementType());
                    break;
                case TypeTags.TABLE_TAG:
                    analyzeType(((TableType) impliedType).getConstrainedType());
                    break;
                case TypeTags.RECORD_TYPE_TAG:
                    analyzeRecordType((RecordType) impliedType);
                    break;
                case TypeTags.MAP_TAG:
                    analyzeType(((MapType) impliedType).getConstrainedType());
                    break;
                case TypeTags.STREAM_TAG:
                    analyzeType(((StreamType) impliedType).getConstrainedType());
                    break;
                default:
                    break;
            }
        } finally {
            visitedTypes.remove(impliedType);
        }
    }

    private void analyzeServiceType(ServiceType serviceType) {
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            String typeName = serviceType.getName();
            analyzeResourceMethod(resourceMethod, typeName);
        }
    }

    private void analyzeUnionType(UnionType unionType) {
        for (Type memberType : unionType.getMemberTypes()) {
            if (memberType.getTag() != TypeTags.NULL_TAG || memberType.getTag() != TypeTags.ERROR_TAG) {
                analyzeType(memberType);
            }
        }
    }

    private void analyzeRecordType(RecordType recordType) {
        String typeName = recordType.getName();
        for (Field field : recordType.getFields().values()) {
            String coordinate = typeName + "." + field.getFieldName();
            Resource resource = new Resource(defaultQueryComplexity);
            this.resourceMap.put(coordinate, resource);
            analyzeType(field.getFieldType());
        }
    }

    public Map<String, Resource> getResourceMap() {
        return this.resourceMap;
    }

    private Long getComplexity(String coordinate, BMap<BString, Object> resourceConfig) {
        if (resourceConfig == null) {
            return this.defaultQueryComplexity;
        }
        if (resourceConfig.containsKey(complexityKey)) {
            Long complexity = (Long) resourceConfig.get(complexityKey);
            if (complexity < 0) {
                String message = "Complexity of the field \"" + coordinate + "\" cannot be negative";
                throw Utils.createError(message, Utils.ERROR_TYPE);
            }
            return (Long) resourceConfig.get(complexityKey);
        }
        return this.defaultQueryComplexity;
    }

    private static String getRootTypeName(ResourceMethodType resourceMethod) {
        if (resourceMethod.getAccessor().equals(SUBSCRIBE_ACCESSOR)) {
            return SUBSCRIPTION;
        }
        return QUERY;
    }

    private static String getSchemaCoordinate(String typeName, ResourceMethodType resourceMethodType) {
        String[] resourcePath = resourceMethodType.getResourcePath();
        if (resourcePath.length == 1) {
            return typeName + "." + resourcePath[0];
        }
        int length = resourcePath.length;
        return resourcePath[length - 2] + "." + resourcePath[length - 1];
    }

    @SuppressWarnings("unchecked")
    private static Long getDefaultQueryComplexity(BMap<BString, Object> serviceConfig) {
        if (serviceConfig == null) {
            return 0L;
        }
        Object queryComplexityConfig = serviceConfig.get(queryComplexityConfigKey);
        if (queryComplexityConfig == null) {
            return 0L;
        }
        BMap<BString, Object> queryComplexityConfigMap = (BMap<BString, Object>) queryComplexityConfig;
        return (Long) queryComplexityConfigMap.get(defaultComplexityKey);
    }

    @SuppressWarnings("unchecked")
    private static BMap<BString, Object> getServiceConfig(ServiceType serviceType) {
        Object annotation = serviceType.getAnnotation(packageName, serviceConfigName);
        if (annotation == null) {
            return null;
        }
        return (BMap<BString, Object>) annotation;
    }

    @SuppressWarnings("unchecked")
    private static BMap<BString, Object> getResourceConfig(MethodType method) {
        Object resourceConfig = method.getAnnotation(packageName, resourceConfigName);
        if (resourceConfig == null) {
            return null;
        }
        return (BMap<BString, Object>) resourceConfig;
    }
}
