import ballerina/io;

public client class Caller {
    public remote function respond(anydata data) {
        io:println("Responding: " + data.toString());
    }
}
