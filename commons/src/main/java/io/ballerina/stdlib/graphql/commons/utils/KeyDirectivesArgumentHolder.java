/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
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

package io.ballerina.stdlib.graphql.commons.utils;

import java.util.List;

/**
 * Hold the necessary arguments of GraphQL federation @key directive.
 */
public class KeyDirectivesArgumentHolder {
    // If the fieldName has more than one element then key directive needs to be repeated for each element
    private final List<String> fieldNames;
    private final boolean resolvable;

    public KeyDirectivesArgumentHolder(List<String> fieldNames, boolean resolvable) {
        this.fieldNames = fieldNames;
        this.resolvable = resolvable;
    }

    public List<String> getFieldNames() {
        return fieldNames;
    }

    public boolean isResolvable() {
        return resolvable;
    }
}
