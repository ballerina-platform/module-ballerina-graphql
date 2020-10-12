isolated function getOutputForDocument(Listener 'listener, string documentString) returns InvalidDocumentError|json? {
    map<json> data = {};
    json[] errors = [];
    int errorCount = 0;
    Document document = check parse(documentString);
    if (document.operation == OPERATION_QUERY) {
        string[] fields = document.fields;
        foreach string 'field in fields {
            var resourceValue = getStoredResource('listener, 'field);
            if (resourceValue is error) {
                errors[errorCount] = resourceValue.message();
                errorCount += 1;
            } else if (resourceValue is ()) {
                data['field] = null;
            } else {
                data['field] = resourceValue;
            }
        }
    }
    map<json> result = {};
    if (errorCount > 0) {
        result["errors"] = errors;
    }
    if (data.length() > 0) {
        result["data"] = data;
    }
    return result;
}

isolated function getOperation(string document, string opeartionName) returns string|error {
    return error("not implemented");
}


