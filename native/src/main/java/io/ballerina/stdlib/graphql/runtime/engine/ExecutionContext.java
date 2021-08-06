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

package io.ballerina.stdlib.graphql.runtime.engine;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.values.BObject;

/**
 * This class stores information related to the result of the GraphQL execution.
 *
 * @since 1.0.0
 */
public class ExecutionContext {
    private final Environment environment;
    private final BObject visitor;
    private final CallbackHandler callbackHandler;
    private String typeName;

    ExecutionContext(Environment environment, BObject visitor, CallbackHandler callbackHandler, String typeName) {
        this.environment = environment;
        this.visitor = visitor;
        this.callbackHandler = callbackHandler;
        this.typeName = typeName;
    }

    Environment getEnvironment() {
        return this.environment;
    }

    BObject getVisitor() {
        return this.visitor;
    }

    CallbackHandler getCallbackHandler() {
        return this.callbackHandler;
    }

    String getTypeName() {
        return this.typeName;
    }

    void setTypeName(String typeName) {
        this.typeName = typeName;
    }
}
