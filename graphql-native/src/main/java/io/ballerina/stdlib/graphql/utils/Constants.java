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
import io.ballerina.runtime.api.StringUtils;
import io.ballerina.runtime.api.values.BString;

import static io.ballerina.runtime.util.BLangConstants.BALLERINA_BUILTIN_PKG_PREFIX;
/**
 * Constants used in Ballerina GraphQL native library.
 */
public class Constants {
    private Constants() {}

    private static final String MODULE_NAME = "graphql";
    private static final String VERSION = "0.1.0";

    public static final Module PACKAGE_ID = new Module(BALLERINA_BUILTIN_PKG_PREFIX, MODULE_NAME, VERSION);

    // Type names
    public static final String RESOURCE_EXECUTION_ERROR = "ResourceExecutionFailed";

    // Operations
    public static final String OPERATION_QUERY = "Query";

    public static final String NATIVE_SERVICE_OBJECT = "graphql.service";

    // Record types
    public static final String RECORD_ERROR_RECORD = "ErrorRecord";
    public static final String RECORD_LOCATION = "Location";

    // Error types
    public static final String ERROR = "Error";
    public static final String ERROR_INVALID_ARGUMENT_TYPE = "InvalidArgumentTypeError";
    public static final String ERROR_INVALID_SELECTION = "InvalidSelectionError";
    public static final String ERROR_MISSING_REQUIRED_ARGUMENT = "MissingRequiredArgumentError";

    // Record fields
    public static final BString FIELD_NAME = StringUtils.fromString("name");
    public static final BString FIELD_LOCATION = StringUtils.fromString("location");
    public static final BString FIELD_ARGUMENTS = StringUtils.fromString("arguments");
    public static final BString FIELD_SELECTIONS = StringUtils.fromString("selections");
    public static final BString FIELD_VALUE = StringUtils.fromString("value");
    public static final BString FIELD_LOCATIONS = StringUtils.fromString("locations");
    public static final BString FIELD_TYPE = StringUtils.fromString("type");

}
