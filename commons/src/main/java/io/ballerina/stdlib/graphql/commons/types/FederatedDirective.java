/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org). All Rights Reserved.
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

package io.ballerina.stdlib.graphql.commons.types;

import java.util.List;

import static io.ballerina.stdlib.graphql.commons.types.DirectiveLocation.INTERFACE;
import static io.ballerina.stdlib.graphql.commons.types.DirectiveLocation.OBJECT;
import static io.ballerina.stdlib.graphql.commons.types.DirectiveLocation.SCHEMA;
import static io.ballerina.stdlib.graphql.commons.types.FederatedEnumValue.LINK_PURPOSE;

/**
 * Stores the federated subgraph directives.
 */
public enum FederatedDirective {

    KEY("key", List.of(getFieldsInput(), getResolvableInput()), true, List.of(OBJECT, INTERFACE)),
    LINK("link", List.of(getUrlInput(), getAsInput(), getForInput(), getImportInput()), true, List.of(SCHEMA));

    private final String name;
    private final List<InputValue> arguments;
    private final boolean repeatable;
    private final List<DirectiveLocation> locations;

    FederatedDirective(String name, List<InputValue> arguments, boolean repeatable, List<DirectiveLocation> locations) {
        this.name = name;
        this.arguments = arguments;
        this.repeatable = repeatable;
        this.locations = locations;
    }

    public static boolean canImportInLinkDirective(String directiveName) {
        return directiveName.equals(LINK.getName());
    }

    public String getName() {
        return this.name;
    }

    public List<InputValue> getArguments() {
        return this.arguments;
    }

    public List<DirectiveLocation> getLocations() {
        return this.locations;
    }

    private static InputValue getFieldsInput() {
        return new InputValue("fields", new Type(TypeKind.NON_NULL, getScalar(ScalarType.FIELD_SET)), null, null);
    }

    private static InputValue getResolvableInput() {
        return new InputValue("resolvable", getScalar(ScalarType.BOOLEAN), null, "true");
    }

    private static InputValue getUrlInput() {
        return new InputValue("url", new Type(TypeKind.NON_NULL, getScalar(ScalarType.STRING)), null, null);
    }

    private static InputValue getAsInput() {
        return new InputValue("as", getScalar(ScalarType.STRING), null, null);
    }

    private static InputValue getForInput() {
        return new InputValue("for", LINK_PURPOSE.getEnumTypeWithValues(), null, null);
    }

    private static InputValue getImportInput() {
        return new InputValue("import", new Type(TypeKind.LIST, getScalar(ScalarType.LINK_IMPORT)), null, null);
    }

    private static Type getScalar(ScalarType scalar) {
        return new Type(scalar.getName(), TypeKind.SCALAR, scalar.getDescription());
    }

    public boolean isRepeatable() {
        return repeatable;
    }
}
