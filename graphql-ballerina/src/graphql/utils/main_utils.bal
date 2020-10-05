import ballerina/log;

isolated function logAndPanicError(string message, error e) {
    log:printError(message, e);
    panic e;
}
