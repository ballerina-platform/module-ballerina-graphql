import ballerina/io;
import ballerina/stringutils;

isolated function parse(string documentString) returns Document {
    string[] tokens = stringutils:split(documentString, "\\s+");
    string[] fields = [];
    string operationType = OPERATION_QUERY; // Default value
    string operationName = "";
    if (tokens[0] == "{") {
        fields = getFields(tokens, 1);
    } else if (tokens[0] == OPERATION_QUERY) {
        if (tokens[1] != "{") {
            operationName = tokens[1];
            fields = getFields(tokens, 2);
        } else {
            fields = getFields(tokens, 1);
        }
    } else {
        panic error("Invalid document");
    }
    Document document = {
        operation: operationType,
        fields: fields
    };
    if (operationName != "") {
        document.operationName = operationName;
    }
    return document;
}

isolated function getFields(string[] tokens, int startingCount) returns string[] {
    int count = startingCount;
    string[] fields = [];
    while (count < tokens.length()) {
        if (tokens[count] != "{" && tokens[count] != "}" ) {
            fields.push(tokens[count]);
        }
        count += 1;
    }
    return fields;
}

isolated function printArray(string[] array) {
    foreach string s in array {
        io:println("    " + s);
    }
}
