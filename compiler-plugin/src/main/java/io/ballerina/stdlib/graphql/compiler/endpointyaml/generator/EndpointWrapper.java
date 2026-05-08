/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.graphql.compiler.endpointyaml.generator;

import java.util.Objects;

public class EndpointWrapper {
    private final Endpoint endpoint;
    private static final String ENDPOINT_NOT_NULL_MSG = "endpoint must not be null";

    public EndpointWrapper(Endpoint endpoint) {
        this.endpoint = Objects.requireNonNull(endpoint, ENDPOINT_NOT_NULL_MSG);
    }

    public Endpoint getEndpoint() {
        return endpoint;
    }
}
