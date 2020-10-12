package io.ballerina.stdlib.graphql.engine;

import io.ballerina.stdlib.graphql.runtime.wrapper.Wrapper;
import io.ballerina.stdlib.graphql.utils.Constants;
import org.ballerinalang.jvm.api.values.BObject;
import org.ballerinalang.jvm.api.values.BString;
import org.ballerinalang.jvm.types.AttachedFunction;

import static io.ballerina.stdlib.graphql.utils.Constants.OPERATION_QUERY;
import static io.ballerina.stdlib.graphql.utils.Utils.createFieldNotFoundError;

/**
 * This handles Ballerina GraphQL Engine.
 */
public class Engine {

    /**
     * Returns a stored resource value of a Ballerina service.
     *
     * @param listener - GraphQL listener to which the service is attached
     * @param name - Resource name to be retrieved
     * @return - Resource value
     */
    public static Object getResource(BObject listener, BString name) {
        BObject attachedService = (BObject) listener.getNativeData(Constants.NATIVE_SERVICE_OBJECT);
        AttachedFunction[] attachedFunctions = attachedService.getType().getAttachedFunctions();
        for (AttachedFunction attachedFunction:attachedFunctions) {
            if (attachedFunction.funcName.equals(name.toString())) {
                return Wrapper.invokeResource(attachedFunction);
            }
        }
        return createFieldNotFoundError(name, OPERATION_QUERY);
    }
}
