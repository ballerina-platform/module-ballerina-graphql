package io.ballerina.stdlib.graphql.utils;

import org.ballerinalang.jvm.api.BErrorCreator;
import org.ballerinalang.jvm.api.BStringUtils;
import org.ballerinalang.jvm.api.values.BError;
import org.ballerinalang.jvm.api.values.BString;

import static io.ballerina.stdlib.graphql.utils.Constants.ERROR_FIELD_NOT_FOUND;
import static io.ballerina.stdlib.graphql.utils.Constants.PACKAGE_ID;

/**
 * Utility class for Ballerina GraphQL module.
 */
public class Utils {
    private Utils() {
    }

    public static BError createError(String type, BString message) {
        return BErrorCreator.createDistinctError(type, PACKAGE_ID, message);
    }

    public static BError createFieldNotFoundError(BString fieldName, String operationName) {
        StringBuilder stringBuilder = new StringBuilder()
                .append("Cannot query field \\\"")
                .append(fieldName.getValue())
                .append("\\\" on type \\\"")
                .append(operationName)
                .append("\\\".");
        BString message = BStringUtils.fromString(stringBuilder.toString());
        return createError(ERROR_FIELD_NOT_FOUND, message);
    }
}
