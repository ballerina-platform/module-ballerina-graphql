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

package io.ballerina.stdlib.graphql.compiler;

import io.ballerina.projects.JvmTarget;

import java.util.Arrays;

/**
 * Shared helpers for compiler plugin tests.
 */
final class TestUtils {

    private TestUtils() {
    }

    static JvmTarget getJvmTarget() {
        String runtimeCode = "java" + Runtime.version().feature();
        return Arrays.stream(JvmTarget.values())
                .filter(target -> target.code().equals(runtimeCode))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException(
                        "cannot find a compatible JvmTarget for the runtime version: " + runtimeCode));
    }
}
