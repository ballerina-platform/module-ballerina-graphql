/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.graphql.engine;

import io.ballerina.runtime.api.StringUtils;
import io.ballerina.runtime.api.ValueCreator;
import io.ballerina.runtime.api.types.AttachedFunctionType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.types.BBooleanType;
import io.ballerina.runtime.types.BFloatType;
import io.ballerina.runtime.types.BIntegerType;
import io.ballerina.runtime.values.ArrayValue;
import io.ballerina.stdlib.graphql.runtime.wrapper.Input;
import io.ballerina.stdlib.graphql.runtime.wrapper.Resource;
import io.ballerina.stdlib.graphql.runtime.wrapper.Wrapper;
import io.ballerina.stdlib.graphql.utils.Constants;

import java.util.List;
import java.util.Objects;

import static io.ballerina.stdlib.graphql.runtime.wrapper.Constants.BOOLEAN_TYPE;
import static io.ballerina.stdlib.graphql.runtime.wrapper.Constants.FLOAT_TYPE;
import static io.ballerina.stdlib.graphql.runtime.wrapper.Constants.INT_TYPE;
import static io.ballerina.stdlib.graphql.utils.Constants.ERROR_INVALID_ARGUMENT_TYPE;
import static io.ballerina.stdlib.graphql.utils.Constants.ERROR_INVALID_SELECTION;
import static io.ballerina.stdlib.graphql.utils.Constants.ERROR_MISSING_REQUIRED_ARGUMENT;
import static io.ballerina.stdlib.graphql.utils.Constants.FIELD_ARGUMENTS;
import static io.ballerina.stdlib.graphql.utils.Constants.FIELD_NAME;
import static io.ballerina.stdlib.graphql.utils.Constants.FIELD_SELECTIONS;
import static io.ballerina.stdlib.graphql.utils.Constants.FIELD_TYPE;
import static io.ballerina.stdlib.graphql.utils.Constants.FIELD_VALUE;
import static io.ballerina.stdlib.graphql.utils.Constants.OPERATION_QUERY;
import static io.ballerina.stdlib.graphql.utils.Utils.createError;
import static io.ballerina.stdlib.graphql.utils.Utils.createErrorArray;
import static io.ballerina.stdlib.graphql.utils.Utils.createFieldNotFoundError;
import static io.ballerina.stdlib.graphql.utils.Utils.createResourceExecutionFailedError;

/**
 * This handles Ballerina GraphQL Engine.
 */
public class Engine {

    /**
     * Returns a stored resource value of a Ballerina service.
     *
     * @param listener - GraphQL listener to which the service is attached
     * @param field    - The {@code Field} record from the Ballerina
     * @return - Resource value
     */
    public static Object executeResource(BObject listener, BMap<BString, Object> field) {
        BObject attachedService = (BObject) listener.getNativeData(Constants.NATIVE_SERVICE_OBJECT);
        AttachedFunctionType[] attachedFunctions = attachedService.getType().getAttachedFunctions();
        String fieldName = field.get(FIELD_NAME).toString();
        for (AttachedFunctionType attachedFunction : attachedFunctions) {
            if (attachedFunction.getName().equals(fieldName)) {
                return Wrapper.invokeResource(attachedFunction, null);
            }
        }
        return createResourceExecutionFailedError(fieldName, OPERATION_QUERY);
    }

    /**
     * Returns an array of field names for the attached service for a Ballerina GraphQL listener.
     *
     * @return - A {@code BArray} consisting field names for the given service
     */
    public static BArray getFieldNames(BObject service) {
        AttachedFunctionType[] attachedFunctions = service.getType().getAttachedFunctions();
        String[] result = new String[attachedFunctions.length];
        for (int i = 0; i < attachedFunctions.length; i++) {
            result[i] = attachedFunctions[i].getName();
        }
        return ValueCreator.createArrayValue(StringUtils.fromStringArray(result));
    }

    /**
     * Validates a given field in a GraphQL document with the schema.
     *
     * @param listener  - Ballerina GraphQL listener object
     * @param field     - The GraphQL operation field which needs to be validated
     * @param operation - The type of the operation
     * @return - A {@code BArray} consisting field names for the given service
     */
    public static Object validateField(BObject listener, BMap<BString, Object> field, BString operation) {
        BObject service = (BObject) listener.getNativeData(Constants.NATIVE_SERVICE_OBJECT);
        return validateFieldWithService(field, service, operation);
    }

    private static Object validateFieldWithService(BMap<BString, Object> field, BObject service, BString operation) {
        AttachedFunctionType[] attachedFunctions = service.getType().getAttachedFunctions();
        String fieldName = field.get(FIELD_NAME).toString();
        BArray errors = createErrorArray();
        for (AttachedFunctionType attachedFunction : attachedFunctions) {
            if (attachedFunction.getName().equals(fieldName)) {
                Resource resource = new Resource(attachedFunction);
                validateResourceWithField(resource, field, errors, operation.getValue());
                return errors;
            }
        }
        return createFieldNotFoundError(field, operation);
    }

    private static void validateResourceWithField(Resource resource, BMap<BString, Object> field, BArray errors,
                                                    String type) {
        List<Input> inputs = resource.getInputs();
        validateArguments(inputs, field, errors);
        validateSelections(resource, field, errors, type);
    }

    // TODO: Exhaustive validation?
    private static void validateArguments(List<Input> inputs, BMap<BString, Object> field, BArray errors) {
        BArray arguments = field.getArrayValue(FIELD_ARGUMENTS);
        if (Objects.isNull(arguments)) {
            if (!inputs.isEmpty()) {
                String filedName = field.getStringValue(FIELD_NAME).getValue();
                for (Input input : inputs) {
                    if (input.isRequired()) {
                        String message = "Field \"" + filedName + "\" argument \"" + input.getName() + "\" of type " +
                                "\"" + input.getType() + "\" is required, but it was not provided.";
                        errors.append(createError(ERROR_MISSING_REQUIRED_ARGUMENT, message, field));
                    }
                }
            }
            return;
        }
        for (int i = 0; i < arguments.size(); i++) {
            BMap<BString, Object> argument = (BMap<BString, Object>) arguments.get(i);
            BString argumentName = (BString) argument.get(FIELD_NAME);
            for (Input input : inputs) {
                if (input.getName().equals(argumentName.getValue())) {
                    validateArgument(argument, input, errors);
                }
            }
        }
        return;
    }

    private static void validateSelections(Resource resource, BMap<BString, Object> field, BArray errors, String type) {
        Type resourceType = resource.getType();

        if (resourceType instanceof RecordType) {
            validateSelectionFromRecord(resource, field, errors, type);
        } else if (resourceType instanceof ServiceType) {
            validateSelectionFromService(resource, field, errors, type);
        } else {
            ArrayValue selections = (ArrayValue) field.get(FIELD_SELECTIONS);
            if (Objects.nonNull(selections)) {
                BString fieldName = (BString) field.get(FIELD_NAME);
                String fieldType = getResourceReturnTypeName(resourceType);
                String message =
                        "Field \"" + fieldName.getValue() + "\" must not have a selection since type \"" + fieldType +
                                "\" has no subfields.";
                errors.append(createError(ERROR_INVALID_SELECTION, message, field));
            }
        }
    }

    private static void validateArgument(BMap<BString, Object> argument, Input input, BArray errors) {
        Object value = argument.get(FIELD_VALUE);
        Long argumentType = (Long) argument.get(FIELD_TYPE);
        int inputType = input.getType();

        if (inputType != argumentType) {
            String message = getErrorMessageForMismatchingType(inputType) + value.toString();
            errors.append(createError(ERROR_INVALID_ARGUMENT_TYPE, message, argument));
        }
    }

    private static void validateSelectionFromService(Resource resource, BMap<BString, Object> field, BArray errors,
                                                     String type) {
        BArray selections = field.getArrayValue(FIELD_SELECTIONS);
        if (Objects.isNull(selections)) {
            String fieldName = ((BString) field.get(FIELD_NAME)).getValue();
            String message = "Field \"" + fieldName + "\" of type \"" + type + "\" must have a selection of subfields" +
                    ". Did you mean \"" + fieldName + " { ... }\"?";
            errors.append(createError(ERROR_INVALID_SELECTION, message, field));
        } else {
            for (int i = 0; i < selections.size(); i++) {
                BMap<BString, Object> nextField = (BMap<BString, Object>) selections.get(i);
                validateFieldWithService(nextField, resource.getServiceObject(), field.getStringValue(FIELD_NAME));
            }
        }
    }

    private static void validateSelectionFromRecord(Resource resource, BMap<BString, Object> field, BArray errors,
                                                    String type) {
        BArray selections = field.getArrayValue(FIELD_SELECTIONS);
        if (Objects.isNull(selections)) {
            String fieldName = ((BString) field.get(FIELD_NAME)).getValue();
            String message = "Field \"" + fieldName + "\" of type \"" + type + "\" must have a selection of subfields" +
                    ". Did you mean \"" + fieldName + " { ... }\"?";
            errors.append(createError(ERROR_INVALID_SELECTION, message, field));
        } else {
            for (int i = 0; i < selections.size(); i++) {
                BMap<BString, Object> nextField = (BMap<BString, Object>) selections.get(i);
                validateFieldWithRecord(nextField, resource.getOutputType(), field.getStringValue(FIELD_NAME));
            }
        }
    }

    private static void validateFieldWithRecord(BMap<BString, Object> field, Type recordType, BString type) {
        // TODO: Check record fields
    }

    private static String getErrorMessageForMismatchingType(int inputType) {
        switch (inputType) {
            case INT_TYPE:
                return "Int cannot represent non-integer value: ";
            case FLOAT_TYPE:
                return "Float cannot represent non-numeric value: ";
            case BOOLEAN_TYPE:
                return "Boolean cannot represent a non boolean value: ";
            default:
                return "String cannot represent a non string value: ";
        }
    }

    private static String getResourceReturnTypeName(Type resourceType) {
        // Mock
        if (resourceType instanceof BIntegerType) {
            return "Int";
        } else if (resourceType instanceof BBooleanType) {
            return "Boolean";
        } else if (resourceType instanceof BFloatType) {
            return "Float";
        }
        return "String";
    }
}
