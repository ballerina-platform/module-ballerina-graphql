/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org). All Rights Reserved.
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

package io.ballerina.stdlib.graphql.commons.types;

import java.util.List;

import static io.ballerina.stdlib.graphql.commons.types.Description.EXECUTION;
import static io.ballerina.stdlib.graphql.commons.types.Description.SECURITY;

/**
 * Represents enum types of federated subgraph.
 */
public enum FederatedEnumValue {

    LINK_PURPOSE(TypeName.LINK_PURPOSE, null, List.of(getExecutionEnumValue(), getSecurityEnumValue()));

    private final TypeName name;
    private final String description;
    private final List<EnumValue> values;

    FederatedEnumValue(TypeName name, String description, List<EnumValue> values) {
        this.name = name;
        this.description = description;
        this.values = values;
    }

    public String getName() {
        return this.name.getName();
    }

    public String getDescription() {
        return this.description;
    }

    public Type getEnumTypeWithValues() {
        Type enumType = new Type(getName(), TypeKind.ENUM);
        values.forEach(enumType::addEnumValue);
        return enumType;
    }

    private static EnumValue getSecurityEnumValue() {
        return new EnumValue("SECURITY", SECURITY.getDescription());
    }

    private static EnumValue getExecutionEnumValue() {
        return new EnumValue("EXECUTION", EXECUTION.getDescription());
    }
}
