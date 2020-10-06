package io.ballerina.stdlib.graphql.service;

import org.ballerinalang.jvm.api.values.BObject;

import java.io.PrintStream;

import static io.ballerina.stdlib.graphql.utils.Constants.NATIVE_SERVICE_OBJECT;

/**
 * Handles the service objects related to Ballerina GraphQL implementation.
 */
public class ServiceHandler {
    private static final PrintStream console = System.out;

    /**
     * Attaches a Ballerina service to a Ballerina GraphQL listener.
     *
     * @param listener - GraphQL listener to attach the service
     * @param service  - Service object of the Ballerina service
     * @param name     - Name of the service
     * @return - {@code ErrorValue} if the attaching is failed, null otherwise
     */
    public static Object attach(BObject listener, BObject service, Object name) {
        listener.addNativeData(NATIVE_SERVICE_OBJECT, service);
        return null;
    }
}
