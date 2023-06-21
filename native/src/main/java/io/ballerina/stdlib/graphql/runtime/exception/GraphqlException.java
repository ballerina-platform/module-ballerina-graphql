package io.ballerina.stdlib.graphql.runtime.exception;

/**
 * Exception type definition for GraphQL errors.
 */
public class GraphqlException extends Exception {
    public GraphqlException(String message) {
        super(message);
    }
}
