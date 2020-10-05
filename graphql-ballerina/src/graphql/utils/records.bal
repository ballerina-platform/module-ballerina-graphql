public type Configurations record {|
    string sample;
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

public type ErrorRecord record {
    string message;
    Location[] locations?;
    string[] path?; // TODO: Ideally this should be (int|string)[] to hold array values
};

public type OutputObject record {
    Data data?;
    ErrorRecord[] errors?;
};
