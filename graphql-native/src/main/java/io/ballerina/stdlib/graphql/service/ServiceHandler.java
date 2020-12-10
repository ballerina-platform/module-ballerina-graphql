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

package io.ballerina.stdlib.graphql.service;

import io.ballerina.runtime.api.values.BObject;

import java.io.PrintStream;

import static io.ballerina.stdlib.graphql.utils.Utils.NATIVE_SERVICE_OBJECT;

/**
 * Handles the service objects related to Ballerina GraphQL implementation.
 */
public class ServiceHandler {
    private static final PrintStream console = System.out;

    /**
     * Attaches a Ballerina service to a Ballerina GraphQL listener.
     *
     * @param listener - GraphQL listener to attach the service
     * @param service  - Service object of the Ballerina service
     * @param name     - Name of the service
     * @return - {@code ErrorValue} if the attaching is failed, null otherwise
     */
    public static Object attach(BObject listener, BObject service, Object name) {
        listener.addNativeData(NATIVE_SERVICE_OBJECT, service);
        return null;
    }

    /**
     * Detaches a service from the Ballerina GraphQL listener.
     *
     * @param listener - The listener from which the service should be detached
     * @param service  - The service to be detached
     * @return - An {@code ErrorValue} if the detaching is failed, null otherwise
     */
    public static Object detach(BObject listener, BObject service) {
        listener.addNativeData(NATIVE_SERVICE_OBJECT, null);
        return null;
    }
}
