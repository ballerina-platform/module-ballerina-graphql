package io.ballerina.stdlib.graphql.runtime.exception;

/**
 * Exception type definition for GraphQL ID type input validation errors.
 */
public class IdTypeInputValidationException extends GraphqlException {
    public IdTypeInputValidationException(String message) {
        super(message);
    }
}
