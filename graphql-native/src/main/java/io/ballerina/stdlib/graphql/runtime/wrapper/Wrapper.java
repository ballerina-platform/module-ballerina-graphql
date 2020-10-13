package io.ballerina.stdlib.graphql.runtime.wrapper;

import org.ballerinalang.jvm.api.BStringUtils;
import org.ballerinalang.jvm.types.AttachedFunction;

/**
 * Wrapper class for Ballerina Compiler Utils.
 */
public class Wrapper {
    public static Object invokeResource(AttachedFunction attachedFunction, Object[] inputs) {
        String name = attachedFunction.funcName;
        if ("name".equals(name)) {
            return BStringUtils.fromString("John Doe");
        } else if ("id".equals(name)) {
            return 1;
        } else if ("birthDate".equals(name)) {
            return BStringUtils.fromString("01-01-1980");
        }
        return null;
    }
}
