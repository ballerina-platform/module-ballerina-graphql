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

package io.ballerina.stdlib.graphql.runtime.wrapper;

import io.ballerina.runtime.api.types.AttachedFunctionType;
import io.ballerina.runtime.api.utils.StringUtils;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.stdlib.graphql.runtime.wrapper.Constants.AGE;
import static io.ballerina.stdlib.graphql.runtime.wrapper.Constants.GREET;
import static io.ballerina.stdlib.graphql.runtime.wrapper.Constants.ID;
import static io.ballerina.stdlib.graphql.runtime.wrapper.Constants.INT_TYPE;
import static io.ballerina.stdlib.graphql.runtime.wrapper.Constants.NAME;
import static io.ballerina.stdlib.graphql.runtime.wrapper.Constants.NAME_WITH_ID;
import static io.ballerina.stdlib.graphql.runtime.wrapper.Constants.PERSON;
import static io.ballerina.stdlib.graphql.runtime.wrapper.Constants.RECORD_TYPE;
import static io.ballerina.stdlib.graphql.runtime.wrapper.Constants.SERVICE_TYPE;
import static io.ballerina.stdlib.graphql.runtime.wrapper.Constants.STRING_TYPE;

/**
 * Wrapper class for Ballerina Compiler Utils.
 */
public class Wrapper {
    public static Object invokeResource(AttachedFunctionType attachedFunction, Object[] inputs) {
        String name = attachedFunction.getName();
        if ("name".equals(name)) {
            return StringUtils.fromString("John Doe");
        } else if ("id".equals(name)) {
            return 1;
        } else if ("birthdate".equals(name)) {
            return StringUtils.fromString("01-01-1980");
        }
        return null;
    }

    public static int getReturnType(AttachedFunctionType attachedFunction) {
        String name = attachedFunction.getName();
        switch (name) {
            case PERSON:
                return RECORD_TYPE;
            case GREET:
            case NAME_WITH_ID:
                return STRING_TYPE;
            case AGE:
                return INT_TYPE;
            default:
                return SERVICE_TYPE;
        }
    }

    public static List<Input> populateInputs(AttachedFunctionType attachedFunction) {
        String name = attachedFunction.getName();
        ArrayList<Input> inputs = new ArrayList<>();
        switch (name) {
            case PERSON:
                inputs.add(new Input(ID, INT_TYPE, false));
                return inputs;
            case NAME_WITH_ID:
                inputs.add(new Input(ID, INT_TYPE, true));
                inputs.add(new Input(NAME, STRING_TYPE, true));
                return inputs;
            default:
                return null;
        }
    }
}
