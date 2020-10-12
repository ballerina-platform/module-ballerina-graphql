# Defines the configurations related to Ballerina GraphQL listener
#
# + host - The host name/IP of the GraphQL endpoint
public type ListenerConfiguration record {|
    string host = "0.0.0.0";
|};

public type Data record {
    // Intentionally kept empty
};

public type Document record {
    string operation;
    string operationName?;
    string[] fields;
};

# Stores a location for an error in a GraphQL operation.
#
# + line - The line of the document where error occured
# + column - The column of the document where error occurred
public type Location record {
    int line;
    int column;
};

# Represents an error occurred while executing a GraphQL operation.
#
# + message - The message related to the error
# + locations - Locations of the GraphQL document where the error occurred
# + path - The complete path for the error in the GraphQL document
public type ErrorRecord record {
    string message;
    Location[] locations?;
    (int|string)[] path?;
};

public type OutputObject record {
    Data data?;
    ErrorRecord[] errors?;
};

# Contains the configurations for a GraphQL service.
#
# + basePath - Service base path
public type GraphQlServiceConfiguration record {
    string basePath;
};
