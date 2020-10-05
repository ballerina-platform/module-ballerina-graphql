package org.ballerinalang.stdlib.graphql.engine;

import org.ballerinalang.jvm.api.values.BObject;
import org.ballerinalang.jvm.api.values.BString;
import org.ballerinalang.jvm.types.AttachedFunction;
import org.ballerinalang.stdlib.graphql.runtime.wrapper.Wrapper;

import java.io.PrintStream;

import static org.ballerinalang.stdlib.graphql.utils.Constants.NATIVE_SERVICE_OBJECT;

/**
 * This handles Ballerina GraphQL Engine.
 */
public class Engine {
    private static PrintStream console = System.out;

    /**
     * Returns a stored resource value of a Ballerina service.
     *
     * @param listener - GraphQL listener to which the service is attached
     * @param name - Resource name to be retrieved
     * @return - Resource value
     */
    public static Object getResource(BObject listener, BString name) {
        BObject attachedService = (BObject) listener.getNativeData(NATIVE_SERVICE_OBJECT);
        AttachedFunction[] attachedFunctions = attachedService.getType().getAttachedFunctions();
        for (AttachedFunction attachedFunction:attachedFunctions) {
            if (attachedFunction.funcName.equals(name.toString())) {
                console.println("Required Resource: " + name);
                return Wrapper.invokeResource(attachedFunction);
            }
        }
        return null;
    }
}
