/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.graphql.compiler.schema.types;

/**
 * Stores descriptions for the default types in a GraphQL schema.
 */
public enum Description {
    STRING("The `String` scalar type represents textual data, represented as UTF-8 character sequences. The String type is most often used by GraphQL to represent free-form human-readable text."),
    INT("The `Int` scalar type represents non-fractional signed whole numeric values."),
    FLOAT("The `Float` scalar type represents signed double-precision fractional values as specified by [IEEE 754]" +
                  "(https://en.wikipedia.org/wiki/IEEE_floating_point)."),
    BOOLEAN("The `Boolean` scalar type represents `true` or `false`."),
    DECIMAL("The decimal type corresponds to a subset of IEEE 754-2008 128-bit decimal (radix 10) floating point " +
                    "numbers"),
    GENERATED_UNION_TYPE("auto-generated union type from Ballerina");

    private final String description;

    Description(String description) {
        this.description = description;
    }

    public String getDescription() {
        return this.description;
    }
}
