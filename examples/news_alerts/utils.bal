import ballerina/io;

isolated function printStackTrace(error? err, string indentation = "") {
    if err is error {
        io:println(string `${indentation}${err.message()}: ${err.detail().toBalString()}`);
        printStackTrace(err.cause(), "    ");
    }
}
