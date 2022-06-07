/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.graphql.compiler.schema.types;

import java.util.Arrays;
import java.util.List;

/**
 * Stores the default directive values supported in Ballerina GraphQL package.
 */
public enum DefaultDirective {
    INCLUDE("include", Description.INCLUDE, Arrays.asList(DirectiveLocation.FIELD,
                                                          DirectiveLocation.FRAGMENT_SPREAD,
                                                          DirectiveLocation.INLINE_FRAGMENT)),
    SKIP("skip", Description.SKIP, Arrays.asList(DirectiveLocation.FIELD,
                                                 DirectiveLocation.FRAGMENT_SPREAD,
                                                 DirectiveLocation.INLINE_FRAGMENT)),
    DEPRECATED("deprecated", Description.DEPRECATED, Arrays.asList(DirectiveLocation.FIELD_DEFINITION,
                                                                   DirectiveLocation.ARGUMENT_DEFINITION,
                                                                   DirectiveLocation.INPUT_FIELD_DEFINITION,
                                                                   DirectiveLocation.ENUM_VALUE));

    private final String name;
    private final Description description;
    private final List<DirectiveLocation> locations;

    DefaultDirective(String name, Description description, List<DirectiveLocation> locations) {
        this.name = name;
        this.description = description;
        this.locations = locations;
    }

    public String getName() {
        return this.name;
    }

    public String getDescription() {
        return this.description.getDescription();
    }

    public List<DirectiveLocation> getLocations() {
        return this.locations;
    }
}
