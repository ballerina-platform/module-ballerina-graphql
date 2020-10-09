import ballerina/io;

public class Engine {
    private Listener 'listener;

    public isolated function init(Listener 'listener) {
        self.'listener = 'listener;
    }

    isolated function getOutputForDocument(string documentString) returns InvalidDocumentError? {
         Document document = check parse(documentString);
         if (document.operation == OPERATION_QUERY) {
             string[] fields = document.fields;
             foreach string 'field in fields {
                 io:println(getStoredResource(self.'listener, 'field));
             }
         }
     }
}

isolated function getOperation(string document, string opeartionName) returns string|error {
    return error("not implemented");
}


