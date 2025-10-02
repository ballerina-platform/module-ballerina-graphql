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

public class SdlSchemaStringGeneratorTest {

    @Test
    public void testSchemaTypeOrdering() {
        Schema schema = new Schema(null, false);

        Type queryType = schema.addType("Query", TypeKind.OBJECT, null);
        Type stringType = schema.addType("String", TypeKind.SCALAR, null);
        queryType.addField(new Field("greeting", stringType));
        queryType.addField(new Field("user", null));
        schema.setQueryType(queryType);

        Type mutationType = schema.addType("Mutation", TypeKind.OBJECT, null);
        mutationType.addField(new Field("createUser", null));
        schema.setMutationType(mutationType);

        Type subscriptionType = schema.addType("Subscription", TypeKind.OBJECT, null);
        subscriptionType.addField(new Field("userUpdated", null));
        schema.setSubscriptionType(subscriptionType);

        Type profileInterface = schema.addType("Profile", TypeKind.INTERFACE, null);
        profileInterface.addField(new Field("id", stringType));
        profileInterface.addField(new Field("name", stringType));

        Type userType = schema.addType("User", TypeKind.OBJECT, null);
        userType.addField(new Field("id", stringType));
        userType.addField(new Field("name", stringType));
        userType.addField(new Field("email", stringType));
        userType.addInterface(profileInterface);

        Type addressType = schema.addType("Address", TypeKind.OBJECT, null);
        addressType.addField(new Field("street", stringType));
        addressType.addField(new Field("city", stringType));

        Type createUserInput = schema.addType("CreateUserInput", TypeKind.INPUT_OBJECT, null);
        createUserInput.addInputField(new InputValue("name", stringType, null, null));
        createUserInput.addInputField(new InputValue("email", stringType, null, null));

        Type statusEnum = schema.addType("Status", TypeKind.ENUM, null);
        statusEnum.addEnumValue(new EnumValue("ACTIVE", null));
        statusEnum.addEnumValue(new EnumValue("INACTIVE", null));

        Type searchResultUnion = schema.addType("SearchResult", TypeKind.UNION, null);
        searchResultUnion.addPossibleType(userType);
        searchResultUnion.addPossibleType(addressType);

        Type dateTimeScalar = schema.addType("DateTime", TypeKind.SCALAR, null);

        String sdlSchema = SdlSchemaStringGenerator.generate(schema);

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

        Assert.assertTrue(queryIndex != -1, "Query type should be present");
        Assert.assertTrue(mutationIndex != -1, "Mutation type should be present");
        Assert.assertTrue(subscriptionIndex != -1, "Subscription type should be present");
        Assert.assertTrue(interfaceIndex != -1, "Interface should be present");
        Assert.assertTrue(userIndex != -1, "Object types should be present");
        Assert.assertTrue(inputIndex != -1, "Input type should be present");
        Assert.assertTrue(enumIndex != -1, "Enum type should be present");
        Assert.assertTrue(unionIndex != -1, "Union type should be present");
        Assert.assertTrue(scalarIndex != -1, "Scalar type should be present");

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
        Schema schema = new Schema(null, false);

        Type queryType = schema.addType("Query", TypeKind.OBJECT, null);
        Type stringType = schema.addType("String", TypeKind.SCALAR, null);
        queryType.addField(new Field("test", stringType));
        schema.setQueryType(queryType);

        Type zebraType = schema.addType("Zebra", TypeKind.OBJECT, null);
        zebraType.addField(new Field("name", stringType));

        Type appleType = schema.addType("Apple", TypeKind.OBJECT, null);
        appleType.addField(new Field("color", stringType));

        Type mangoType = schema.addType("Mango", TypeKind.OBJECT, null);
        mangoType.addField(new Field("taste", stringType));

        String sdlSchema = SdlSchemaStringGenerator.generate(schema);

        int appleIndex = findTypeIndex(sdlSchema, "type Apple");
        int mangoIndex = findTypeIndex(sdlSchema, "type Mango");
        int zebraIndex = findTypeIndex(sdlSchema, "type Zebra");

        Assert.assertTrue(appleIndex < mangoIndex, "Apple should come before Mango (alphabetical order)");
        Assert.assertTrue(mangoIndex < zebraIndex, "Mango should come before Zebra (alphabetical order)");
    }

    @Test
    public void testMinimalSchemaWithOnlyQuery() {
        Schema schema = new Schema(null, false);

        Type queryType = schema.addType("Query", TypeKind.OBJECT, null);
        Type stringType = schema.addType("String", TypeKind.SCALAR, null);
        queryType.addField(new Field("hello", stringType));
        schema.setQueryType(queryType);

        String sdlSchema = SdlSchemaStringGenerator.generate(schema);

        Assert.assertTrue(sdlSchema.contains("type Query"), "Schema should contain Query type");
        Assert.assertTrue(sdlSchema.contains("hello"), "Query should have hello field");
    }

    private int findTypeIndex(String schema, String typePattern) {
        Pattern pattern = Pattern.compile("^" + Pattern.quote(typePattern), Pattern.MULTILINE);
        Matcher matcher = pattern.matcher(schema);
        if (matcher.find()) {
            return matcher.start();
        }
        return -1;
    }
}

