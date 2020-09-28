package org.ballerinalang.stdlib.graphql.service;

import org.ballerinalang.jvm.types.AttachedFunction;
import org.ballerinalang.jvm.values.ObjectValue;

public class ServiceHandler {
    public static Object attach(ObjectValue listener, ObjectValue service, Object name) {
        AttachedFunction[] resourceFunctions = service.getType().getAttachedFunctions();
        for (AttachedFunction resource : resourceFunctions) {
            System.out.println("Tag: " + resource.getReturnParameterType().getTag());
        }
        return null;
    }
}
