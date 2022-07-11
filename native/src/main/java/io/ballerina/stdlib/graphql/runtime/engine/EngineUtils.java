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

import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.flags.SymbolFlags;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BValue;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.runtime.api.TypeTags.BOOLEAN_TAG;
import static io.ballerina.runtime.api.TypeTags.DECIMAL_TAG;
import static io.ballerina.runtime.api.TypeTags.FLOAT_TAG;
import static io.ballerina.runtime.api.TypeTags.INT_TAG;
import static io.ballerina.runtime.api.TypeTags.SERVICE_TAG;
import static io.ballerina.runtime.api.TypeTags.STRING_TAG;
import static io.ballerina.stdlib.graphql.runtime.utils.ModuleUtils.getModule;

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
    public static final BString ALIAS_FIELD = StringUtils.fromString("alias");
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

    // Input values
    public static final String KEY = "key";

    //Accessor names
    public static final String GET_ACCESSOR = "get";
    public static final String SUBSCRIBE_ACCESSOR = "subscribe";
    public static final String INTERCEPTOR_EXECUTE = "execute";

    // Visitor object fields
    static final BString ERRORS_FIELD = StringUtils.fromString("errors");
    static final BString ENGINE_FIELD = StringUtils.fromString("engine");
    static final BString DATA_FIELD = StringUtils.fromString("data");
    static final BString CONTEXT_FIELD = StringUtils.fromString("context");
    static final BString FILE_INFO = StringUtils.fromString("fileInfo");

    // Internal Types
    static final String ERROR_DETAIL_RECORD = "ErrorDetail";
    static final String DATA_RECORD = "Data";

    // Record fields
    static final BString LOCATION_FIELD = StringUtils.fromString("location");
    public static final BString LOCATIONS_FIELD = StringUtils.fromString("locations");
    static final BString PATH_FIELD = StringUtils.fromString("path");
    static final BString MESSAGE_FIELD = StringUtils.fromString("message");
    static final BString SELECTIONS_FIELD = StringUtils.fromString("selections");
    static final BString ARGUMENTS_FIELD = StringUtils.fromString("arguments");
    static final BString VALUE_FIELD = StringUtils.fromString("value");
    static final BString VARIABLE_NAME_FIELD = StringUtils.fromString("variableName");
    static final BString ON_TYPE_FIELD = StringUtils.fromString("onType");
    static final BString SCHEMA_FIELD = StringUtils.fromString("schema");

    // Node Types
    static final BString FRAGMENT_NODE = StringUtils.fromString("FragmentNode");

    // Query Fields
    public static final String TYPENAME_FIELD = "__typename";

    // Native Data Fields
    public static final String GRAPHQL_SERVICE_OBJECT = "graphql.service.object";
    public static final String GRAPHQL_FIELD = "graphql.field";
    public static final String FIELD_OBJECT = "field.object";

    public static final String FILE_INFO_FIELD = "graphql.context.fileInfo";

    static BMap<BString, Object> getErrorDetailRecord(BError error, BObject node, List<Object> pathSegments) {
        BMap<BString, Object> location = node.getMapValue(LOCATION_FIELD);
        ArrayType locationsArrayType = TypeCreator.createArrayType(location.getType());
        BArray locations = ValueCreator.createArrayValue(locationsArrayType);
        locations.append(location);
        ArrayType pathSegmentArrayType = TypeCreator
                .createArrayType(TypeCreator.createUnionType(PredefinedTypes.TYPE_INT, PredefinedTypes.TYPE_STRING));
        BArray pathSegmentArray = ValueCreator.createArrayValue(pathSegments.toArray(), pathSegmentArrayType);
        BMap<BString, Object> errorDetail = ValueCreator.createRecordValue(getModule(), ERROR_DETAIL_RECORD);
        errorDetail.put(MESSAGE_FIELD, StringUtils.fromString(error.getMessage()));
        errorDetail.put(LOCATIONS_FIELD, locations);
        errorDetail.put(PATH_FIELD, pathSegmentArray);
        return errorDetail;
    }

    static BMap<BString, Object> createDataRecord() {
        return ValueCreator.createRecordValue(getModule(), DATA_RECORD);
    }

    static boolean isScalarType(Type type) {
        int tag = type.getTag();
        if (tag == TypeTags.UNION_TAG) {
            if (isEnum((UnionType) type)) {
                return true;
            }
            List<Type> memberTypes = getMemberTypes((UnionType) type);
            if (memberTypes.size() == 1) {
                return isScalarType(memberTypes.get(0));
            }
            return false;
        }
        return tag == INT_TAG || tag == FLOAT_TAG || tag == BOOLEAN_TAG || tag == STRING_TAG || tag == DECIMAL_TAG;
    }

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

    static List<String> copyAndUpdateResourcePathsList(List<String> paths, BObject node) {
        List<String> updatedPaths = new ArrayList<>(paths);
        updatedPaths.add(node.getStringValue(NAME_FIELD).getValue());
        return updatedPaths;
    }

    static List<Object> updatePathSegments(List<Object> pathSegments, Object segment) {
        List<Object> updatedPathSegments = new ArrayList<>(pathSegments);
        if (segment instanceof String) {
            updatedPathSegments.add(StringUtils.fromString((String) segment));
        } else {
            updatedPathSegments.add(segment);
        }
        return updatedPathSegments;
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

    public static BMap<BString, Object> getTypeFromTypeArray(String typeName, BArray types) {
        for (int i = 0; i < types.size(); i++) {
            BMap<BString, Object> type = (BMap<BString, Object>) types.get(i);
            if (type.getStringValue(NAME_FIELD).getValue().equals(typeName)) {
                return type;
            }
        }
        return null;
    }

    public static void addService(BObject engine, BObject service) {
        engine.addNativeData(GRAPHQL_SERVICE_OBJECT, service);
    }

    public static BObject getService(BObject engine) {
        return (BObject) engine.getNativeData(GRAPHQL_SERVICE_OBJECT);
    }

    public static void setFileInfo(BObject context, BMap<BString, Object> fileInfo) {
        context.addNativeData(FILE_INFO_FIELD, fileInfo);
    }

    public static BMap<BString, Object> getFileInfo(BObject context) {
        return (BMap<BString, Object>) context.getNativeData(FILE_INFO_FIELD);
    }

    public static boolean isMap(BMap<BString, Object> value) {
        return value.getType().getTag() == TypeTags.MAP_TAG;
    }

    public static BString getTypeNameFromValue(BValue bValue) {
        if (bValue.getType().getTag() == TypeTags.RECORD_TYPE_TAG) {
            return StringUtils.fromString(getTypeNameFromRecordValue((RecordType) bValue.getType()));
        } else if (bValue.getType().getTag() == SERVICE_TAG) {
            return StringUtils.fromString(bValue.getType().getName());
        }
        return StringUtils.fromString("");
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

    public static BObject getFieldFromEngine(BObject engine) {
        BObject fieldNode = (BObject) engine.getNativeData(GRAPHQL_FIELD);
        return fieldNode;
    }

    public static void setField(BObject context, BObject field) {
        context.addNativeData(FIELD_OBJECT, field);
    }

    public static BObject getField(BObject context) {
        return (BObject) context.getNativeData(FIELD_OBJECT);
    }
}
