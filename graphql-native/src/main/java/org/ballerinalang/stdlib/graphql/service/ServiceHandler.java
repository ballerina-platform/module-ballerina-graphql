package org.ballerinalang.stdlib.graphql.service;

import org.ballerinalang.jvm.types.AttachedFunction;
import org.ballerinalang.jvm.values.ObjectValue;

import java.io.PrintStream;

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
    public static Object attach(ObjectValue listener, ObjectValue service, Object name) {
        AttachedFunction[] resourceFunctions = service.getType().getAttachedFunctions();
        for (AttachedFunction resource : resourceFunctions) {
            console.println("Tag: " + resource.getReturnParameterType());
        }
        return null;
    }
}
