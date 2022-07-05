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

package io.ballerina.stdlib.graphql.runtime.utils;

import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.async.StrandMetadata;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BError;

import static io.ballerina.stdlib.graphql.runtime.utils.ModuleUtils.getModule;

/**
 * This class contains utility methods for the Ballerina GraphQL module.
 */
public class Utils {
    private Utils() {
    }

    // Inter-op function names
    static final String EXECUTE_SERVICE_FUNCTION = "executeService";
    static final String EXECUTE_MUTATION_FUNCTION = "executeMutation";

    static final String EXECUTE_RESOURCE_FUNCTION = "executeResource";

    // Internal type names
    public static final String ERROR_TYPE = "Error";
    public static final String CONTEXT_OBJECT = "Context";

    public static final String UPLOAD = "Upload";

    public static final StrandMetadata RESOURCE_STRAND_METADATA = new StrandMetadata(getModule().getOrg(),
                                                                                     getModule().getName(),
                                                                                     getModule().getMajorVersion(),
                                                                                     EXECUTE_SERVICE_FUNCTION);
    public static final StrandMetadata REMOTE_STRAND_METADATA = new StrandMetadata(getModule().getOrg(),
                                                                                   getModule().getName(),
                                                                                   getModule().getMajorVersion(),
                                                                                   EXECUTE_MUTATION_FUNCTION);

    public static final StrandMetadata FIELD_EXECUTION_STRAND = new StrandMetadata(getModule().getOrg(),
                                                                                   getModule().getName(),
                                                                                   getModule().getMajorVersion(),
                                                                                   EXECUTE_RESOURCE_FUNCTION);

    public static BError createError(String message, String errorTypeName) {
        return ErrorCreator.createError(getModule(), errorTypeName, StringUtils.fromString(message), null, null);
    }

    public static BError createError(String message, String errorTypeName, BError cause) {
        return ErrorCreator.createError(getModule(), errorTypeName, StringUtils.fromString(message), cause, null);
    }

    public static boolean isContext(Type type) {
        return isGraphqlModule(type) && type.getName().equals(CONTEXT_OBJECT);
    }

    public static boolean isFileUpload(Type type) {
        if (type.getTag() == TypeTags.ARRAY_TAG) {
            return isFileUpload(((ArrayType) type).getElementType());
        }
        return isGraphqlModule(type) && type.getName().equals(UPLOAD);
    }

    public static boolean isGraphqlModule(Type type) {
        if (type.getPackage() == null) {
            return false;
        }
        if (type.getPackage().getOrg() == null || type.getPackage().getName() == null) {
            return false;
        }
        return type.getPackage().getOrg().equals(ModuleUtils.getModule().getOrg()) &&
                type.getPackage().getName().equals(ModuleUtils.getModule().getName());
    }
}
