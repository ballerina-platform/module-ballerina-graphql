package io.ballerina.stdlib.graphql.runtime.exception;

/**
 * Exception type definition for GraphQL constraint validation errors.
 */
public class ConstraintValidationException extends GraphqlException {
    public ConstraintValidationException(String message) {
        super(message);
    }
}
