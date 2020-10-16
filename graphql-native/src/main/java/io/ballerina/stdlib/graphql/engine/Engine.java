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

package io.ballerina.stdlib.graphql.engine;

import io.ballerina.stdlib.graphql.runtime.wrapper.Wrapper;
import io.ballerina.stdlib.graphql.utils.Constants;
import org.ballerinalang.jvm.api.BStringUtils;
import org.ballerinalang.jvm.api.BValueCreator;
import org.ballerinalang.jvm.api.values.BArray;
import org.ballerinalang.jvm.api.values.BObject;
import org.ballerinalang.jvm.api.values.BString;
import org.ballerinalang.jvm.types.AttachedFunction;

import static io.ballerina.stdlib.graphql.utils.Constants.OPERATION_QUERY;
import static io.ballerina.stdlib.graphql.utils.Utils.createResourceExecutionFailedError;

/**
 * This handles Ballerina GraphQL Engine.
 */
public class Engine {

    /**
     * Returns a stored resource value of a Ballerina service.
     *
     * @param listener - GraphQL listener to which the service is attached
     * @param name - Resource name to be retrieved
     * @return - Resource value
     */
    public static Object executeResource(BObject listener, BString name) {
        BObject attachedService = (BObject) listener.getNativeData(Constants.NATIVE_SERVICE_OBJECT);
        AttachedFunction[] attachedFunctions = attachedService.getType().getAttachedFunctions();
        for (AttachedFunction attachedFunction:attachedFunctions) {
            if (attachedFunction.funcName.equals(name.toString())) {
                return Wrapper.invokeResource(attachedFunction, null);
            }
        }
        return createResourceExecutionFailedError(name, OPERATION_QUERY);
    }

    /**
     * Returns an array of field names for the attached service for a Ballerina GraphQL listener.
     *
     * @return - A {@code BArray} consisting field names for the given service
     */
    public static BArray getFieldNames(BObject service) {
        AttachedFunction[] attachedFunctions = service.getType().getAttachedFunctions();
        String[] result = new String[attachedFunctions.length];
        for (int i = 0; i < attachedFunctions.length; i++) {
            result[i] = attachedFunctions[i].funcName;
        }
        return BValueCreator.createArrayValue(BStringUtils.fromStringArray(result));
    }
}
