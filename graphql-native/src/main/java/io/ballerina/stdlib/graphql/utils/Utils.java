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

import org.ballerinalang.jvm.api.BErrorCreator;
import org.ballerinalang.jvm.api.BStringUtils;
import org.ballerinalang.jvm.api.values.BError;
import org.ballerinalang.jvm.api.values.BString;

import static io.ballerina.stdlib.graphql.utils.Constants.PACKAGE_ID;
import static io.ballerina.stdlib.graphql.utils.Constants.RESOURCE_EXECUTION_ERROR;

/**
 * Utility class for Ballerina GraphQL module.
 */
public class Utils {
    private Utils() {
    }

    public static BError createError(String type, BString message) {
        return BErrorCreator.createDistinctError(type, PACKAGE_ID, message);
    }

    // TODO: This should be handled better
    public static BError createResourceExecutionFailedError(BString fieldName, String operationName) {
        String message = "Cannot query field \"" + fieldName.getValue() + "\" on type \"" + operationName + "\".";
        BString bErrorMessage = BStringUtils.fromString(message);
        return createError(RESOURCE_EXECUTION_ERROR, bErrorMessage);
    }
}
