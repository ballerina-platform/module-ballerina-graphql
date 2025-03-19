/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.graphql.runtime.engine;

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

/**
 * This class provides native implementations of the Ballerina Placeholder class.
 */
public class Placeholder {
    private static final BString PLACE_HOLDER_VALUE_OBJECT = StringUtils.fromString("value");
    private static final BString PLACE_HOLDER_FIELD_OBJECT = StringUtils.fromString("field");

    private Placeholder() {
    }

    public static void setValue(BObject placeholder, Object value) {
        placeholder.set(PLACE_HOLDER_VALUE_OBJECT, value);
    }

    public static Object getValue(BObject placeholder) {
        return placeholder.get(PLACE_HOLDER_VALUE_OBJECT);
    }

    public static void setFieldValue(BObject placeholder, BObject field) {
        placeholder.set(PLACE_HOLDER_FIELD_OBJECT, field);
    }

    public static BObject getFieldValue(BObject placeholder) {
        return (BObject) placeholder.get(PLACE_HOLDER_FIELD_OBJECT);
    }
}
