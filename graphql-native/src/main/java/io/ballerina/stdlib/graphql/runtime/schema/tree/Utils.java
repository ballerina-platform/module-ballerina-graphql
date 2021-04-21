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
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;

import java.util.ArrayList;
import java.util.List;

/**
 * Utility methods for the Ballerina GraphQL schema generator.
 */
public class Utils {
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
}
