# Represents an error occurred when validating a GraphQL document
public type InvalidDocumentError distinct error;

# Represents an error occurred while a listener operation
public type ListenerError distinct error;

# Represents any error related to the Ballerina GraphQL module
type Error InvalidDocumentError|ListenerError;

# Represents a GraphQL ID field
type Id int|string;

# Represents the supported Scalar types in Ballerina GraphQL module
type Scalar int|string|float|boolean|Id;

# The annotation which is used to configure a GraphQL service.
public annotation GraphQlServiceConfiguration ServiceConfiguration on service;
