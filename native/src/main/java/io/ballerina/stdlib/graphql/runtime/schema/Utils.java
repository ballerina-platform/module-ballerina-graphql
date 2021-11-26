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
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.flags.SymbolFlags;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.TableType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.BOOLEAN;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.DECIMAL;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FLOAT;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.INTEGER;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.STRING;

/**
 * Utility methods for the Ballerina GraphQL schema generator.
 */
public class Utils {
    private static final String UNION_TYPE_NAME_DELIMITER = "|";

    private Utils() {}

    public static boolean isEnum(UnionType unionType) {
        return SymbolFlags.isFlagOn(unionType.getFlags(), SymbolFlags.ENUM);
    }

    public static boolean isRequired(Field field) {
        return SymbolFlags.isFlagOn(field.getFlags(), SymbolFlags.REQUIRED) ||
                !SymbolFlags.isFlagOn(field.getFlags(), SymbolFlags.OPTIONAL);
    }

    public static List<Type> getMemberTypes(UnionType unionType) {
        List<Type> members = new ArrayList<>();
        if (isEnum(unionType)) {
            members.add(unionType);
        } else {
            List<Type> originalMembers = unionType.getOriginalMemberTypes();
            for (Type type : originalMembers) {
                if (type.getTag() == TypeTags.ERROR_TAG || type.getTag() == TypeTags.NULL_TAG) {
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

    public static String getTypeNameFromType(Type type) {
        int tag = type.getTag();
        if (type.getTag() < TypeTags.JSON_TAG) {
            return getScalarTypeName(tag);
        } else if (tag == TypeTags.ARRAY_TAG) {
            return getTypeNameFromType(((ArrayType) type).getElementType());
        } else if (tag == TypeTags.MAP_TAG) {
            return getTypeNameFromType(((MapType) type).getConstrainedType());
        } else if (tag == TypeTags.TABLE_TAG) {
            return getTypeNameFromType(((TableType) type).getConstrainedType());
        } else if (tag == TypeTags.UNION_TAG) {
            return getTypeName((UnionType) type);
        } else if (tag == TypeTags.RECORD_TYPE_TAG) {
            return getTypeName((RecordType) type);
        } else if (tag == TypeTags.INTERSECTION_TAG) {
            return getTypeName((IntersectionType) type);
        }
        return type.getName();
    }

    public static String getScalarTypeName(int tag) {
        switch (tag) {
            case TypeTags.INT_TAG:
                return INTEGER;
            case TypeTags.FLOAT_TAG:
                return FLOAT;
            case TypeTags.DECIMAL_TAG:
                return DECIMAL;
            case TypeTags.BOOLEAN_TAG:
                return BOOLEAN;
            default:
                return STRING;
        }
    }

    public static BArray getArrayTypeFromBMap(BMap<BString, Object> recordValue) {
        ArrayType arrayType = TypeCreator.createArrayType(recordValue.getType());
        return ValueCreator.createArrayValue(arrayType);
    }

    public static String getTypeName(UnionType unionType) {
        List<Type> memberTypes = getMemberTypes(unionType);
        return unionType.getName().isBlank() ?
                memberTypes.stream().map(Type::getName).collect(Collectors.joining(UNION_TYPE_NAME_DELIMITER)) :
                unionType.getName();
    }

    private static String getTypeName(RecordType recordType) {
        return recordType.getName();
    }

    private static String getTypeName(IntersectionType intersectionType) {
        return getTypeNameFromType(intersectionType.getEffectiveType());
    }

    public static Type getEffectiveType(Type type) {
        if (type.getTag() == TypeTags.INTERSECTION_TAG) {
            IntersectionType intersectionType = (IntersectionType) type;
            return (intersectionType.getEffectiveType());
        }
        return type;
    }
}
