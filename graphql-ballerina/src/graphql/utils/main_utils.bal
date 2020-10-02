import ballerina/io;
import ballerina/log;

function readFileAndGetDocument(string path) returns string|error {
    io:ReadableByteChannel rbc = check <@untainted>io:openReadableFile(path);
    io:ReadableCharacterChannel rch = new (rbc, "UTF8");
    var result = <@untainted>rch.read(34);
    closeReadChannel(rch);
    return result;
}

isolated function logAndPanicError(string message, error e) {
    log:printError(message, e);
    panic e;
}

function closeReadChannel(io:ReadableCharacterChannel rc) {
    var result = rc.close();
    if (result is error) {
        log:printError("Error occurred while closing character stream", result);
    }
}
