import ballerina/io;

type MapAnydata map<anydata>;

isolated function getOperation(string document, string opeartionName) returns string|error {
    return error("not implemented");
}

isolated function getStoredResource(Listener 'listener, string name) returns Scalar? {
    return getStoredResourceExt('listener, name);
}

isolated function getOutputForDocument(Listener 'listener, string documentString) returns InvalidDocumentError? {
    Document document = check parse(documentString);
    if (document.operation == OPERATION_QUERY) {
        io:println("Operation: " + document.operation);
        string[] fields = document.fields;
        foreach string 'field in fields {
            io:println(getStoredResource('listener, 'field));
        }
    }
}
