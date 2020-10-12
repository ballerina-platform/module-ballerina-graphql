package io.ballerina.stdlib.graphql.utils;

import org.ballerinalang.jvm.types.BPackage;

/**
 * Constants used in Ballerina GraphQL native library.
 */
public class Constants {
    private Constants() {}

    private static final String ORG_NAME = "ballerina";
    private static final String MODULE_NAME = "graphql";
    private static final String VERSION = "0.1.0";

    static final BPackage PACKAGE_ID = new BPackage(ORG_NAME, MODULE_NAME, VERSION);

    // Type names
    public static final String ERROR_FIELD_NOT_FOUND = "FieldNotFoundError";

    // Operations
    public static final String OPERATION_QUERY = "QUERY";

    public static final String NATIVE_SERVICE_OBJECT = "graphql.service";
}
