# Represents an error occurred when validating a GraphQL document
public type InvalidDocumentError distinct error;

# Represents an error occurred when a required field not found in graphql service resources
public type FieldNotFoundError distinct error;

# Represents an error occurred while a listener operation
public type ListenerError distinct error;

# Represents not-implemented feature error
public type NotImplementedError distinct error;

# Represents any error related to the Ballerina GraphQL module
type Error InvalidDocumentError|ListenerError|FieldNotFoundError|NotImplementedError;

# Represents a GraphQL ID field
type Id int|string;

# Represents the supported Scalar types in Ballerina GraphQL module
type Scalar int|string|float|boolean|Id;

# The annotation which is used to configure a GraphQL service.
public annotation GraphQlServiceConfiguration ServiceConfiguration on service;

# Represents the types of operations valid for Ballerina GraphQL.
public type OperationType OPERATION_QUERY;
