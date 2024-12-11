/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.graphql.runtime.client;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;

/**
 * This class is used to execute a GraphQL document using the Ballerina GraphQL client.
 */
public final class QueryExecutor {

    private QueryExecutor () {}

    /**
     * Executes the GraphQL document when the corresponding Ballerina remote operation is invoked.
     */
    public static Object execute(Environment env, BObject client, BString document, Object variables,
                                 Object operationName, Object headers, BTypedesc targetType) {
        return invokeClientMethod(env, client, document, variables, operationName, headers, targetType,
                "processExecute");
    }

    /**
     * Executes the GraphQL document when the corresponding Ballerina remote operation is invoked.
     */
    public static Object executeWithType(Environment env, BObject client, BString document, Object variables,
                                         Object operationName, Object headers, BTypedesc targetType) {
        return invokeClientMethod(env, client, document, variables, operationName, headers, targetType,
                "processExecuteWithType");
    }

    private static Object invokeClientMethod(Environment env, BObject client, BString document, Object variables,
                                             Object operationName, Object headers, BTypedesc targetType,
                                             String methodName) {
        Object[] paramFeed = new Object[5];
        paramFeed[0] = targetType;
        paramFeed[1] = document;
        paramFeed[2] = variables;
        paramFeed[3] = operationName;
        paramFeed[4] = headers;
        return invokeClientMethod(env, client, methodName, paramFeed);
    }

    private static Object invokeClientMethod(Environment env, BObject client, String methodName, Object[] paramFeed) {
        return env.yieldAndRun(() -> {
            try {
                return env.getRuntime().callMethod(client, methodName, null, paramFeed);
            } catch (BError bError) {
                return bError;
            }
        });
    }
}
