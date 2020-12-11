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

package io.ballerina.stdlib.graphql.utils;

import io.ballerina.runtime.api.Module;

import static io.ballerina.runtime.api.constants.RuntimeConstants.BALLERINA_BUILTIN_PKG_PREFIX;

/**
 * Utility class for Ballerina GraphQL module.
 */
public class Utils {
    private Utils() {
    }

    public static final String MODULE_NAME = "graphql";
    public static final String MODULE_VERSION = "0.1.0";

    public static final Module PACKAGE_ID = new Module(BALLERINA_BUILTIN_PKG_PREFIX, MODULE_NAME, MODULE_VERSION);

    // Operations
    public static final String OPERATION_QUERY = "Query";

    public static final String NATIVE_SERVICE_OBJECT = "graphql.service";
}
