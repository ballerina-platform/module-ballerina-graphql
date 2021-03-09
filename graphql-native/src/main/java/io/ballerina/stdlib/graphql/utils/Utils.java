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

package io.ballerina.stdlib.graphql.utils;

import io.ballerina.runtime.api.async.StrandMetadata;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BError;

import static io.ballerina.stdlib.graphql.utils.ModuleUtils.getModule;

/**
 * This class contains utility methods for the Ballerina GraphQL module.
 */
public class Utils {

    // Inter-op function names
    static final String EXECUTE_SINGLE_RESOURCE_FUNCTION = "executeSingleResource";

    public static final String NOT_SUPPORTED_ERROR = "NotSupportedError";
    public static final String INVALID_TYPE_ERROR = "InvalidTypeError";

    public static final StrandMetadata STRAND_METADATA = new StrandMetadata(getModule().getOrg(), getModule().getName(),
                                                                            getModule().getVersion(),
                                                                            EXECUTE_SINGLE_RESOURCE_FUNCTION);

    public static BError createError(String message, String errorTypeName) {
        return ErrorCreator.createError(getModule(), errorTypeName, StringUtils.fromString(message), null, null);
    }

    public static String[] removeFirstElementFromArray(String[] array) {
        int length = array.length - 1;
        String[] result = new String[length];
        System.arraycopy(array, 1, result, 0, length);
        return result;
    }
}
