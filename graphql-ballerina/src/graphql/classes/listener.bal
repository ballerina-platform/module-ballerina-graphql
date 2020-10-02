import ballerina/http;
import ballerina/io;
import ballerina/lang.'object;

public class Listener {
    *'object:Listener;
    http:Listner httpListener;

    public isolated function init(int port, string url = "graphql", Configurations? configs = ()) {
        self.httpListener = new (port);
        io:println("init");
    }

    public isolated function __attach(service s, string? name = ()) returns error? {
        return attach(self, s, name);
    }

    public isolated function __detach(service s) returns error? {
        io:println("attach");
    }

    public isolated function __start() returns error? {
        io:println("start");
    }

    public isolated function __gracefulStop() returns error? {
        io:println("gracefulStop");
    }

    public isolated function __immediateStop() returns error? {
        io:println("immediateStop");
    }
}
