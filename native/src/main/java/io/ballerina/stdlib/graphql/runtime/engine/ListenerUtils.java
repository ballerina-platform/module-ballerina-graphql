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

import io.ballerina.runtime.api.values.BObject;

/**
 * External utility methods used in Ballerina GraphQL listener.
 */
public final class ListenerUtils {
    private static final String HTTP_SERVICE = "graphql.http.service";

    private ListenerUtils() {}

    public static void attachHttpServiceToGraphqlService(BObject graphqlService, BObject httpService) {
        graphqlService.addNativeData(HTTP_SERVICE, httpService);
    }

    public static Object getHttpServiceFromGraphqlService(BObject graphqlService) {
        Object httpService = graphqlService.getNativeData(HTTP_SERVICE);
        if (httpService instanceof BObject) {
            return httpService;
        }
        return null;
    }
}
