import ballerina/io;
import ballerina/log;

function getGeneralNotationDocument() returns string {
    return readFileAndGetString(DOCUMENT_GENERAL, 47);
}

function getShorthandNotationDocument() returns string {
    return readFileAndGetString(DOCUMENT_SHORTHAND, 34);
}

function getAnonymousOperationDocument() returns string {
    return readFileAndGetString(DOCUMENT_ANONYMOUS, 39);
}

function getNoCloseBraceDocument() returns string {
    return readFileAndGetString(DOCUMENT_NO_CLOSE_BRACE, 38);
}

function readFileAndGetString(string fileName, int length) returns string {
    var fileText = readFile(RESOURCE_PATH + fileName, length);
    if (fileText is error) {
        logAndPanicError("Error occurred while reading the document", fileText);
    }
    return <string>fileText;
}

function readFile(string path, int count) returns string|error {
    io:ReadableByteChannel rbc = check <@untainted>io:openReadableFile(path);
    io:ReadableCharacterChannel rch = new (rbc, "UTF8");
    var result = <@untainted>rch.read(count);
    closeReadChannel(rch);
    return result;
}

function closeReadChannel(io:ReadableCharacterChannel rc) {
    var result = rc.close();
    if (result is error) {
        log:printError("Error occurred while closing character stream", result);
    }
}

