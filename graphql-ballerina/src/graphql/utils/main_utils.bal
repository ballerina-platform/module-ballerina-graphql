import ballerina/log;

isolated function logAndPanicError(string message, error e) {
    log:printError(message, e);
    panic e;
}

isolated function getExpectedSyntaxError(Token token, string expected, string foundType = "") returns
InvalidDocumentError {
    string message = "Syntax Error: Expected \"" + expected + "\", found " + foundType + " \"" + token.value + "\".";
    ErrorRecord errorRecord = getErrorRecordFromToken(token);
    return InvalidDocumentError(message, errorRecord = errorRecord);
}

isolated function getUnexpectedSyntaxError(Token token, string unexpectedType) returns InvalidDocumentError {
    string message = "Syntax Error: Unexpected " + unexpectedType + " \"" + token.value + "\".";
    ErrorRecord errorRecord = getErrorRecordFromToken(token);
    return InvalidDocumentError(message, errorRecord = errorRecord);
}

isolated function getErrorRecordFromToken(Token token) returns ErrorRecord {
    Location location = {
        line: token.line,
        column: token.column
    };
    return {
        locations: [location]
    };
}
