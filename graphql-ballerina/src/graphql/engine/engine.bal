isolated function getOutputForDocument(Listener 'listener, string documentString) returns json {
    map<json> data = {};
    json[] errors = [];
    int errorCount = 0;
    Document|Error parseResult = parse(documentString);
    if (parseResult is Error) {
        errors[errorCount] = getErrorJsonFromError(parseResult);
        return getResultJson(data, errors);
    }
    Document document = <Document>parseResult;
    if (document.operations.length() > 1) {
        NotImplementedError err = NotImplementedError("Ballerina GraphQL does not support multiple operations yet.");
        errors[errorCount] = getErrorJsonFromError(err);
        return getResultJson(data, errors);
    } else if (document.operations.length() == 0) {
        InvalidDocumentError err = InvalidDocumentError("Document does not contains any operation.");
        errors[errorCount] = getErrorJsonFromError(err);
        return getResultJson(data, errors);
    }
    Operation operation = document.operations[0];
    OperationType 'type = operation.'type;
    if ('type == OPERATION_QUERY) {
        string[] fields = operation.fields;
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
    } else {
        NotImplementedError err =
            NotImplementedError("Ballerina GraphQL does not support " + 'type.toString() + " operations yet.");
        errors[errorCount] = getErrorJsonFromError(err);
        return getResultJson(data, errors);
    }
    return getResultJson(data, errors);
}
