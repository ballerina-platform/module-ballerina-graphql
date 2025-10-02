/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org). All Rights Reserved.
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

package io.ballerina.stdlib.graphql.commons.utils;

import io.ballerina.stdlib.graphql.commons.types.EnumValue;
import io.ballerina.stdlib.graphql.commons.types.Field;
import io.ballerina.stdlib.graphql.commons.types.InputValue;
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.commons.types.Type;
import io.ballerina.stdlib.graphql.commons.types.TypeKind;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * This class includes tests for SDL schema string generation and type ordering.
 */
public class SdlSchemaStringGeneratorTest {

    @Test
    public void testSchemaTypeOrdering() {
        // Create a schema with various types
        Schema schema = new Schema(null, false);

        // Add Query type
        Type queryType = schema.addType("Query", TypeKind.OBJECT, null);
        Type stringType = schema.addType("String", TypeKind.SCALAR, null);
        queryType.addField(new Field("greeting", stringType));
        queryType.addField(new Field("user", null)); // Will be set later
        schema.setQueryType(queryType);

        // Add Mutation type
        Type mutationType = schema.addType("Mutation", TypeKind.OBJECT, null);
        mutationType.addField(new Field("createUser", null)); // Will be set later
        schema.setMutationType(mutationType);

        // Add Subscription type
        Type subscriptionType = schema.addType("Subscription", TypeKind.OBJECT, null);
        subscriptionType.addField(new Field("userUpdated", null)); // Will be set later
        schema.setSubscriptionType(subscriptionType);

        // Add Interface
        Type profileInterface = schema.addType("Profile", TypeKind.INTERFACE, null);
        profileInterface.addField(new Field("id", stringType));
        profileInterface.addField(new Field("name", stringType));

        // Add Object types
        Type userType = schema.addType("User", TypeKind.OBJECT, null);
        userType.addField(new Field("id", stringType));
        userType.addField(new Field("name", stringType));
        userType.addField(new Field("email", stringType));
        userType.addInterface(profileInterface);

        Type addressType = schema.addType("Address", TypeKind.OBJECT, null);
        addressType.addField(new Field("street", stringType));
        addressType.addField(new Field("city", stringType));

        // Add Input type
        Type createUserInput = schema.addType("CreateUserInput", TypeKind.INPUT_OBJECT, null);
        createUserInput.addInputField(new InputValue("name", stringType, null, null));
        createUserInput.addInputField(new InputValue("email", stringType, null, null));

        // Add Enum
        Type statusEnum = schema.addType("Status", TypeKind.ENUM, null);
        statusEnum.addEnumValue(new EnumValue("ACTIVE", null));
        statusEnum.addEnumValue(new EnumValue("INACTIVE", null));

        // Add Union
        Type searchResultUnion = schema.addType("SearchResult", TypeKind.UNION, null);
        searchResultUnion.addPossibleType(userType);
        searchResultUnion.addPossibleType(addressType);

        // Add custom Scalar
        Type dateTimeScalar = schema.addType("DateTime", TypeKind.SCALAR, null);

        // Generate the SDL schema string
        String sdlSchema = SdlSchemaStringGenerator.generate(schema);

        // Verify the order: Query, Mutation, Subscription, Interface, Object types, Input, Enum, Union, Scalar
        int queryIndex = findTypeIndex(sdlSchema, "type Query");
        int mutationIndex = findTypeIndex(sdlSchema, "type Mutation");
        int subscriptionIndex = findTypeIndex(sdlSchema, "type Subscription");
        int interfaceIndex = findTypeIndex(sdlSchema, "interface Profile");
        int addressIndex = findTypeIndex(sdlSchema, "type Address");
        int userIndex = findTypeIndex(sdlSchema, "type User");
        int inputIndex = findTypeIndex(sdlSchema, "input CreateUserInput");
        int enumIndex = findTypeIndex(sdlSchema, "enum Status");
        int unionIndex = findTypeIndex(sdlSchema, "union SearchResult");
        int scalarIndex = findTypeIndex(sdlSchema, "scalar DateTime");

        // Assert the ordering
        Assert.assertTrue(queryIndex != -1, "Query type should be present");
        Assert.assertTrue(mutationIndex != -1, "Mutation type should be present");
        Assert.assertTrue(subscriptionIndex != -1, "Subscription type should be present");
        Assert.assertTrue(interfaceIndex != -1, "Interface should be present");
        Assert.assertTrue(userIndex != -1, "Object types should be present");
        Assert.assertTrue(inputIndex != -1, "Input type should be present");
        Assert.assertTrue(enumIndex != -1, "Enum type should be present");
        Assert.assertTrue(unionIndex != -1, "Union type should be present");
        Assert.assertTrue(scalarIndex != -1, "Scalar type should be present");

        // Verify the order is correct
        Assert.assertTrue(queryIndex < mutationIndex, "Query should come before Mutation");
        Assert.assertTrue(mutationIndex < subscriptionIndex, "Mutation should come before Subscription");
        Assert.assertTrue(subscriptionIndex < interfaceIndex, "Subscription should come before Interface");
        Assert.assertTrue(interfaceIndex < addressIndex, "Interface should come before Object types");
        Assert.assertTrue(interfaceIndex < userIndex, "Interface should come before Object types");
        Assert.assertTrue(addressIndex < inputIndex, "Object types should come before Input");
        Assert.assertTrue(userIndex < inputIndex, "Object types should come before Input");
        Assert.assertTrue(inputIndex < enumIndex, "Input should come before Enum");
        Assert.assertTrue(enumIndex < unionIndex, "Enum should come before Union");
        Assert.assertTrue(unionIndex < scalarIndex, "Union should come before Scalar");
    }

    @Test
    public void testAlphabeticalOrderingWithinSameTypeKind() {
        // Create a schema with multiple object types
        Schema schema = new Schema(null, false);

        // Add Query type
        Type queryType = schema.addType("Query", TypeKind.OBJECT, null);
        Type stringType = schema.addType("String", TypeKind.SCALAR, null);
        queryType.addField(new Field("test", stringType));
        schema.setQueryType(queryType);

        // Add multiple object types (not in alphabetical order)
        Type zebraType = schema.addType("Zebra", TypeKind.OBJECT, null);
        zebraType.addField(new Field("name", stringType));

        Type appleType = schema.addType("Apple", TypeKind.OBJECT, null);
        appleType.addField(new Field("color", stringType));

        Type mangoType = schema.addType("Mango", TypeKind.OBJECT, null);
        mangoType.addField(new Field("taste", stringType));

        // Generate the SDL schema string
        String sdlSchema = SdlSchemaStringGenerator.generate(schema);

        // Find positions
        int appleIndex = findTypeIndex(sdlSchema, "type Apple");
        int mangoIndex = findTypeIndex(sdlSchema, "type Mango");
        int zebraIndex = findTypeIndex(sdlSchema, "type Zebra");

        // Verify alphabetical ordering within the same type kind
        Assert.assertTrue(appleIndex < mangoIndex, "Apple should come before Mango (alphabetical order)");
        Assert.assertTrue(mangoIndex < zebraIndex, "Mango should come before Zebra (alphabetical order)");
    }

    @Test
    public void testMinimalSchemaWithOnlyQuery() {
        // Create a minimal schema with only Query type
        Schema schema = new Schema(null, false);

        Type queryType = schema.addType("Query", TypeKind.OBJECT, null);
        Type stringType = schema.addType("String", TypeKind.SCALAR, null);
        queryType.addField(new Field("hello", stringType));
        schema.setQueryType(queryType);

        // Generate the SDL schema string
        String sdlSchema = SdlSchemaStringGenerator.generate(schema);

        // Verify Query is present
        Assert.assertTrue(sdlSchema.contains("type Query"), "Schema should contain Query type");
        Assert.assertTrue(sdlSchema.contains("hello"), "Query should have hello field");
    }

    /**
     * Helper method to find the index of a type definition in the schema string.
     *
     * @param schema the schema string
     * @param typePattern the pattern to search for (e.g., "type Query", "interface Profile")
     * @return the index of the type definition, or -1 if not found
     */
    private int findTypeIndex(String schema, String typePattern) {
        // Use regex to find the pattern at the start of a line
        Pattern pattern = Pattern.compile("^" + Pattern.quote(typePattern), Pattern.MULTILINE);
        Matcher matcher = pattern.matcher(schema);
        if (matcher.find()) {
            return matcher.start();
        }
        return -1;
    }
}

