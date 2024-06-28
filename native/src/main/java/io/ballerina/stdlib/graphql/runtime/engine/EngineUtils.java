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

package io.ballerina.stdlib.graphql.runtime.engine;

import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.flags.SymbolFlags;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BValue;
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.commons.utils.SdlSchemaStringGenerator;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.runtime.api.TypeTags.SERVICE_TAG;
import static io.ballerina.stdlib.graphql.runtime.engine.Engine.getDecodedSchema;

/**
 * This class provides utility functions for Ballerina GraphQL engine.
 */
@SuppressWarnings("unchecked")
public class EngineUtils {

    private EngineUtils() {
    }

    // Schema related record types
    public static final String SCHEMA_RECORD = "__Schema";
    public static final String FIELD_RECORD = "__Field";
    public static final String TYPE_RECORD = "__Type";
    public static final String INPUT_VALUE_RECORD = "__InputValue";
    public static final String ENUM_VALUE_RECORD = "__EnumValue";
    public static final String DIRECTIVE_RECORD = "__Directive";
    public static final String DIRECTIVE_LOCATION_ENUM = "__DirectiveLocation";

    // Schema related record field names
    public static final BString QUERY_TYPE_FIELD = StringUtils.fromString("queryType");
    public static final BString MUTATION_TYPE_FIELD = StringUtils.fromString("mutationType");
    public static final BString SUBSCRIPTION_TYPE_FIELD = StringUtils.fromString("subscriptionType");
    public static final BString TYPES_FIELD = StringUtils.fromString("types");
    public static final BString TYPE_FIELD = StringUtils.fromString("type");
    public static final BString NAME_FIELD = StringUtils.fromString("name");
    public static final BString DESCRIPTION_FIELD = StringUtils.fromString("description");
    public static final BString DEPRECATION_REASON_FIELD = StringUtils.fromString("deprecationReason");
    public static final BString IS_DEPRECATED_FIELD = StringUtils.fromString("isDeprecated");
    public static final BString DIRECTIVES_FIELD = StringUtils.fromString("directives");
    public static final BString KIND_FIELD = StringUtils.fromString("kind");
    public static final BString FIELDS_FIELD = StringUtils.fromString("fields");
    public static final BString ARGS_FIELD = StringUtils.fromString("args");
    public static final BString DEFAULT_VALUE_FIELD = StringUtils.fromString("defaultValue");
    public static final BString ENUM_VALUES_FIELD = StringUtils.fromString("enumValues");
    public static final BString INPUT_FIELDS_FIELD = StringUtils.fromString("inputFields");
    public static final BString OF_TYPE_FIELD = StringUtils.fromString("ofType");
    public static final BString POSSIBLE_TYPES_FIELD = StringUtils.fromString("possibleTypes");
    public static final BString INTERFACES_FIELD = StringUtils.fromString("interfaces");
    public static final BString VARIABLE_VALUE_FIELD = StringUtils.fromString("variableValue");
    public static final BString VARIABLE_DEFINITION = StringUtils.fromString("variableDefinition");
    public static final String QUERY = "Query";
    public static final String MUTATION = "Mutation";
    public static final String SUBSCRIPTION = "Subscription";

    //Accessor names
    public static final String GET_ACCESSOR = "get";
    public static final String SUBSCRIBE_ACCESSOR = "subscribe";
    public static final String INTERCEPTOR_EXECUTE = "execute";

    public static final BString LOCATIONS_FIELD = StringUtils.fromString("locations");
    static final BString ARGUMENTS_FIELD = StringUtils.fromString("arguments");
    static final BString VALUE_FIELD = StringUtils.fromString("value");
    static final BString VARIABLE_NAME_FIELD = StringUtils.fromString("variableName");

    // Native Data Fields
    public static final String GRAPHQL_SERVICE_OBJECT = "graphql.service.object";
    public static final String FIELD_OBJECT = "field.object";

    public static final String FILE_INFO_FIELD = "graphql.context.fileInfo";
    public static final BString HAS_FILE_INFO_FIELD = StringUtils.fromString("hasFileInfo");
    public static final BString RESULT_FIELD = StringUtils.fromString("result");

    // Resource annotation
    public static final String RESOURCE_CONFIG = "ResourceConfig";
    public static final String COLON = ":";

    // Root operation types
    public static final String OPERATION_QUERY = "query";
    public static final String OPERATION_SUBSCRIPTION = "subscription";

    static boolean isPathsMatching(ResourceMethodType resourceMethod, List<String> paths) {
        String[] resourcePath = resourceMethod.getResourcePath();
        if (resourcePath.length != paths.size()) {
            return false;
        }

        for (int i = 0; i < resourcePath.length; i++) {
            if (!resourcePath[i].equals(paths.get(i))) {
                return false;
            }
        }
        return true;
    }

    public static boolean isEnum(UnionType unionType) {
        return SymbolFlags.isFlagOn(unionType.getFlags(), SymbolFlags.ENUM);
    }

    public static List<Type> getMemberTypes(UnionType unionType) {
        List<Type> members = new ArrayList<>();
        if (isEnum(unionType)) {
            members.add(unionType);
        } else {
            List<Type> originalMembers = unionType.getOriginalMemberTypes();
            for (Type type : originalMembers) {
                if (isIgnoreType(type)) {
                    continue;
                }
                if (type.getTag() == TypeTags.UNION_TAG) {
                    members.addAll(getMemberTypes((UnionType) type));
                } else {
                    members.add(type);
                }
            }
        }
        return members;
    }

    public static BArray getArrayTypeFromBMap(BMap<BString, Object> recordValue) {
        ArrayType arrayType = TypeCreator.createArrayType(recordValue.getType());
        return ValueCreator.createArrayValue(arrayType);
    }

    public static boolean isIgnoreType(Type type) {
        return type.getTag() == TypeTags.ERROR_TAG || type.getTag() == TypeTags.NULL_TAG;
    }

    public static void addService(BObject engine, BObject service) {
        engine.addNativeData(GRAPHQL_SERVICE_OBJECT, service);
    }

    public static BObject getService(BObject engine) {
        return (BObject) engine.getNativeData(GRAPHQL_SERVICE_OBJECT);
    }

    public static void setFileInfo(BObject context, BMap<BString, Object> fileInfo) {
        context.addNativeData(FILE_INFO_FIELD, fileInfo);
        context.set(HAS_FILE_INFO_FIELD, true);
    }

    public static BMap<BString, Object> getFileInfo(BObject context) {
        return (BMap<BString, Object>) context.getNativeData(FILE_INFO_FIELD);
    }

    public static boolean isMap(BMap<BString, Object> value) {
        Type type =  TypeUtils.getReferredType(value.getType());
        type = type.getTag() == TypeTags.INTERSECTION_TAG ? ((IntersectionType) type).getEffectiveType() : type;
        return type.getTag() == TypeTags.MAP_TAG;
    }

    public static BString getTypeNameFromValue(BValue bValue) {
        if (bValue.getType().getTag() == TypeTags.INTERSECTION_TAG) {
            return StringUtils.fromString(getTypeNameFromIntersection((IntersectionType) bValue.getType()));
        } else if (bValue.getType().getTag() == TypeTags.RECORD_TYPE_TAG) {
            return StringUtils.fromString(getTypeNameFromRecordValue((RecordType) bValue.getType()));
        } else if (bValue.getType().getTag() == SERVICE_TAG) {
            return StringUtils.fromString(bValue.getType().getName());
        } else if (bValue.getType().getTag() == TypeTags.TYPE_REFERENCED_TYPE_TAG) {
            return StringUtils.fromString(bValue.getType().getName());
        }
        return StringUtils.fromString("");
    }

    public static boolean isRecordWithNoOptionalFields(Object value) {
        if (value instanceof BMap) {
            BMap<BString, Object> recordValue = (BMap<BString, Object>) value;
            Type type = TypeUtils.getImpliedType(recordValue.getType());
            if (type.getTag() == TypeTags.RECORD_TYPE_TAG) {
                RecordType recordType = (RecordType) type;
                for (Field field : recordType.getFields().values()) {
                    if (SymbolFlags.isFlagOn(field.getFlags(), SymbolFlags.OPTIONAL)) {
                        return false;
                    }
                }
                return true;
            }
        }
        return false;
    }

    static String getTypeNameFromRecordValue(RecordType recordType) {
        if (recordType.getName().contains("&") && recordType.getIntersectionType().isPresent()) {
            for (Type constituentType : recordType.getIntersectionType().get().getConstituentTypes()) {
                if (constituentType.getTag() != TypeTags.READONLY_TAG) {
                    return constituentType.getName();
                }
            }
        }
        return recordType.getName();
    }

    static String getTypeNameFromIntersection(IntersectionType intersectionType) {
        for (Type constituentType : intersectionType.getConstituentTypes()) {
            if (constituentType.getTag() != TypeTags.READONLY_TAG) {
                return constituentType.getName();
            }
        }
        return intersectionType.getEffectiveType().getName();
    }

    public static void setField(BObject context, BObject field) {
        context.addNativeData(FIELD_OBJECT, field);
    }

    public static BObject getField(BObject context) {
        return (BObject) context.getNativeData(FIELD_OBJECT);
    }

    public static Object getSdlString(BString schemaString) {
        Schema schema = getDecodedSchema(schemaString);
        String sdl = SdlSchemaStringGenerator.generate(schema, true);
        return StringUtils.fromString(sdl);
    }

    public static void setResult(BObject executorVisitor, Object result) {
        executorVisitor.set(RESULT_FIELD, result);
    }

    public static Object getResult(BObject executorVisitor) {
        return executorVisitor.get(RESULT_FIELD);
    }
}
